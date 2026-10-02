package io.github.nishian3695.bujit

// Non-release builds use the App Check provider Dart sets up (the debug provider in
// debug builds); only release builds install the Play Integrity exchange.
object ReleaseAppCheck {
    fun install(): Boolean = false
}
