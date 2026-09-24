# WorkManager's Room database is instantiated reflectively during AndroidX
# Startup, before Flutter starts. Preserve its generated no-arg constructor
# under release R8 full mode (the dependency only keeps the class name).
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
