# flutter_gemma / MediaPipe – keep rules for release builds
# These classes are referenced via reflection and must not be stripped by R8.

-keep class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.proto.** { *; }
-keep class com.google.mediapipe.framework.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }

# Suppress R8 warnings for proto classes not present in the dependency tree
# (referenced from MediaPipe internals but not shipped with the AAR)
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate

# AutoValue @Memoized annotation referenced by MediaPipe's MPImageProperties
# but absent at runtime — compile-time annotation only, safe to ignore.
-dontwarn com.google.auto.value.extension.memoized.Memoized

# Keep Flutter embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter deferred components use Google Play Core — suppress warnings
# since we do not use deferred components in this app.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Keep Hive adapters (generated classes)
-keep class * extends com.hivedb.** { *; }
-keep class * implements com.hivedb.** { *; }
