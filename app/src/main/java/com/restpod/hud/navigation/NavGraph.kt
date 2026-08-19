package com.restpod.hud.navigation

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.restpod.hud.session.WorkoutEvent
import com.restpod.hud.session.WorkoutSessionViewModel
import com.restpod.hud.ui.screens.CameraScreen
import com.restpod.hud.ui.screens.ChatListScreen
import com.restpod.hud.ui.screens.CoachActiveScreen
import com.restpod.hud.ui.screens.CoachReadyScreen
import com.restpod.hud.ui.screens.CoachRestLast5sScreen
import com.restpod.hud.ui.screens.CoachRestScreen
import com.restpod.hud.ui.screens.ConfirmSuccessScreen
import com.restpod.hud.ui.screens.DietAnalysisScreen
import com.restpod.hud.ui.screens.DietHistoryScreen
import com.restpod.hud.ui.screens.OnboardingOtpScreen
import com.restpod.hud.ui.screens.OnboardingPhoneScreen
import com.restpod.hud.ui.screens.ProfileScreen
import com.restpod.hud.ui.screens.RecipeScreen
import com.restpod.hud.ui.screens.SettingsScreen
import com.restpod.hud.ui.screens.SocialFeedScreen
import com.restpod.hud.ui.screens.StopwatchHomeScreen
import com.restpod.hud.ui.screens.WorkoutMapScreen

private val tabDestinations = listOf(
    Routes.STOPWATCH_HOME,
    Routes.SOCIAL_FEED,
    Routes.WORKOUT_MAP,
    Routes.PROFILE,
)

private val tabSet = tabDestinations.toSet()
private val restSet = setOf(Routes.COACH_REST, Routes.COACH_REST_LAST_5S)

private const val TransitionMs = 280

