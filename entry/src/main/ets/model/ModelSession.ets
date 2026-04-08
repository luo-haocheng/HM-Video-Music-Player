import { avSession as AVSessionMananger } from '@kit.AVSessionKit';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { util } from '@kit.ArkTS';
import { VideoInfoModel } from './VideoInfoModel';
import { AudioInfoModel } from './AudioInfoModel';

export class MediaSessionManager {
  private session?: AVSessionMananger.AVSession;
  private callbacks: Map<string, Function> = new Map();

  async initAudioSession(context: Context): Promise<void> {
    if (!this.session) {
      try {
        let sessionName = util.generateRandomUUID();
        this.session = await AVSessionMananger.createAVSession(context, sessionName, 'audio');
      } catch (error) {
        console.error(`Failed to create avsession. Cause: ${JSON.stringify(error)}`);
        return;
      }
      try {
        this.registerCtrlCmd();
      } catch (error) {
        console.error(`Failed to register avsession control command. Cuase: ${JSON.stringify(error)}`);
        return;
      }

      try {
        await this.session.activate();
      } catch (error) {
        console.error(`Failed to invoke avsession.activate. Cause: ${JSON.stringify(error)}`);
        return;
      }
    }
  }

  async setAudioAsset(audioInfo: AudioInfoModel, context: Context) {
    if (this.session) {
      let duration = -1;
      let title: string | undefined;
      let mediaImg: image.PixelMap | undefined;
      try {
        if (audioInfo.coverPath) {
          mediaImg = await this.getMediaImage(audioInfo.coverPath);
        } else {
          mediaImg = await this.getDefaultImage(context);
        }
        if (audioInfo.metadata) {
          duration = await this.getMediaDuration(audioInfo.metadata);
          title = await this.getAudioTitle(audioInfo.metadata);
        }
        let metadata: AVSessionMananger.AVMetadata = {
          assetId: util.generateRandomUUID(),
          title: title ? title : audioInfo.name,
          artist: audioInfo.artist ? audioInfo.artist : '',
          mediaImage: mediaImg,
          duration: duration,
        };
        await this.session.setAVMetadata(metadata);
      } catch (error) {
        console.error(`Failed to invoke avsession.setAVMetadata. Cause: ${JSON.stringify(error)}`);
        return;
      } finally {
        if (mediaImg) {
          await mediaImg.release();
        }
      }
    }
  }

