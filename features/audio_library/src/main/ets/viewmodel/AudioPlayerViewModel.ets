import { media } from '@kit.MediaKit';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { AVPlayerManager } from 'player';
import { MediaSessionManager } from 'player/src/main/ets/media_session/MediaSession';
import { AudioRepeatMode, SettingKey, Settings } from 'data_storage';
import { AudioItemViewModel } from './AudioItemViewModel';
import { AudioItemViewModelList } from './AudioListViewModel';
import { avSession as AVSessionMananger } from '@kit.AVSessionKit';
import { AudioLibraryStore } from 'data_storage/src/main/ets/rdbms/AudioLibraryStore';
import { fileIo } from '@kit.CoreFileKit';
import { LyricsInfo } from '../model/LyricsInfoModel';
import { emitter } from '@kit.BasicServicesKit';

const TOGGLE_FAVORITE_EVENT = 'ToggleFavorite';

@Observed
export class AudioPlayerViewModel {
  @Track duration: number = 0;
  @Track currTime: number = 0;
  @Track isPlaying: boolean = false;
  @Track isSeeking: boolean = false;
  @Track isFavorite: boolean = false;
  @Track currLyrics: string = '';
  @Track currLyricsIdx: number = 0;
  @Track lyricsInfoArr: Array<LyricsInfo> = [];
  @Track currAudioItem?: AudioItemViewModel;
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  @Track repeatMode: AudioRepeatMode = AudioRepeatMode.SINGLE_REPEAT;
  @Track lyricsScroller: Scroller = new Scroller();
  private settings: Settings = new Settings();
  private playerState: media.AVPlayerState = 'idle';
  private audioPlayer: AVPlayerManager = new AVPlayerManager();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    MediaSessionManager.getInstance().registerCallback('play', () => {
      this.audioPlayer.play();
    });
    MediaSessionManager.getInstance().registerCallback('pause', () => {
      this.audioPlayer.pause();
    });
    MediaSessionManager.getInstance().registerCallback('seek', (timeMs: number) => {
      this.seek(timeMs);
    });
    MediaSessionManager.getInstance().registerCallback('playNext', () => {
      this.switchNext(context);
    });
    MediaSessionManager.getInstance().registerCallback('playPrevious', () => {
      this.switchPrev(context);
    });
    MediaSessionManager.getInstance().registerCallback('setLoopMode', (loopMode: AVSessionMananger.LoopMode) => {
      loopMode;
      this.switchRepeatMode();
    });
    MediaSessionManager.getInstance().registerCallback('toggleFavorite', (assetId: string) => {
      assetId;
      this.toggleFavorite();
    });
    await MediaSessionManager.getInstance().initAudioSession(context);

