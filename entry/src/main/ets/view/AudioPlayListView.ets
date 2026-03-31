import { PlayListBoxView } from './PlayListBoxView';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const PLAYLIST_PATH_STACK = 'PlayListPathStack';

@Component
export struct AudioPlayListView {
  @Consume(PLAYLIST_PATH_STACK) playListStack: NavPathStack = new NavPathStack();

  build() {
    List() {
      ListItem() {
        PlayListBoxView({ playListName: '所有音乐' });
      }
      .onClick(() => {
        this.playListStack.pushPath({ name: 'AudioList', param: ALL_AUDIO });
      });

      ListItem() {
        PlayListBoxView({ playListName: '我的收藏' });
      }
      .onClick(() => {
        this.playListStack.pushPath({ name: 'AudioList', param: FAVORITE_AUDIO });
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