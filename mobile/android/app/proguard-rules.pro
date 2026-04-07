# Flutter ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep JSON serialization
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep http package
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Keep secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
