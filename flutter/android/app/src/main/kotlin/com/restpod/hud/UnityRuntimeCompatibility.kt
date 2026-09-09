package com.restpod.hud

/**
 * Whether this device should start the checked-in arm64-only Unity runtime.
 *
 * Some x86_64 emulators advertise arm64-v8a as a secondary, translated ABI.
 * Android still selects the x86_64 libraries from a universal APK for that
 * process, so merely finding arm64-v8a anywhere in the list is not enough.
 */
internal fun supportsArm64UnityRuntime(deviceAbis: Array<String>): Boolean =
    deviceAbis.firstOrNull() == "arm64-v8a"
