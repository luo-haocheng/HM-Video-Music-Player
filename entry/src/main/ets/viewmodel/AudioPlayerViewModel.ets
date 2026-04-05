import { media } from '@kit.MediaKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AVPlayerModel } from '../model/AVPlayerModel';
import { AudioItemViewModelList } from './AudioListViewModel';

@Observed
export class AudioPlayerViewModel {
  @Track currIndex: number = -1;
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track isPlaying: boolean = false;
  private playerState: media.AVPlayerState = 'idle';
  private audioPlayer: AVPlayerModel = new AVPlayerModel();

  async init(audioInfo: AudioInfoModel): Promise<void> {
    this.audioPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.audioPlayer.registerCallback('seekDone', (timeMs: number) => {
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
    });
    await this.audioPlayer.initPlayer();
    await this.audioPlayer.setMediaAsset(audioInfo.audioPath);
  }

  async play(): Promise<void> {
    await this.audioPlayer.play();
  }

  async pause(): Promise<void> {
    await this.audioPlayer.pause();
  }
}