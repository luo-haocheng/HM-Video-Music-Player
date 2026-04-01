import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../view/PlayListItemViewModel';

@Observed
export class AudioArtistListViewModel {
  @Track unknownArtist?: PlayListItemViewModel = new PlayListItemViewModel();
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
      let playlistCount = artistMap.get(key)?.length;
      artistItem.playListCount = playlistCount ? playlistCount : 0;
      if (artistItem.playListName) {
        this.artistList.push(artistItem);
      } else {
        artistItem.playListName = '未知艺术家';
        this.unknownArtist = artistItem;
      }
    }
  }
}