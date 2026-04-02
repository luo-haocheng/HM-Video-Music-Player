import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { AudioListInfo, AudioListType } from '../view/AudioListView';
import { AudioItemViewModel } from './AudioItemViewModel';

@Observed
export class AudioItemViewModelList extends Array<AudioItemViewModel> {
}

@Observed
export class AudioListViewModel {
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  public audioListInfo: AudioListInfo = new AudioListInfo();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
  }

  async updateAudio(audioInfo: AudioInfoModel): Promise<void> {
    switch (this.audioListInfo.type) {
      case AudioListType.PLAY_LIST:
        if (this.audioListInfo.name === '*') {
          const audioItem = new AudioItemViewModel();
          audioItem.updateAudioItem(audioInfo);
          this.audioList.push(audioItem);
        }
        break;
      case AudioListType.ALNUM_LIST:
        if (this.audioListInfo.name === audioInfo.album) {
          const audioItem = new AudioItemViewModel();
          audioItem.updateAudioItem(audioInfo);
          this.audioList.push(audioItem);
        }
        break;
      case AudioListType.ARTIST_LIST:
        if (this.audioListInfo.name === audioInfo.artist) {
          const audioItem = new AudioItemViewModel();
          audioItem.updateAudioItem(audioInfo);
          this.audioList.push(audioItem);
        }
        break;
    }
  }

  async loadAudioList(): Promise<void> {
    switch (this.audioListInfo.type) {
      case AudioListType.PLAY_LIST:
        await this.loadFromPlayList(this.audioListInfo.name);
        break;
      case AudioListType.ALNUM_LIST:
        await this.loadFromAlbumList(this.audioListInfo.name);
        break;
      case AudioListType.ARTIST_LIST:
        await this.loadFromArtistList(this.audioListInfo.name);
        break;
    }
  }

  private async loadFromPlayList(name: string | null) {
    const audioInfoList = await this.audioStore.selectAudioByPlayList(name);
    for (let i = 0; i < audioInfoList.length; ++i) {
      let audioItem = new AudioItemViewModel();
      audioItem.updateAudioItem(audioInfoList[i]);
      this.audioList.push(audioItem);
    }
  }

  private async loadFromAlbumList(name: string | null) {
    const audioInfoList = await this.audioStore.selectAudioByAlbum(name);
    for (let i = 0; i < audioInfoList.length; ++i) {
      let audioItem = new AudioItemViewModel();
      audioItem.updateAudioItem(audioInfoList[i]);
      this.audioList.push(audioItem);
    }
  }

  private async loadFromArtistList(name: string | null) {
    const audioInfoList = await this.audioStore.selectAudioByArtist(name);
    for (let i = 0; i < audioInfoList.length; ++i) {
      let audioItem = new AudioItemViewModel();
      audioItem.updateAudioItem(audioInfoList[i]);
      this.audioList.push(audioItem);
    }
  }
}