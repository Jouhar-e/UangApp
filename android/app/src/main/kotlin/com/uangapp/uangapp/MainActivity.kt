package com.uangapp.uangapp

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(resolveLaunchTheme())
        super.onCreate(savedInstanceState)
    }

    private fun resolveLaunchTheme(): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val variant = prefs.getString(PREF_THEME_VARIANT, null)
        return if (variant == THEME_PINK) {
            R.style.LaunchThemePink
        } else {
            R.style.LaunchTheme
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREF_THEME_VARIANT = "flutter.app_theme_variant"
        private const val THEME_PINK = "pink"
    }
}
