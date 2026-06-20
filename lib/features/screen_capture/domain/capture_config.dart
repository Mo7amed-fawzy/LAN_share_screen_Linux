class CaptureConfig {
  final int width;
  final int height;
  final int frameRate;

  const CaptureConfig({
    this.width = 1920,
    this.height = 1080,
    this.frameRate = 30,
  });

  const CaptureConfig.low({
    this.width = 320,
    this.height = 180,
    this.frameRate = 5,
  });

  const CaptureConfig.medium({
    this.width = 640,
    this.height = 360,
    this.frameRate = 15,
  });

  const CaptureConfig.high({
    this.width = 1920,
    this.height = 1080,
    this.frameRate = 30,
  });
}
