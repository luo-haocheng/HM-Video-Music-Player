import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

@Observed
export class AddToPlaylistViewModel {
  @Track userPlaylistArray: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    const playlistArr = await this.audioStore.selectAllPlaylist();
    for (let i = 0; i < playlistArr.length; ++i) {
      const playlistItem = new PlayListItemViewModel();
      playlistItem.updatePlaylistItem(playlistArr[i]);
      playlistItem.playListCount = await this.audioStore.playlistAudioCount(playlistArr[i].name);
      this.userPlaylistArray.push(playlistItem);
    }
  }

  async addToPlaylist(audioInfo: AudioInfoModel): Promise<void> {
    for (let i = 0; i < this.userPlaylistArray.length; i++) {
      if (this.userPlaylistArray[i].isChoice) {
        await this.audioStore.insertAudio2Playlist(audioInfo, this.userPlaylistArray[i].playlistInfo);
      }
    }
  }
}