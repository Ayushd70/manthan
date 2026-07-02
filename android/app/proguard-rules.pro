# MediaPipe / flutter_gemma — required for release (R8) builds.
# https://github.com/DenisovAV/flutter_gemma
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.proto.**

# Protocol Buffers (referenced by MediaPipe graph templates).
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
  *;
}

# Flogger (MediaPipe transitive).
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.common.flogger.**
