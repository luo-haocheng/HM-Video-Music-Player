import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

const FAVORITE_AUDIO = '**';
const ADD_TO_PLAYLIST_EVENT = 'AddToPlaylist';

@Observed
export class AddToPlaylistViewModel {
  @Track favoritePlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track userPlaylistArray: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    // update favorite playlist
    this.favoritePlaylist.playListName = '我的收藏';
    this.favoritePlaylist.playlistInfo.name = FAVORITE_AUDIO;
    this.favoritePlaylist.playListCount = (await this.audioStore.selectPlaylistAudioList(FAVORITE_AUDIO)).length;
    // update user playlist
    const playlistArr = await this.audioStore.selectAllPlaylist();
    for (let i = 0; i < playlistArr.length; ++i) {
      const playlistItem = new PlayListItemViewModel();
      playlistItem.updatePlaylistItem(playlistArr[i]);
      playlistItem.playListCount = (await this.audioStore.selectPlaylistAudioList(playlistArr[i].name)).length;
      this.userPlaylistArray.push(playlistItem);
    }
  }

  async addToPlaylist(audioInfo: AudioInfoModel): Promise<void> {
    let success = false;
    if (this.favoritePlaylist.isChoice) {
      success = await this.audioStore.insertAudio2Playlist(audioInfo, this.favoritePlaylist.playlistInfo);
      if (success) {
        this.notifyAddToPlaylist(audioInfo, FAVORITE_AUDIO);
      }
    }
    for (let i = 0; i < this.userPlaylistArray.length; i++) {
      if (this.userPlaylistArray[i].isChoice) {
        success = await this.audioStore.insertAudio2Playlist(audioInfo, this.userPlaylistArray[i].playlistInfo);
        if (success) {
          this.notifyAddToPlaylist(audioInfo, this.userPlaylistArray[i].playListName);
        }
      }
    }
  }

  private async notifyAddToPlaylist(audioInfo: AudioInfoModel, playlistName: string | null) {
    const eventData: emitter.EventData = {
      data: {
        'info': audioInfo,
        'name': playlistName,
      }
    };
    emitter.emit(ADD_TO_PLAYLIST_EVENT, eventData);
  }
}