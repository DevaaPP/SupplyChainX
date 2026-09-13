# ML Kit Barcode Scanning rules
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn androidx.camera.**
-dontwarn dev.steenbakker.mobile_scanner.**
