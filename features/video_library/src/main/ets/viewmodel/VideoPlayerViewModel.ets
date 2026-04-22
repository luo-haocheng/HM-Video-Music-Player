import { AVPlayerManager, MediaSessionManager } from 'player';
import { common, Context } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { ColorMetrics, display, window } from '@kit.ArkUI';
import { settings } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import { VideoInfoModel } from 'data_storage';

const SEEK_TIME = 10000;
const BRIGHT_VALUE = 0.1;
const VOLUME_VALUE = 1.0;
const ONE_HUNDRED_VP = 100;
const MAX_VOLUME_LEVEL = 15;
const MAX_WINDOW_BRIGHTNESS = 1.0;
const MAX_SCREEN_BRIGHTNESS = 255;

@Observed
export class VideoPlayerViewModel {
  @Track name: string = '';
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track seekTime: number = 0;
  @Track brightness: number = 0;
  @Track volumeLevel: number = 0;
  @Track isPlaying: boolean = false;
  @Track isLandscape: boolean = false;
  @Track isCtrlPanelShow: boolean = false;
  @Track isSeeking: boolean = false;
  @Track isSpeeding: boolean = false;
  @Track isControlVolume: boolean = false;
  @Track isControlBrightness: boolean = false;
  public videoInfo: VideoInfoModel = new VideoInfoModel();
  private videoPlayer: AVPlayerManager = new AVPlayerManager();
  private startSeekTime: number = 0;
  private startBrightness: number = 0;
  private startVolumeLevel: number = 0;
  private slideLeftSide: boolean = false;

  constructor() {
    let audioMgr = audio.getAudioManager();
    let audioVolumeMgr = audioMgr.getVolumeManager();
    try {
      this.volumeLevel = audioVolumeMgr.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
    } catch (error) {
      console.info(`Failed to getVolumeByStream. Cause: ${JSON.stringify(error)}`);
    }
  }

  async initPlayer(surfaceId: string): Promise<void> {
    this.videoPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.videoPlayer.registerCallback('timeUpdate', (timeMs: number) => {
      this.currTime = timeMs;
      MediaSessionManager.getInstance().updateElapsedTime(timeMs);
    });
    this.videoPlayer.registerCallback('seekDone', (timeMs: number) => {
      MediaSessionManager.getInstance().updatePlayPosition(timeMs);
    });
    this.videoPlayer.registerCallback('stateChange', (state: media.AVPlayerState) => {
      this.isPlaying = (state === 'playing');
      MediaSessionManager.getInstance().updatePlayState(this.currTime, state);
    });
    await this.videoPlayer.initPlayer(surfaceId);
  }

  async initSession(context: Context) {
    MediaSessionManager.getInstance().registerCallback('play', () => {
      this.videoPlayer.play();
    });
    MediaSessionManager.getInstance().registerCallback('pause', () => {
      this.videoPlayer.pause();
    });
    MediaSessionManager.getInstance().registerCallback('seek', (timeMs: number) => {
      this.seek(timeMs);
    });
    MediaSessionManager.getInstance().registerCallback('rewind', (timeS?: number) => {
      if (timeS) {
        let timeMs = this.currTime - timeS * 1000;
        this.seek(timeMs);
      }
    });
    MediaSessionManager.getInstance().registerCallback('fastForward', (timeS?: number) => {
      if (timeS) {
        let timeMs = this.currTime + timeS * 1000;
        this.seek(timeMs);
      }
    });
    await MediaSessionManager.getInstance().initVideoSession(context);
  }

  async setVideoAsset(context: Context): Promise<void> {
    await this.videoPlayer.setMediaAsset(this.videoInfo.videoPath);
    setTimeout(async () => {
      await this.initSession(context);
      const currState: media.AVPlayerState = this.videoPlayer.getState() ?? 'released';
      await MediaSessionManager.getInstance().setVideoAsset(this.videoInfo, this.currTime, currState);
    }, 500);
  }

  async play(): Promise<void> {
    await this.videoPlayer.play();
  }

  async pause(): Promise<void> {
    await this.videoPlayer.pause();
  }

  async seek(timeMs: number): Promise<void> {
    timeMs = Math.min(this.duration, Math.max(0, timeMs));
    await this.videoPlayer.seek(timeMs);
  }

