package app.dyshi.breathin

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity — требование audio_service: связывает Flutter-движок
// с медиа-сервисом (фоновое воспроизведение таймлайна сессии, ПЛАН §3.3).
class MainActivity : AudioServiceActivity()
