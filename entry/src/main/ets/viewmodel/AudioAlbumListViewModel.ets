import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

@Observed
export class AudioAlbumListViewModel {
  @Track unknownAlbum?: PlayListItemViewModel = undefined;
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
      albumItem.playListCount = albumMap.get(key)?.length ?? 0;
      this.updateAlbumCover(albumItem, albumMap.get(key));
      if (albumItem.playListName) {
        this.albumList.push(albumItem);
      } else {
        albumItem.playListName = '未知专辑';
        this.unknownAlbum = albumItem;
      }
    }
  }

  async updateAudio(audioInfo: AudioInfoModel): Promise<void> {
    if (audioInfo.album) {
      const idx = this.albumList.findIndex((item: PlayListItemViewModel) => {
        return item.playListName === audioInfo.album;
      });
      if (idx === -1) {
        const playlistItem = new PlayListItemViewModel();
        playlistItem.playListName = audioInfo.album;
        playlistItem.playListCount = 1;
        this.albumList.push(playlistItem);
      } else {
        this.albumList[idx].playListCount += 1;
      }
    } else {
      if (this.unknownAlbum) {
        this.unknownAlbum.playListCount += 1;
      } else {
        const playlistItem = new PlayListItemViewModel();
        playlistItem.playListName = '未知专辑';
        playlistItem.playListCount = 1;
        this.unknownAlbum = playlistItem;
      }
    }
  }

  private async updateAlbumCover(item: PlayListItemViewModel, audioInfoList?: AudioInfoModel[]): Promise<void> {
    if (audioInfoList && !item.albumCover) {
      for (let i = 0; i < audioInfoList.length; ++i) {
        const coverPath = audioInfoList[i].coverPath;
        if (coverPath) {
          item.updateAlbumCover(coverPath);
          break;
        }
      }
    }
  }
}