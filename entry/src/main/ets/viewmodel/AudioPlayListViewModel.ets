import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListInfoModel } from '../model/PlayListInfoModel';
import { Settings } from '../model/Settings';
import { SettingKey, SortModeValue, SortRuleValue } from '../model/SettingsModel';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';
import { i18n } from '@kit.LocalizationKit';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';

@Observed
export class AudioPlayListViewModel {
  @Track allPlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track favoritePlaylist: PlayListItemViewModel = new PlayListItemViewModel();
  @Track userPlaylistArray: PlayListItemViewModelArray = new PlayListItemViewModelArray();
  private settings: Settings = new Settings();
  private playlistMap: Map<string | null, AudioInfoModel[]> = new Map();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    await this.settings.initPreference(context);
    // update all playlist
    const allAudioList = await this.audioStore.selectAllAudio();
    this.updateAlbumCover(this.allPlaylist, allAudioList);
    this.allPlaylist.playListCount = allAudioList.length;
    this.allPlaylist.playListName = '全部音频';
    this.playlistMap.set(ALL_AUDIO, allAudioList);
    // update favorite playlist
    const favoriteAudioList = await this.audioStore.selectFavoriteAudio();
    this.updateAlbumCover(this.favoritePlaylist, favoriteAudioList);
    this.favoritePlaylist.playListCount = favoriteAudioList.length;
    this.favoritePlaylist.playListName = '我的收藏';
    this.playlistMap.set(FAVORITE_AUDIO, favoriteAudioList);
    // update user playlist
    const playlistArray = await this.audioStore.selectAllPlaylist();
    for (let i = 0; i < playlistArray.length; ++i) {
      const audioList = await this.audioStore.selectAudioByPlayList(playlistArray[i].name);
      const playlistItem = new PlayListItemViewModel();
      this.updateAlbumCover(playlistItem, audioList);
      playlistItem.playlistInfo = playlistArray[i];
      playlistItem.playListCount = audioList.length;
      playlistItem.playListName = playlistArray[i].name;
      this.playlistMap.set(playlistArray[i].name, audioList);
      this.userPlaylistArray.push(playlistItem);
    }
    this.sortUserPlaylist();
  }

  async updatePlayList(playlistInfo: PlayListInfoModel): Promise<void> {
    const playlistItem = new PlayListItemViewModel();
    playlistItem.playListName = playlistInfo.name;
    playlistItem.playlistInfo = playlistInfo;
    playlistItem.playListCount = 0;
    this.userPlaylistArray.push(playlistItem);
    this.sortUserPlaylist();
  }

  async updateAudio(audioInfo: AudioInfoModel): Promise<void> {
    const allAudioList = this.playlistMap.get(ALL_AUDIO);
    if (allAudioList) {
      allAudioList.push(audioInfo);
      this.allPlaylist.playListCount += 1;
    }
  }

  async toggleFavorite(audioInfo: AudioInfoModel): Promise<void> {
    const favoriteAudioList = this.playlistMap.get(FAVORITE_AUDIO);
    if (favoriteAudioList) {
      if (audioInfo.favorite) {
        favoriteAudioList.push(audioInfo);
        this.favoritePlaylist.playListCount += 1;
      } else {
        const idx = favoriteAudioList.findIndex((info: AudioInfoModel) => {
          return info.id === audioInfo.id;
        });
        if (idx !== -1) {
          favoriteAudioList.splice(idx, 1);
          this.favoritePlaylist.playListCount -= 1;
        }
      }
    }
  }

  async removeAudio(audioInfo: AudioInfoModel): Promise<void> {
    // remove from all playlist
    const allAudioList = this.playlistMap.get(ALL_AUDIO);
    if (allAudioList) {
      const idx = allAudioList.findIndex((info: AudioInfoModel) => {
        return info.id === audioInfo.id;
      });
      if (idx !== -1) {
        allAudioList.splice(idx, 1);
      }
      this.allPlaylist.playListCount = allAudioList.length;
    }
    // remove from favorite playlist
    const favoriteAudioList = this.playlistMap.get(FAVORITE_AUDIO);
    if (favoriteAudioList) {
      const idx = favoriteAudioList.findIndex((info: AudioInfoModel) => {
        return info.id === audioInfo.id;
      });
      if (idx !== -1) {
        favoriteAudioList.splice(idx, 1);
      }
      this.favoritePlaylist.playListCount = favoriteAudioList.length;
    }
    // remove from user playlist
    for (let i = 0; i < this.userPlaylistArray.length; ++i) {
      const userAudioList = this.playlistMap.get(this.userPlaylistArray[i].playListName);
      if (userAudioList) {
        const idx = userAudioList.findIndex((info: AudioInfoModel) => {
          return info.id === audioInfo.id;
        });
        if (idx !== -1) {
          userAudioList.splice(idx, 1);
        }
        this.userPlaylistArray[i].playListCount = userAudioList.length;
      }
    }
  }

  async addToPlaylist(audioInfo: AudioInfoModel, playlistName: string | null): Promise<void> {
    if (playlistName === FAVORITE_AUDIO) {
      this.favoritePlaylist.playListCount += 1;
      this.playlistMap.get(FAVORITE_AUDIO)?.push(audioInfo);
    }
    for (let i = 0; i < this.userPlaylistArray.length; ++i) {
      if (playlistName === this.userPlaylistArray[i].playListName) {
        this.userPlaylistArray[i].playListCount += 1;
        this.playlistMap.get(this.userPlaylistArray[i].playListName)?.push(audioInfo);
      }
    }
  }

  async deleteUserPlaylist(selectedIdx: number): Promise<void> {
    if (selectedIdx < 0 || selectedIdx >= this.userPlaylistArray.length) {
      console.error(`Failed to delete selected user playlist. Index ${selectedIdx} out of range ${0}-${this.userPlaylistArray.length}`);
      return;
    }
    // Delete database record
    const delPlaylistInfo = this.userPlaylistArray[selectedIdx].playlistInfo;
    await this.audioStore.deletePlaylist(delPlaylistInfo);
    // Delete from view
    this.userPlaylistArray.splice(selectedIdx, 1);
  }

  async deleteFromPlaylist(audioInfo: AudioInfoModel, playlistName: string | null): Promise<void> {
    if (playlistName === FAVORITE_AUDIO) {
      const favoriteAudioList = this.playlistMap.get(FAVORITE_AUDIO);
      if (favoriteAudioList) {
        const delIdx = favoriteAudioList.findIndex((info: AudioInfoModel) => {
          return info.id === audioInfo.id;
        });
        if (delIdx !== -1) {
          favoriteAudioList.splice(delIdx, 1);
        }
        this.favoritePlaylist.playListCount = favoriteAudioList.length;
      }
    }
    for (let i = 0; i < this.userPlaylistArray.length; ++i) {
      if (playlistName === this.userPlaylistArray[i].playListName) {
        const userAudioList = this.playlistMap.get(this.userPlaylistArray[i].playListName);
        if (userAudioList) {
          const delIdx = userAudioList.findIndex((info: AudioInfoModel) => {
            return info.id === audioInfo.id;
          });
          if (delIdx !== -1) {
            userAudioList.splice(delIdx, 1);
            this.userPlaylistArray[i].playListCount -= 1;
          }
        }
        break;
      }
    }
  }

  async sortUserPlaylist(): Promise<void> {
    const sortMode = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_MODE);
    const sortRule = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_RULE);
    if (sortMode === SortModeValue.DATE_ADD) {
      this.userPlaylistArray.sort((playlistA: PlayListItemViewModel, playlistB: PlayListItemViewModel) => {
        const diff = playlistA.playlistInfo.dateAdd - playlistB.playlistInfo.dateAdd;
        return sortRule === SortRuleValue.ASCENDING ? diff : -diff;
      });
    } else if (sortMode === SortModeValue.PLAYLIST_NAME) {
      this.userPlaylistArray.sort((playlistA: PlayListItemViewModel, playlistB: PlayListItemViewModel) => {
        const diff = this.sortByFileName(playlistA.playListName ?? '', playlistB.playListName ?? '');
        return sortRule === SortRuleValue.ASCENDING ? diff : -diff;
      });
    } else {
      this.userPlaylistArray.sort((playlistA: PlayListItemViewModel, playlistB: PlayListItemViewModel) => {
        const diff = playlistA.playlistInfo.dateAdd - playlistB.playlistInfo.dateAdd;
        return sortRule === SortRuleValue.ASCENDING ? diff : -diff;
      });
    }
  }

  private sortByFileName(nameA: string, nameB: string): number {
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn;Latin-Ascii');
    let name1 = transliterator.transform(nameA).toLowerCase();
    let name2 = transliterator.transform(nameB).toLowerCase();
    if (name1 === name2) {
      return 0;
    }
    return name1 > name2 ? 1 : -1;
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