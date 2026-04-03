import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

@Observed
export class AudioArtistListViewModel {
  @Track unknownArtist?: PlayListItemViewModel = undefined;
  @Track artistList: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    const audioInfoList = await this.audioStore.selectAllAudio();
    const artistMap: Map<string | null, AudioInfoModel[]> = new Map();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let artist: string | null = audioInfoList[i].artist;
      if (artistMap.has(artist)) {
        artistMap.get(artist)?.push(audioInfoList[i]);
      } else {
        artistMap.set(artist, [audioInfoList[i]]);
      }
    }
    for (const key of artistMap.keys()) {
      const artistItem = new PlayListItemViewModel();
      artistItem.playListName = key;
      artistItem.playListCount = artistMap.get(key)?.length ?? 0;
      this.updateAlbumCover(artistItem, artistMap.get(key));
      if (artistItem.playListName) {
        this.artistList.push(artistItem);
      } else {
        artistItem.playListName = '未知艺术家';
        this.unknownArtist = artistItem;
      }
    }
  }

  async updateAudio(audioInfo: AudioInfoModel): Promise<void> {
    if (audioInfo.artist) {
      const idx = this.artistList.findIndex((item: PlayListItemViewModel) => {
        return item.playListName === audioInfo.artist;
      });
      if (idx === -1) {
        const playlistItem = new PlayListItemViewModel();
        playlistItem.playListName = audioInfo.artist;
        playlistItem.playListCount = 1;
        this.artistList.push(playlistItem);
      } else {
        this.artistList[idx].playListCount += 1;
      }
    } else {
      if (this.unknownArtist) {
        this.unknownArtist.playListCount += 1;
      } else {
        const playlistItem = new PlayListItemViewModel();
        playlistItem.playListName = '未知艺术家';
        playlistItem.playListCount = 1;
        this.artistList.push(playlistItem);
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