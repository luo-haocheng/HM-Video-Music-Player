import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListInfoModel } from '../model/PlayListInfoModel';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';

@Observed
export class AudioPlayListViewModel {
  @Track allPlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track favoritePlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track userPlaylistArray: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    // update all playlist
    this.allPlaylist.playListName = '全部音频';
    this.allPlaylist.playListCount = await this.audioStore.playlistAudioCount(ALL_AUDIO);
    // update favorite playlist
    this.favoritePlaylist.playListName = '我的收藏';
    this.favoritePlaylist.playListCount = await this.audioStore.playlistAudioCount(FAVORITE_AUDIO);
    // update user playlist
    const playlistArray = await this.audioStore.selectAllPlaylist();
    for (let i = 0; i < playlistArray.length; ++i) {
      const playlistItem = new PlayListItemViewModel();
      playlistItem.playListName = playlistArray[i].name;
      playlistItem.playListCount = await this.audioStore.playlistAudioCount(playlistArray[i].name);
      this.userPlaylistArray.push(playlistItem);
    }
  }

  async updatePlayList(playlistInfo: PlayListInfoModel): Promise<void> {
    const playlistItem = new PlayListItemViewModel();
    playlistItem.playListName = playlistInfo.name;
    playlistItem.playListCount = 0;
    this.userPlaylistArray.push(playlistItem);
  }

  async updateAudio(audioInfo: AudioInfoModel): Promise<void> {
    audioInfo;
    this.allPlaylist.playListCount += 1;
  }

  async removeAudio(audioInfo: AudioInfoModel): Promise<void> {
    audioInfo;
    this.allPlaylist.playListCount -= 1;
    // todo
  }

  async addToPlaylist(playlistName: string | null): Promise<void> {
    if (playlistName === FAVORITE_AUDIO) {
      this.favoritePlaylist.playListCount += 1;
    }
    for (let i = 0; i < this.userPlaylistArray.length; ++i) {
      if (playlistName === this.userPlaylistArray[i].playListName) {
        this.userPlaylistArray[i].playListCount += 1;
      }
    }
  }

  async deleteFromPlaylist(playlistName: string | null): Promise<void> {
    if (playlistName === FAVORITE_AUDIO) {
      this.favoritePlaylist.playListCount -= 1;
    }
    for (let i = 0; i < this.userPlaylistArray.length; ++i) {
      if (playlistName === this.userPlaylistArray[i].playListName) {
        this.userPlaylistArray[i].playListCount -= 1;
      }
    }
  }
}