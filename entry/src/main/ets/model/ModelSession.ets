import { avSession as AVSessionMananger } from '@kit.AVSessionKit';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { util } from '@kit.ArkTS';
import { VideoInfoModel } from './VideoInfoModel';

export class MediaSessionManager {
  private session?: AVSessionMananger.AVSession;
  private callbacks: Map<string, Function> = new Map();

  async initSession(info: VideoInfoModel, type: AVSessionMananger.AVSessionType, context: Context): Promise<void> {
    try {
      let sessionName = util.generateRandomUUID();
      this.session = await AVSessionMananger.createAVSession(context, sessionName, type);
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

  async updatePlayState(timeMs: number, playState: AVSessionMananger.PlaybackState): Promise<void> {
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

  private async getMediaDuration(metadataStr: string): Promise<number> {
    let metadata = JSON.parse(metadataStr) as media.AVMetadata;
    let duration = metadata.duration ? parseInt(metadata.duration) : 0;
    return duration;
  }
}