@Composable
fun RestPodNavGraph(
    navController: NavHostController = rememberNavController(),
    session: WorkoutSessionViewModel = viewModel(),
) {
    val workoutState by session.uiState.collectAsState()

    fun goToTab(index: Int) {
        navController.navigate(tabDestinations[index]) {
            popUpTo(Routes.STOPWATCH_HOME) {
                inclusive = false
                saveState = true
            }
            launchSingleTop = true
            restoreState = true
        }
    }

    LaunchedEffect(session) {
        session.events.collect { event ->
            when (event) {
                WorkoutEvent.GoReady -> navController.navigate(Routes.COACH_READY) {
                    launchSingleTop = true
                }
                WorkoutEvent.GoActive -> navController.navigate(Routes.COACH_ACTIVE) {
                    popUpTo(Routes.COACH_READY) { inclusive = false }
                    launchSingleTop = true
                }
                WorkoutEvent.GoRest -> navController.navigate(Routes.COACH_REST) {
                    popUpTo(Routes.COACH_ACTIVE) { inclusive = true }
                    launchSingleTop = true
                }
                WorkoutEvent.GoRestLast5 -> {
                    if (navController.currentDestination?.route != Routes.COACH_REST_LAST_5S) {
                        navController.navigate(Routes.COACH_REST_LAST_5S) {
                            launchSingleTop = true
                        }
                    }
                }
                WorkoutEvent.GoHome -> {
                    navController.popBackStack(Routes.STOPWATCH_HOME, inclusive = false)
                }
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = Routes.STOPWATCH_HOME,
        enterTransition = {
            val from = initialState.destination.route
            val to = targetState.destination.route
            when {
                from in restSet && to in restSet -> fadeIn(tween(TransitionMs)) + scaleIn(
                    initialScale = 0.94f,
                    animationSpec = tween(TransitionMs),
                )
                from in tabSet && to in tabSet -> fadeIn(tween(220))
                else -> slideInHorizontally(tween(TransitionMs)) { it } + fadeIn(tween(TransitionMs))
            }
        },
        exitTransition = {
            val from = initialState.destination.route
            val to = targetState.destination.route
            when {
                from in restSet && to in restSet -> fadeOut(tween(TransitionMs)) + scaleOut(
                    targetScale = 1.04f,
                    animationSpec = tween(TransitionMs),
                )
                from in tabSet && to in tabSet -> fadeOut(tween(220))
                else -> slideOutHorizontally(tween(TransitionMs)) { -it / 4 } + fadeOut(tween(TransitionMs))
            }
        },
        popEnterTransition = {
            val from = initialState.destination.route
            val to = targetState.destination.route
            when {
                from in restSet && to in restSet -> fadeIn(tween(TransitionMs)) + scaleIn(
                    initialScale = 1.04f,
                    animationSpec = tween(TransitionMs),
                )
                from in tabSet && to in tabSet -> fadeIn(tween(220))
                else -> slideInHorizontally(tween(TransitionMs)) { -it / 4 } + fadeIn(tween(TransitionMs))
            }
        },
        popExitTransition = {
            val from = initialState.destination.route
            val to = targetState.destination.route
            when {
                from in restSet && to in restSet -> fadeOut(tween(TransitionMs)) + scaleOut(
                    targetScale = 0.94f,
                    animationSpec = tween(TransitionMs),
                )
                from in tabSet && to in tabSet -> fadeOut(tween(220))
                else -> slideOutHorizontally(tween(TransitionMs)) { it } + fadeOut(tween(TransitionMs))
            }
        },
    ) {
        composable(Routes.ONBOARDING_PHONE) {
            OnboardingPhoneScreen(onGetCode = { navController.navigate(Routes.ONBOARDING_OTP) })
        }
        composable(Routes.ONBOARDING_OTP) {
            OnboardingOtpScreen(onVerified = {
                navController.navigate(Routes.STOPWATCH_HOME) {
                    popUpTo(Routes.ONBOARDING_PHONE) { inclusive = true }
                }
            })
        }
        composable(Routes.STOPWATCH_HOME) {
            StopwatchHomeScreen(onStart = { session.startSession() }, onNavigate = ::goToTab)
        }
        composable(Routes.SOCIAL_FEED) {
            SocialFeedScreen(onNavigate = ::goToTab)
        }
        composable(Routes.CHAT_LIST) {
            ChatListScreen(onNavigate = ::goToTab)
        }
        composable(Routes.WORKOUT_MAP) {
            WorkoutMapScreen(onNavigate = ::goToTab)
        }
        composable(Routes.PROFILE) {
            ProfileScreen(onOpenSettings = { navController.navigate(Routes.SETTINGS) }, onNavigate = ::goToTab)
        }
        composable(Routes.SETTINGS) {
            SettingsScreen(onBack = { navController.popBackStack() })
        }
        composable(Routes.CAMERA) {
            CameraScreen(onCaptured = { navController.navigate(Routes.DIET_ANALYSIS) })
        }
        composable(Routes.DIET_ANALYSIS) {
            DietAnalysisScreen(onConfirm = { navController.navigate(Routes.CONFIRM_SUCCESS) })
        }
        composable(Routes.CONFIRM_SUCCESS) {
            ConfirmSuccessScreen(
                onContinueScanning = { navController.navigate(Routes.CAMERA) },
                onBackToAnalysis = { navController.popBackStack(Routes.STOPWATCH_HOME, inclusive = false) },
            )
        }
        composable(Routes.DIET_HISTORY) {
            DietHistoryScreen()
        }
        composable(Routes.RECIPE) {
            RecipeScreen()
        }
        composable(Routes.COACH_READY) {
            BackHandler { session.abortWorkout() }
            CoachReadyScreen(
                state = workoutState,
                onStart = { session.startSet() },
                onToggleGender = { session.setMale(it) },
                onCycleAngle = { session.cycleCameraAngle() },
            )
        }
        composable(Routes.COACH_ACTIVE) {
            BackHandler { session.abortWorkout() }
            CoachActiveScreen(
                state = workoutState,
                onPauseToggle = { session.togglePause() },
                onCompleteSet = { session.completeSet() },
                onAbort = { session.abortWorkout() },
            )
        }
        composable(Routes.COACH_REST) {
            BackHandler { session.abortWorkout() }
            CoachRestScreen(
                state = workoutState,
                onSkip = { session.skipRest() },
                onAddThirty = { session.addRestSeconds(30) },
            )
        }
        composable(Routes.COACH_REST_LAST_5S) {
            BackHandler { session.abortWorkout() }
            CoachRestLast5sScreen(
                state = workoutState,
                onStartNow = { session.startNextSetNow() },
            )
        }
    }
}
