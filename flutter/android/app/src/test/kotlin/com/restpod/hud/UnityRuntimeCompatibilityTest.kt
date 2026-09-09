package com.restpod.hud

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UnityRuntimeCompatibilityTest {
    @Test
    fun arm64PrimaryAbiCanStartUnity() {
        assertTrue(supportsArm64UnityRuntime(arrayOf("arm64-v8a", "armeabi-v7a")))
    }

    @Test
    fun x86PrimaryAbiFallsBackEvenWhenArmTranslationIsAdvertised() {
        assertFalse(supportsArm64UnityRuntime(arrayOf("x86_64", "arm64-v8a")))
    }

    @Test
    fun missingAbisCannotStartUnity() {
        assertFalse(supportsArm64UnityRuntime(emptyArray()))
    }
}