  async initVideoSession(info: VideoInfoModel, context: Context): Promise<void> {
    try {
      let sessionName = util.generateRandomUUID();
      this.session = await AVSessionMananger.createAVSession(context, sessionName, 'video');
    } catch (error) {
      console.error(`Failed to create avsession. Cause: ${JSON.stringify(error)}`);
      return;
    }

    let duration = -1;
    let mediaImg: image.PixelMap | undefined;
    try {
      mediaImg = await this.getMediaImage(info.thumbnailPath);
      duration = await this.getMediaDuration(info.metadata);
      let metadata: AVSessionMananger.AVMetadata = {
        assetId: util.generateRandomUUID(),
        title: info.name,
        duration: duration,
        mediaImage: mediaImg,
      };
      await this.session.setAVMetadata(metadata);
    } catch (error) {
      console.error(`Failed to invoke avsession.setAVMetadata. Cause: ${JSON.stringify(error)}`);
      return;
    } finally {
      if (mediaImg) {
        await mediaImg.release();
      }
    }

    try {
      this.registerCtrlCmd();
    } catch (error) {
      console.error(`Failed to register avsession control command. Cuase: ${JSON.stringify(error)}`);
      return;
    }

    try {
      await this.session.activate();
    } catch (error) {
      console.error(`Failed to invoke avsession.activate. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlayState(timeMs: number, state: media.AVPlayerState): Promise<void> {
    let playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
    switch (state) {
      case 'initialized':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_INITIAL;
        break;
      case 'prepared':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PREPARE;
        break;
      case 'playing':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PLAY;
        break;
      case 'paused':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_PAUSE;
        break;
      case 'stopped':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_STOP;
        break;
      case 'completed':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_COMPLETED;
        break;
      case 'released':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_RELEASED;
        break;
      case 'idle':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_IDLE;
        break;
      case 'error':
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
        break;
      default:
        playState = AVSessionMananger.PlaybackState.PLAYBACK_STATE_ERROR;
        break;
    }
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        state: playState,
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play state. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlayPosition(timeMs: number): Promise<void> {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        }
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play position. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async updatePlaySpeed(timeMs: number, playSpeed: number): Promise<void> {
    try {
      let playbackState: AVSessionMananger.AVPlaybackState = {
        position: {
          elapsedTime: timeMs,
          updateTime: new Date().getTime()
        },
        speed: playSpeed
      };
      await this.session?.setAVPlaybackState(playbackState);
    } catch (error) {
      console.error(`Failed to update avsession play speed. Cause: ${JSON.stringify(error)}`);
      return;
    }
  }

  async destroySession(): Promise<void> {
    try {
      await this.session?.destroy();
    } catch (error) {
      console.error(`Failed to invoke avsession.destroy. Cause: ${JSON.stringify(error)}`);
    }
  }

  async registerCallback(event: string, callback: Function) {
    this.callbacks.set(event, callback);
  }

  private registerCtrlCmd() {
    try {
      this.session?.on('play', () => {
        if (this.callbacks.has('play')) {
          let callback = this.callbacks.get('play') as () => void;
          callback();
        }
      });
      this.session?.on('pause', () => {
        if (this.callbacks.has('pause')) {
          let callback = this.callbacks.get('pause') as () => void;
          callback();
        }
      });
      this.session?.on('seek', (timeMs: number) => {
        if (this.callbacks.has('seek')) {
          let callback = this.callbacks.get('seek') as (timeMs: number) => void;
          callback(timeMs);
        }
      });
      this.session?.on('rewind', (timeS?: number) => {
        if (this.callbacks.has('rewind')) {
          let callback = this.callbacks.get('rewind') as (timeS?: number) => void;
          callback(timeS);
        }
      });
      this.session?.on('fastForward', (timeS?: number) => {
        if (this.callbacks.has('fastForward')) {
          let callback = this.callbacks.get('fastForward') as (timeS?: number) => void;
          callback(timeS);
        }
      });
    } catch (error) {
      throw new Error(error);
    }
  }

  private async getMediaImage(thumbnailPath: string): Promise<image.PixelMap | undefined> {
    let imageSource: image.ImageSource | undefined;
    let mediaImg: image.PixelMap | undefined;
    try {
      imageSource = image.createImageSource(thumbnailPath);
      mediaImg = await imageSource.createPixelMap();
    } catch (error) {
      console.error(`Failed to create preview image. Cause: ${JSON.stringify(error)}`);
    } finally {
      if (imageSource) {
        imageSource.release();
      }
    }
    return mediaImg;
  }

  private async getDefaultImage(context: Context): Promise<image.PixelMap | undefined> {
    let imageSource: image.ImageSource | undefined;
    let mediaImg: image.PixelMap | undefined;
    try {
      const rawFd = await context.resourceManager.getRawFd('audio_default.jpg');
      imageSource = image.createImageSource(rawFd);
      mediaImg = await imageSource.createPixelMap();
    } catch (error) {
      console.error(`Failed to create default music cover. Cause: ${JSON.stringify(error)}`);
    } finally {
      if (imageSource) {
        imageSource.release();
      }
    }
    return mediaImg;
  }

  private async getMediaDuration(metadataStr: string): Promise<number> {
    let metadata = JSON.parse(metadataStr) as media.AVMetadata;
    let duration = metadata.duration ? parseInt(metadata.duration) : 0;
    return duration;
  }

  private async getAudioTitle(metadataStr: string): Promise<string | undefined> {
    const metadata = JSON.parse(metadataStr) as media.AVMetadata;
    return metadata.title;
  }
}