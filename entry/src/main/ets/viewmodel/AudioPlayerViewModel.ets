import { media } from '@kit.MediaKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AVPlayerModel } from '../model/AVPlayerModel';
import { MediaSessionManager } from '../model/ModelSession';
import { AudioItemViewModelList } from './AudioListViewModel';

@Observed
export class AudioPlayerViewModel {
  @Track currIndex: number = -1;
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track isPlaying: boolean = false;
  @Track bitRate?: string;
  @Track codecMime?: string;
  @Track sampleRate?: string;
  private playerState: media.AVPlayerState = 'idle';
  private audioPlayer: AVPlayerModel = new AVPlayerModel();
  private mediaSession: MediaSessionManager = new MediaSessionManager();

  async init(audioInfo: AudioInfoModel, context: Context): Promise<void> {
    this.mediaSession.registerCallback('play', () => {
      this.audioPlayer.play();
    });
    this.mediaSession.registerCallback('pause', () => {
      this.audioPlayer.pause();
    });
    this.mediaSession.initAudioSession(audioInfo, context);

    this.audioPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.audioPlayer.registerCallback('timeUpdate', (timeMs: number) => {
      this.currTime = timeMs;
    });
    this.audioPlayer.registerCallback('stateChange', (state: media.AVPlayerState) => {
      this.playerState = state;
      if (this.isPlaying && ['idle', 'initialized', 'prepared'].includes(state)) {
        setTimeout(() => {
          if (this.playerState !== 'playing') {
            this.isPlaying = false;
          }
        }, 500);
      } else {
        this.isPlaying = (state === 'playing');
      }
      this.mediaSession.updatePlayState(this.currTime, state);
    });
    await this.audioPlayer.initPlayer();
    await this.audioPlayer.setMediaAsset(audioInfo.audioPath);

    this.parseAudioMetadata();
  }

  async play(): Promise<void> {
    await this.audioPlayer.play();
  }

  async pause(): Promise<void> {
    await this.audioPlayer.pause();
  }


  private parseAudioMetadata() {
    this.bitRate = undefined;
    this.codecMime = undefined;
    this.sampleRate = undefined;
    const metadataStr = this.audioList[this.currIndex].audioInfo.metadata;
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
}