  setSpeed(speed: media.PlaybackSpeed): void {
    this.videoPlayer.setSpeed(speed);
    switch (speed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.75);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.25);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.75);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 2.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.50);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 1.50);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_3_00_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 3.00);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_25_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.25);
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_125_X:
        MediaSessionManager.getInstance().updatePlaySpeed(this.currTime, 0.125);
        break;
    }
  }

  async release(): Promise<void> {
    await MediaSessionManager.getInstance().release();
    await this.videoPlayer.release();
  }

  async startHorizontalSlide(): Promise<void> {
    console.info(`PanGesture Horizontal Start`);
    this.seekTime = this.currTime;
    this.startSeekTime = this.currTime;
  }

  async updateHorizontalSlide(offsetX: number): Promise<void> {
    console.info(`PanGesture Horizontal Update: ${offsetX}`);
    let seekTime = this.startSeekTime + (offsetX / ONE_HUNDRED_VP) * SEEK_TIME;
    this.seekTime = Math.max(0, Math.min(seekTime, this.duration));
  }

  async endHorizontalSlide(): Promise<void> {
    console.info(`PanGesture Horizontal End`);
    await this.seek(this.seekTime);
  }

  async startVerticalSlide(context: common.UIAbilityContext, uiContext: UIContext, globalX: number): Promise<void> {
    console.info(`PanGesture Veritcal Start`);
    let screenWidthVp: number = 0;
    try {
      screenWidthVp = uiContext.px2vp(display.getDefaultDisplaySync().width);
    } catch (error) {
      console.error(`Failed to invoke getDefaultDisplaySync. Cause: ${JSON.stringify(error)}`);
      return;
    }
    if (globalX <= screenWidthVp / 2) {
      this.slideLeftSide = true;
    } else {
      this.slideLeftSide = false;
    }
    if (this.slideLeftSide) {
      this.isControlBrightness = true;
      let windowClass: window.Window | undefined;
      try {
        windowClass = await context.windowStage.getMainWindow();
      } catch (error) {
        console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
        return;
      }
      try {
        this.startBrightness = windowClass.getWindowProperties().brightness;
        if (this.startBrightness === -1) {
          let brightStr = settings.getValueSync(context, settings.display.SCREEN_BRIGHTNESS_STATUS, '100');
          this.startBrightness = parseInt(brightStr) / MAX_SCREEN_BRIGHTNESS;
        }
      } catch (error) {
        console.error(`Failed to getWindowProperties. Cause: ${JSON.stringify(error)}`);
        return;
      }
    } else {
      this.isControlVolume = true;
      let audioMgr = audio.getAudioManager();
      let audioVolumeMgr = audioMgr.getVolumeManager();
      try {
        this.startVolumeLevel = audioVolumeMgr.getVolumeByStream(audio.StreamUsage.STREAM_USAGE_MUSIC);
      } catch (error) {
        console.info(`Failed to getVolumeByStream. Cause: ${JSON.stringify(error)}`);
      }
    }
  }

  async updateVerticalSlide(context: common.UIAbilityContext, offsetY: number): Promise<void> {
    console.info(`PanGesture Vertical Update: ${offsetY}`);
    if (this.slideLeftSide) {
      let windowClass: window.Window | undefined;
      try {
        windowClass = await context.windowStage.getMainWindow();
      } catch (error) {
        console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
        return;
      }
      let brightnessVal = this.startBrightness - (offsetY / ONE_HUNDRED_VP) * BRIGHT_VALUE;
      this.brightness = Math.min(MAX_WINDOW_BRIGHTNESS, Math.max(0, brightnessVal));
      try {
        await windowClass.setWindowBrightness(this.brightness);
      } catch (error) {
        console.error(`Failed to setWindowBrightness. Cause: ${JSON.stringify(error)}`);
        return;
      }
    } else {
      let volumeLevel = this.startVolumeLevel - (offsetY / ONE_HUNDRED_VP) * VOLUME_VALUE;
      this.volumeLevel = Math.min(MAX_VOLUME_LEVEL, Math.max(0, volumeLevel));
    }
  }

  async setWindowOrientation(context: common.UIAbilityContext, orientation: window.Orientation): Promise<void> {
    await context.windowStage.getMainWindow()
      .then((windowClass: window.Window) => {
        windowClass.setPreferredOrientation(orientation)
          .then(() => {
            this.isLandscape = orientation === window.Orientation.LANDSCAPE;
            console.info(`Set window orientation to ${orientation} successfully`);
          })
          .catch((error: BusinessError) => {
            console.error(`Failed to set window orientation to ${orientation}, Cause: ${JSON.stringify(error)}`);
          });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getMainWindow, Cause: ${JSON.stringify(error)}`);
      });
  }

  async setStatusBarColor(context: common.UIAbilityContext, color: number) {
    await context.windowStage.getMainWindow()
      .then((windowClass: window.Window) => {
        windowClass.setStatusBarColor(ColorMetrics.numeric(color))
          .catch((err: BusinessError) => {
            console.error(`Failed to set status bar color to 0x000000, error: ${JSON.stringify(err)}`);
          });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getMainWindow, Cause: ${JSON.stringify(error)}`);
      });
  }

  async setDefaultBrightness(context: common.UIAbilityContext): Promise<void> {
    let windowClass: window.Window | undefined;
    try {
      windowClass = await context.windowStage.getMainWindow();
    } catch (error) {
      console.error(`Failed to getMainWindow. Cause: ${JSON.stringify(error)}`);
      return;
    }
    try {
      await windowClass.setWindowBrightness(-1.0);
    } catch (error) {
      console.error(`Failed to setWindowBrightness. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async setControlPanelShow() {
    this.isCtrlPanelShow = !this.isCtrlPanelShow;
  }
}