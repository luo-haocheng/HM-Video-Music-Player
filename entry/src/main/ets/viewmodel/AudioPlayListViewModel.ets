import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../view/PlayListItemViewModel';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';

@Observed
export class AudioPlayListViewModel {
  @Track allPlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track favoritePlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track userPlaylist: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    // update all playlist
    this.allPlaylist.playListName = '全部音乐';
    this.allPlaylist.playListCount = await this.audioStore.playlistAudioCount(ALL_AUDIO);
    // update favorite playlist
    this.favoritePlaylist.playListName = '我的收藏';
    this.favoritePlaylist.playListCount = await this.audioStore.playlistAudioCount(FAVORITE_AUDIO);
  }
}