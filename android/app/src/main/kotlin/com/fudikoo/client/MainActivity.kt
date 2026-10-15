package com.fudikoo.client

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // The manifest already asks for adjustNothing; this says it again at
    // runtime so a plugin's merged manifest can't quietly hand resizing back.
    // The keyboard has to draw over the window instead of shrinking it, or the
    // radius panel on the location picker rides up the screen with it.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
    }
}
