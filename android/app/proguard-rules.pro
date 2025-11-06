# Suppress warnings for annotation-only classes referenced by libraries (R8 missing class warnings)
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**
-dontwarn org.checkerframework.**

# Keep Google Tink classes used by Firebase/crypto libs to prevent over-shrinking
-keep class com.google.crypto.tink.** { *; }
-keep class com.google.crypto.** { *; }

# Generated missing rules from AGP
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# Suppress R8 missing class warnings for optional Google HTTP Client and Joda-Time
# referenced by com.google.crypto.tink.util.KeysDownloader in transitive dependencies.
-dontwarn com.google.api.client.http.GenericUrl
-dontwarn com.google.api.client.http.HttpHeaders
-dontwarn com.google.api.client.http.HttpRequest
-dontwarn com.google.api.client.http.HttpRequestFactory
-dontwarn com.google.api.client.http.HttpResponse
-dontwarn com.google.api.client.http.HttpTransport
-dontwarn com.google.api.client.http.javanet.NetHttpTransport$Builder
-dontwarn com.google.api.client.http.javanet.NetHttpTransport
-dontwarn org.joda.time.Instant

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Dart HTTP classes used by Flutter http package
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep HTTP client implementation classes
-keep class io.flutter.plugins.connectivity.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep all classes in the http package implementation
-keep class dart.io.** { *; }
-keep class dart.async.** { *; }

# Keep JSON serialization classes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all model classes that might be used with JSON
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Suppress warnings for Google Play Core (optional dependency, not needed for regular APK)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

