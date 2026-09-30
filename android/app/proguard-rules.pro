# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepclassmembers class com.it_nomads.fluttersecurestorage.** { *; }

# SQLCipher
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# General
-dontwarn org.slf4j.**
-keepattributes Signature
-keepattributes *Annotation*
