import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../view/PlayListItemViewModel';

@Observed
export class AudioAlbumListViewModel {
  @Track unknownAlbum?: PlayListItemViewModel = new PlayListItemViewModel();
  @Track albumList: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    const audioInfoList = await this.audioStore.selectAllAudio();
    const albumMap: Map<string | null, AudioInfoModel[]> = new Map();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let album: string | null = audioInfoList[i].album;
      if (albumMap.has(album)) {
        albumMap.get(album)?.push(audioInfoList[i]);
      } else {
        albumMap.set(album, [audioInfoList[i]]);
      }
    }
    for (const key of albumMap.keys()) {
      const albumItem = new PlayListItemViewModel();
      albumItem.playListName = key;
      let playlistCount = albumMap.get(key)?.length;
      albumItem.playListCount = playlistCount ? playlistCount : 0;
      if (albumItem.playListName) {
        this.albumList.push(albumItem);
      } else {
        albumItem.playListName = '未知专辑';
        this.unknownAlbum = albumItem;
      }
    }
  }
}