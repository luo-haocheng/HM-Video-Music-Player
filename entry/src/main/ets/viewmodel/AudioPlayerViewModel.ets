import { media } from '@kit.MediaKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AVPlayerModel } from '../model/AVPlayerModel';
import { MediaSessionManager } from '../model/ModelSession';
import { Settings } from '../model/Settings';
import { AudioRepeatMode, SettingKey } from '../model/SettingsModel';
import { AudioItemViewModel } from './AudioItemViewModel';
import { AudioItemViewModelList } from './AudioListViewModel';


@Observed
export class AudioPlayerViewModel {
  @Track currAudioItem?: AudioItemViewModel;
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track isPlaying: boolean = false;
  @Track bitRate?: string;
  @Track codecMime?: string;
  @Track sampleRate?: string;
  @Track repeatMode: AudioRepeatMode = AudioRepeatMode.SINGLE_REPEAT;
  private settings: Settings = new Settings();
  private playerState: media.AVPlayerState = 'idle';
  private audioPlayer: AVPlayerModel = new AVPlayerModel();
  private mediaSession: MediaSessionManager = new MediaSessionManager();

  async init(context: Context): Promise<void> {
    this.mediaSession.registerCallback('play', () => {
      this.audioPlayer.play();
    });
    this.mediaSession.registerCallback('pause', () => {
      this.audioPlayer.pause();
    });
    this.mediaSession.initAudioSession(context);

    this.audioPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.audioPlayer.registerCallback('timeUpdate', (timeMs: number) => {
      this.currTime = timeMs;
    });
    this.audioPlayer.registerCallback('stateChange', (state: media.AVPlayerState) => {
      this.playerState = state;
      if (this.isPlaying && ['idle', 'initialized', 'prepared', 'completed'].includes(state)) {
        setTimeout(() => {
          if (this.playerState !== 'playing') {
            this.isPlaying = false;
          }
        }, 500);
      } else {
        this.isPlaying = (state === 'playing');
      }
      this.mediaSession.updatePlayState(this.currTime, state);

      if (state === 'completed') {
        if (this.repeatMode === AudioRepeatMode.SINGLE_REPEAT) {
          if (this.currAudioItem) {
            this.setAudioAsset(this.currAudioItem.audioInfo, context);
          }
        } else if (this.repeatMode === AudioRepeatMode.LIST_REPEAT) {
          this.switchNext(context);
        } else {
          this.switchShuffle(context);
        }
      }
    });
    await this.audioPlayer.initPlayer();

    await this.settings.initPreference(context);
    this.repeatMode = (await this.settings.getSetting(SettingKey.AUDIO_REPEAT_MODE)) as AudioRepeatMode;
  }

  async setAudioAsset(audioInfo: AudioInfoModel, context: Context) {
    await this.mediaSession.setAudioAsset(audioInfo, context);
    await this.audioPlayer.setMediaAsset(audioInfo.audioPath);
    this.parseAudioMetadata();
  }

  async switchShuffle(context: Context) {
    if (this.currAudioItem) {
      const currIdx = this.audioList.findIndex((item: AudioItemViewModel) => {
        return this.currAudioItem?.audioInfo.id === item.audioInfo.id;
      });
      if (currIdx !== -1) {
        let randIdx = this.getRandomIndex(currIdx, this.audioList.length);
        this.setAudioAsset(this.audioList[randIdx].audioInfo, context);
        this.currAudioItem = this.audioList[randIdx];
      }
    }
  }

  async switchNext(context: Context): Promise<void> {
    if (this.currAudioItem) {
      const currIdx = this.audioList.findIndex((item: AudioItemViewModel) => {
        return this.currAudioItem?.audioInfo.id === item.audioInfo.id;
      });
      if (currIdx !== -1) {
        const nextIdx = (currIdx + 1) % this.audioList.length;
        await this.setAudioAsset(this.audioList[nextIdx].audioInfo, context);
        this.currAudioItem = this.audioList[nextIdx];
      }
    }
  }

  async switchPrev(context: Context): Promise<void> {
    if (this.currAudioItem) {
      const currIdx = this.audioList.findIndex((item: AudioItemViewModel) => {
        return this.currAudioItem?.audioInfo.id === item.audioInfo.id;
      });
      if (currIdx !== -1) {
        const prevIdx = currIdx === 0 ? this.audioList.length - 1 : (currIdx - 1) % this.audioList.length;
        await this.setAudioAsset(this.audioList[prevIdx].audioInfo, context);
        this.currAudioItem = this.audioList[prevIdx];
      }
    }
  }

  async switchRepeatMode(): Promise<void> {
    if (this.repeatMode === AudioRepeatMode.SINGLE_REPEAT) {
      this.repeatMode = AudioRepeatMode.LIST_REPEAT;
      this.settings.putSetting(SettingKey.AUDIO_REPEAT_MODE, AudioRepeatMode.LIST_REPEAT);
    } else if (this.repeatMode === AudioRepeatMode.LIST_REPEAT) {
      this.repeatMode = AudioRepeatMode.SHUFFLE;
      this.settings.putSetting(SettingKey.AUDIO_REPEAT_MODE, AudioRepeatMode.SHUFFLE);
    } else {
      this.repeatMode = AudioRepeatMode.SINGLE_REPEAT;
      this.settings.putSetting(SettingKey.AUDIO_REPEAT_MODE, AudioRepeatMode.SINGLE_REPEAT);
    }
  }

  async play(): Promise<void> {
    await this.audioPlayer.play();
  }

  async pause(): Promise<void> {
    await this.audioPlayer.pause();
  }

  async seek(timeMs: number): Promise<void> {
    await this.audioPlayer.seek(timeMs);
  }


  private parseAudioMetadata() {
    if (this.currAudioItem) {
      this.bitRate = undefined;
      this.codecMime = undefined;
      this.sampleRate = undefined;
      const metadataStr = this.currAudioItem.audioInfo.metadata;
      if (metadataStr === null) {
        return;
      }
      const metadata = JSON.parse(metadataStr) as media.AVMetadata;
      if (metadata.tracks) {
        for (let i = 0; i < metadata.tracks.length; ++i) {
          const track = metadata.tracks[i];
          if (track[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE] === media.MediaType.MEDIA_TYPE_AUD) {
            const bitrate = track[media.MediaDescriptionKey.MD_KEY_BITRATE];
            const codecMime = track[media.MediaDescriptionKey.MD_KEY_CODEC_MIME];
            const sampleRate = track[media.MediaDescriptionKey.MD_KEY_AUD_SAMPLE_RATE];
            if (bitrate && codecMime && sampleRate) {
              this.bitRate = this.parseBitrate(bitrate as string);
              this.codecMime = this.parseAudioCodec(codecMime as string);
              this.sampleRate = this.parserAudioSampleRate(sampleRate as string);
            }
            break;
          }
        }
      }
    }
  }

  private parseAudioCodec(codec: string): string {
    const lastIdx = codec.lastIndexOf('/');
    return codec.slice(lastIdx + 1).toUpperCase();
  }

  private parserAudioSampleRate(sampleRate: string): string {
    const sampleRateVal = parseInt(sampleRate);
    return `${sampleRateVal / 1000} kHz`;
  }

  private parseBitrate(bitrate: string): string {
    const bitrateVal = parseInt(bitrate);
    return `${bitrateVal / 1000} kbps`;
  }

  private getRandomIndex(currIdx: number, len: number): number {
    if (len <= 1) {
      return 0;
    }
    let randIdx = currIdx;
    while (randIdx === currIdx) {
      randIdx = Math.floor(Math.random() * len);
    }
    return randIdx;
  }
}