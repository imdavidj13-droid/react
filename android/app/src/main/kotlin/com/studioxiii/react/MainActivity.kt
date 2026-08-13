package com.studioxiii.react

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // RE△CT uses rapid double-tap input as a core game command. Some Android
        // devices/OEM accessibility shortcuts can also map rapid taps to a
        // screenshot. Keep the activity secure so those system shortcuts cannot
        // produce screenshots while the game is open.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
