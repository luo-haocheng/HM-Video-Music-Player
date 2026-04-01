import { AudioPlayListViewModel } from '../viewmodel/AudioPlayListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const PLAYLIST_PATH_STACK = 'PlayListPathStack';

@Component
export struct AudioPlayListView {
  @State audioPlaylistVM: AudioPlayListViewModel = new AudioPlayListViewModel();
  @Consume(PLAYLIST_PATH_STACK) playListStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext() as Context;
    this.audioPlaylistVM.init(context);
  }

  build() {
    List() {
      ListItem() {
        PlayListBoxView({ playlistVM: this.audioPlaylistVM.allPlaylist });
      }
      .onClick(() => {
        const audioListInfo: AudioListInfo = {
          type: AudioListType.PLAY_LIST,
          name: ALL_AUDIO
        };
        this.playListStack.pushPath({ name: 'AudioList', param: audioListInfo });
      });

      ListItem() {
        PlayListBoxView({ playlistVM: this.audioPlaylistVM.favoritePlaylist });
      }
      .onClick(() => {
        const audioListInfo: AudioListInfo = {
          type: AudioListType.PLAY_LIST,
          name: FAVORITE_AUDIO
        };
        this.playListStack.pushPath({ name: 'AudioList', param: audioListInfo });
      });
    }
    .width('100%')
    .height('100%')
    .contentEndOffset(8)
    .contentStartOffset(8)
    .scrollBar(BarState.Off)
    .padding({ left: 8, right: 8 })
    .backgroundColor(`rgb(243, 243, 243)`)
    .divider({ strokeWidth: 8, color: 'rgb(243, 243, 243)' });
  }
}