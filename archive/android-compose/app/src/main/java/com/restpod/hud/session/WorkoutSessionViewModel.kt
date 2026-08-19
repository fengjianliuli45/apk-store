package com.restpod.hud.session

import android.os.SystemClock
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.ceil

enum class WorkoutPhase { Idle, Ready, Active, Rest }

data class SetPlan(val name: String, val targetReps: Int)

data class WorkoutUiState(
    val phase: WorkoutPhase = WorkoutPhase.Idle,
    val currentSet: Int = 1,
    val totalSets: Int = WorkoutSessionViewModel.TOTAL_SETS,
    val exerciseName: String = "深蹲",
    val nextExerciseName: String = "深蹲",
    val targetReps: Int = 12,
    val completedReps: Int = 0,
    val setElapsedMs: Long = 0L,
    val isPaused: Boolean = false,
    val restRemainingMs: Long = 30_000L,
    val restDurationMs: Long = 30_000L,
    val isMale: Boolean = true,
    val cameraAngle: String = "正面视角",
    val isLastFiveSeconds: Boolean = false,
) {
    val nextSetNumber: Int get() = (currentSet + 1).coerceAtMost(totalSets)

    val setTimerText: String get() {
        val centis = (setElapsedMs / 10L).coerceAtLeast(0L)
        val minutes = (centis / 6000L).toInt()
        val seconds = ((centis % 6000L) / 100L).toInt()
        val cs = (centis % 100L).toInt()
        return "%02d:%02d.%02d".format(minutes, seconds, cs)
    }

    val restSecondsDisplay: Int
        get() = ceil(restRemainingMs.coerceAtLeast(0L) / 1000.0).toInt()

    val restRingProgress: Float
        get() {
            val total = restDurationMs.coerceAtLeast(1L).toFloat()
            return (restRemainingMs / total).coerceIn(0f, 1f)
        }

    val repsProgress: Float
        get() = if (targetReps <= 0) 0f else (completedReps.toFloat() / targetReps).coerceIn(0f, 1f)

    val angleCaption: String get() = "$cameraAngle · 4 秒节奏 · 保持核心收紧"

    companion object {
        const val REST_DEFAULT_MS = 30_000L
        val CAMERA_ANGLES = listOf("正面视角", "侧面视角", "背面视角")
    }
}

sealed interface WorkoutEvent {
    data object GoReady : WorkoutEvent
    data object GoActive : WorkoutEvent
    data object GoRest : WorkoutEvent
    data object GoRestLast5 : WorkoutEvent
    data object GoHome : WorkoutEvent
}

class WorkoutSessionViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(WorkoutUiState())
    val uiState: StateFlow<WorkoutUiState> = _uiState.asStateFlow()

    private val eventChannel = Channel<WorkoutEvent>(Channel.BUFFERED)
    val events = eventChannel.receiveAsFlow()

    private var tickerJob: Job? = null

    fun startSession() {
        applySet(1, phase = WorkoutPhase.Ready)
        emit(WorkoutEvent.GoReady)
    }

    fun startSet() {
        _uiState.update {
            it.copy(
                phase = WorkoutPhase.Active,
                setElapsedMs = 0L,
                completedReps = 0,
                isPaused = false,
            )
        }
        startTicker()
        emit(WorkoutEvent.GoActive)
    }

    fun togglePause() {
        if (_uiState.value.phase != WorkoutPhase.Active) return
        _uiState.update { it.copy(isPaused = !it.isPaused) }
    }

    fun completeSet() {
        val state = _uiState.value
        if (state.phase != WorkoutPhase.Active) return
        if (state.currentSet >= TOTAL_SETS) {
            finishWorkout()
        } else {
            beginRest()
            emit(WorkoutEvent.GoRest)
        }
    }

    fun abortWorkout() {
        persistPrefsAndReset()
        emit(WorkoutEvent.GoHome)
    }

    fun addRestSeconds(seconds: Int = 30) {
        if (_uiState.value.phase != WorkoutPhase.Rest) return
        val extra = seconds * 1000L
        _uiState.update {
            val remaining = it.restRemainingMs + extra
            it.copy(
                restRemainingMs = remaining,
                restDurationMs = it.restDurationMs + extra,
                isLastFiveSeconds = remaining <= LAST_FIVE_MS,
            )
        }
    }

    fun skipRest() {
        if (_uiState.value.phase != WorkoutPhase.Rest) return
        _uiState.update {
            it.copy(
                restRemainingMs = LAST_FIVE_MS,
                isLastFiveSeconds = true,
            )
        }
        emit(WorkoutEvent.GoRestLast5)
    }

    fun startNextSetNow() {
        if (_uiState.value.phase != WorkoutPhase.Rest) return
        advanceToNextSet(autoStart = true)
    }

    fun setMale(male: Boolean) {
        _uiState.update { it.copy(isMale = male) }
    }

    fun cycleCameraAngle() {
        _uiState.update {
            val idx = WorkoutUiState.CAMERA_ANGLES.indexOf(it.cameraAngle).let { i ->
                if (i < 0) 0 else i
            }
            val next = WorkoutUiState.CAMERA_ANGLES[(idx + 1) % WorkoutUiState.CAMERA_ANGLES.size]
            it.copy(cameraAngle = next)
        }
    }

    private fun beginRest() {
        _uiState.update {
            it.copy(
                phase = WorkoutPhase.Rest,
                restRemainingMs = WorkoutUiState.REST_DEFAULT_MS,
                restDurationMs = WorkoutUiState.REST_DEFAULT_MS,
                isLastFiveSeconds = false,
                isPaused = false,
            )
        }
        startTicker()
    }

    private fun advanceToNextSet(autoStart: Boolean) {
        val next = _uiState.value.currentSet + 1
        if (next > TOTAL_SETS) {
            finishWorkout()
            return
        }
        applySet(next, phase = if (autoStart) WorkoutPhase.Active else WorkoutPhase.Ready)
        if (autoStart) {
            startTicker()
            emit(WorkoutEvent.GoActive)
        } else {
            tickerJob?.cancel()
            emit(WorkoutEvent.GoReady)
        }
    }

    private fun applySet(setNumber: Int, phase: WorkoutPhase) {
        val plan = PLANS[setNumber - 1]
        val nextPlan = PLANS.getOrNull(setNumber) ?: plan
        val preserved = _uiState.value
        _uiState.value = WorkoutUiState(
            phase = phase,
            currentSet = setNumber,
            totalSets = TOTAL_SETS,
            exerciseName = plan.name,
            nextExerciseName = nextPlan.name,
            targetReps = plan.targetReps,
            completedReps = 0,
            setElapsedMs = 0L,
            isPaused = false,
            restRemainingMs = WorkoutUiState.REST_DEFAULT_MS,
            restDurationMs = WorkoutUiState.REST_DEFAULT_MS,
            isMale = preserved.isMale,
            cameraAngle = preserved.cameraAngle,
            isLastFiveSeconds = false,
        )
    }

    private fun finishWorkout() {
        persistPrefsAndReset()
        emit(WorkoutEvent.GoHome)
    }

    private fun persistPrefsAndReset() {
        tickerJob?.cancel()
        tickerJob = null
        val preserved = _uiState.value
        _uiState.value = WorkoutUiState(
            isMale = preserved.isMale,
            cameraAngle = preserved.cameraAngle,
        )
    }

    private fun startTicker() {
        tickerJob?.cancel()
        tickerJob = viewModelScope.launch {
            var last = SystemClock.elapsedRealtime()
            while (isActive) {
                delay(TICK_MS)
                val now = SystemClock.elapsedRealtime()
                val dt = (now - last).coerceAtLeast(0L)
                last = now
                val state = _uiState.value
                when (state.phase) {
                    WorkoutPhase.Active -> {
                        if (!state.isPaused) {
                            val elapsed = state.setElapsedMs + dt
                            val autoReps = (elapsed / REP_INTERVAL_MS).toInt().coerceIn(0, state.targetReps)
                            _uiState.update {
                                it.copy(
                                    setElapsedMs = elapsed,
                                    completedReps = maxOf(it.completedReps, autoReps),
                                )
                            }
                        }
                    }
                    WorkoutPhase.Rest -> {
                        val remaining = (state.restRemainingMs - dt).coerceAtLeast(0L)
                        val last5 = remaining <= LAST_FIVE_MS
                        val crossedIntoLast5 = last5 && !state.isLastFiveSeconds
                        _uiState.update {
                            it.copy(
                                restRemainingMs = remaining,
                                isLastFiveSeconds = last5,
                            )
                        }
                        if (crossedIntoLast5) {
                            emit(WorkoutEvent.GoRestLast5)
                        }
                        if (remaining == 0L) {
                            viewModelScope.launch { advanceToNextSet(autoStart = true) }
                            break
                        }
                    }
                    else -> { }
                }
            }
        }
    }

    private fun emit(event: WorkoutEvent) {
        eventChannel.trySend(event)
    }

    override fun onCleared() {
        tickerJob?.cancel()
        super.onCleared()
    }

    companion object {
        const val TOTAL_SETS = 4
        private const val TICK_MS = 50L
        private const val LAST_FIVE_MS = 5_000L
        private const val REP_INTERVAL_MS = 2_000L
        val PLANS = listOf(
            SetPlan("深蹲", 12),
            SetPlan("深蹲", 12),
            SetPlan("俯卧撑", 12),
            SetPlan("俯卧撑", 12),
        )
    }
}
