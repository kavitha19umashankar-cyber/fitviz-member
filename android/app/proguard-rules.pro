# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Razorpay — must keep or payments break
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }
-dontwarn com.razorpay.**

# OkHttp (used by Dio internally)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.** { *; }

# JSON models (keep field names for Gson/json_serializable)
-keepclassmembers class in.fitviz.member.** {
    @com.google.gson.annotations.SerializedName <fields>;
}
