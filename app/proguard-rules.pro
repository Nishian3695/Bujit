# Preserve stack trace line numbers in crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Strip verbose/debug/info log calls from release builds.
# Log.w and Log.e are kept for crash-reporting purposes.
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# Teller Connect SDK (WebView-based, written in Kotlin)
# The SDK ships pre-minified — its internals were already renamed to the `a` package
# by its own ProGuard run. Without these rules, R8 renames them a second time,
# breaking Kotlin reflection and the WebView→Java callback bridge (onSuccess, etc.).
-keep class io.teller.** { *; }
-dontwarn io.teller.**
-keep class a.** { *; }
-dontwarn a.**

# Keep ConnectListener callbacks on any class that implements the interface,
# so R8 doesn't remove or rename onSuccess/onFailure/onExit on BankingActivity.
-keepclassmembers class * implements io.teller.connect.sdk.ConnectListener {
    <methods>;
}

# Kotlin runtime — required because Teller SDK is written in Kotlin
# and this app does not otherwise pull in Kotlin's consumer ProGuard rules.
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# Kotlin coroutines (used internally by Teller SDK)
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# MPAndroidChart
-keep class com.github.mikephil.charting.** { *; }
