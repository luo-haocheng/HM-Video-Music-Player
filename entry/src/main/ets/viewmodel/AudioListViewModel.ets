import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { AudioListInfo, AudioListType } from '../view/AudioListView';
import { AudioItemViewModel } from './AudioItemViewModel';

@Observed
export class AudioItemViewModelList extends Array<AudioItemViewModel> {
}

@Observed
export class AudioListViewModel {
  @Track audioList: AudioItemViewModelList = new AudioItemViewModelList();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
  }

  async loadAudioList(audioListInfo: AudioListInfo): Promise<void> {
    switch (audioListInfo.type) {
      case AudioListType.PLAY_LIST:
        await this.loadFromPlayList(audioListInfo.name);
        break;
      case AudioListType.ALNUM_LIST:
        await this.loadFromAlbumList(audioListInfo.name);
        break;
      case AudioListType.ARTIST_LIST:
        await this.loadFromArtistList(audioListInfo.name);
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