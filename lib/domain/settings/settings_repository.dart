enum ScaleSource { decent, mock }

enum PressureSource { bookoo, mock }

/// User-configurable settings. Values are read synchronously: implementations
/// load them up front.
abstract class SettingsRepository {
  static const minStartDelayCompensationSeconds = 0;
  static const maxStartDelayCompensationSeconds = 10;

  /// The pressure sensor detects the start of a shot late. This many seconds
  /// before the detected start are added to the recording.
  int get startDelayCompensationSeconds;

  Future<void> setStartDelayCompensationSeconds(int seconds);

  /// Which scale implementation is wired at app start. Changes apply after
  /// a restart.
  ScaleSource get scaleSource;

  Future<void> setScaleSource(ScaleSource source);

  /// Which pressure sensor implementation is wired at app start. Changes apply
  /// after a restart.
  PressureSource get pressureSource;

  Future<void> setPressureSource(PressureSource source);
}
