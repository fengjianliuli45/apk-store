# Room resolves generated database implementations by name and invokes their
# public no-argument constructor. R8 full mode must preserve that entry point.
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}

# Unity invokes this bridge by its literal Java class and static method names.
# The host also resolves its lifecycle callbacks reflectively from Flutter.
-keep class com.restpod.hud.UnityRuntimeBridge { *; }
-keep class com.restpod.hud.StopwatchUnityActivity { *; }
