# R8 rules for release builds (debug builds aren't shrunk, so problems here only
# show up in builds from Play or `flutter build apk --release`).

# Keep line numbers in crash reports (Play Console's Android vitals).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# WorkManager (brought in by plugins) starts at launch and creates its Room
# database by reflection. Without this, R8 removes the constructor and the app
# crashes on open: "NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init>".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Release App Check (StandardIntegrityAppCheckProvider): Firebase finds its
# components by reflection, and the provider uses Play Integrity's Standard API.
# The Java app kept these too.
-keep class com.google.firebase.appcheck.** { *; }
-keep interface com.google.firebase.appcheck.** { *; }
-dontwarn com.google.firebase.appcheck.**
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**

# Plaid Link (plaid_flutter).
-keep class com.plaid.** { *; }
-dontwarn com.plaid.**
