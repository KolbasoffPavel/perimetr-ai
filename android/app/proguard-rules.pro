# ProGuard / R8 rules for Flutter app

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

-assumenosideeffects class android.util.Log {
public static boolean isLoggable(java.lang.String, int);
public static int v(...);
public static int i(...);
public static int w(...);
public static int d(...);
public static int e(...);
}

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