    this.audioPlayer.registerCallback('durationUpdate', (duration: number) => {
      this.duration = duration;
    });
    this.audioPlayer.registerCallback('timeUpdate', (timeMs: number) => {
      if (!this.isSeeking) {
        this.currTime = timeMs;
        MediaSessionManager.getInstance().updateElapsedTime(timeMs);
      }
      this.updateLyrics(timeMs);
    });
    this.audioPlayer.registerCallback('seekDone', (timeMs: number) => {
      this.currTime = timeMs;
      this.isSeeking = false;
      MediaSessionManager.getInstance().updatePlayPosition(timeMs);
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
      MediaSessionManager.getInstance().updatePlayState(this.currTime, state);

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

    await this.audioStore.initStore(context);
    await this.settings.initPreference(context);
    this.repeatMode = (await this.settings.getSetting(SettingKey.AUDIO_REPEAT_MODE)) as AudioRepeatMode;
  }

  updatePlaylist(audioList: AudioItemViewModelList, currItem: AudioItemViewModel) {
    this.audioList = [...audioList];
    this.currAudioItem = this.audioList[audioList.indexOf(currItem)];
  }

  async setAudioAsset(audioInfo: AudioInfoModel, context: Context) {
    const lyricsText = await this.loadLyrics(audioInfo);
    this.isFavorite = audioInfo.favorite === 0 ? false : true;
    await this.audioPlayer.setMediaAsset(audioInfo.audioPath);

    await MediaSessionManager.getInstance().setAudioAsset(context, audioInfo, lyricsText);
    await MediaSessionManager.getInstance().updateLoopMode(this.currTime, this.repeatMode);
    await MediaSessionManager.getInstance().updateFavorite(this.currTime, audioInfo.favorite === 0 ? false : true);
  }

  async toggleFavorite(): Promise<void> {
    if (this.currAudioItem) {
      let isFavorite: boolean = false;
      if (this.currAudioItem.audioInfo.favorite === 0) {
        isFavorite = true;
      } else {
        isFavorite = false;
      }
      await this.audioStore.updateAudioFavorite(this.currAudioItem.audioInfo, isFavorite);
      await MediaSessionManager.getInstance().updateFavorite(this.currTime, isFavorite);
      this.currAudioItem.updateFavorite(isFavorite);
      this.isFavorite = isFavorite;
      // Notify
      let eventData: emitter.EventData = {
        data: {
          'info': this.currAudioItem.audioInfo,
        }
      };
      emitter.emit(TOGGLE_FAVORITE_EVENT, eventData);
    }
  }

  async switchShuffle(context: Context): Promise<void> {
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
    MediaSessionManager.getInstance().updateLoopMode(this.currTime, this.repeatMode);
  }

  async play(): Promise<void> {
    await this.audioPlayer.play();
  }

  async pause(): Promise<void> {
    await this.audioPlayer.pause();
  }

  seek(timeMs: number): void {
    timeMs = Math.min(this.duration, Math.max(0, timeMs));
    this.audioPlayer.seek(timeMs);
  }

  async deleteAudio(audioInfo: AudioInfoModel, context: Context) {
    if (this.currAudioItem) {
      if (audioInfo.id === this.currAudioItem.id) {
        this.audioPlayer.reset();
        // Switch to next
        if (this.audioList.length > 1) {
          await this.switchNext(context);
        } else {
          this.currAudioItem = undefined;
        }
      }
      // Delete from audio list
      const delIdx = this.audioList.findIndex((item: AudioItemViewModel) => {
        return item.audioInfo.id === audioInfo.id;
      });
      if (delIdx !== -1) {
        this.audioList.splice(delIdx, 1);
      }
    }
  }

  private updateLyrics(timeMs: number) {
    for (let i = 0; i < this.lyricsInfoArr.length; ++i) {
      const startMs = this.lyricsInfoArr[i].startMs;
      const endMS = i === this.lyricsInfoArr.length - 1 ? Infinity : this.lyricsInfoArr[i + 1].startMs;
      if (timeMs >= startMs && timeMs < endMS) {
        if (this.currLyricsIdx !== i) {
          this.currLyricsIdx = i;
          this.lyricsScroller.scrollToIndex(this.currLyricsIdx, true, ScrollAlign.CENTER);
        }
        this.currLyrics = this.lyricsInfoArr[i].text;
      }
    }
  }

  private async loadLyrics(audioInfo: AudioInfoModel): Promise<string | undefined> {
    this.currLyrics = '';
    this.currLyricsIdx = 0;
    if (!audioInfo.lyricsPath) {
      this.lyricsInfoArr = [];
      return undefined;
    }
    try {
      const newLyricsInfoArr: Array<LyricsInfo> = [];
      const lyricsText = await fileIo.readText(audioInfo.lyricsPath);
      const lyricsLines = lyricsText.split('\n');
      for (let i = 0; i < lyricsLines.length; ++i) {
        const lyricsInfo = new LyricsInfo();
        if (lyricsInfo.updateLyrics(lyricsLines[i])) {
          newLyricsInfoArr.push(lyricsInfo);
        }
      }
      this.lyricsInfoArr = newLyricsInfoArr;
      return lyricsText;
    } catch (error) {
      console.error(`Failed to load lyrics from ${audioInfo.lyricsPath}. Cause: ${JSON.stringify(error)}`);
      return undefined;
    }
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