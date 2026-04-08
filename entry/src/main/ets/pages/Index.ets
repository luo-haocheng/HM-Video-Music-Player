import { AudioLibraryView } from '../view/AudioLibraryView';
import { VideoLibraryView } from '../view/VideoLibraryView';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MAIN_PAGE_STACK = 'MainPageStack';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Entry
@Component
struct Index {
  @State selectIdx: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Provide(MAIN_PAGE_STACK) mainPageStack: NavPathStack = new NavPathStack();
  @Provide(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  @Builder
  tabBarBuilder(icon: ResourceStr, name: ResourceStr, index: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1)
        .fillColor(this.selectIdx === index ? '#FF007DFF' : '#99182431');

      Text(name)
        .fontSize(12)
        .fontWeight(this.selectIdx === index ? 600 : 400)
        .fontColor(this.selectIdx === index ? '#FF007DFF' : '#99182431');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  build() {
    Navigation(this.mainPageStack) {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
      }) {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            VideoLibraryView();
          }
          .tabBar(this.tabBarBuilder($r('app.media.video'), '视频库', 0));

          TabContent() {
            AudioLibraryView();
          }
          .tabBar(this.tabBarBuilder($r('app.media.music'), '音频库', 1));

          TabContent() {
            Text('设置')
              .fontSize(30);
          }
          .tabBar(this.tabBarBuilder($r('app.media.gear'), '设置', 2));
        }
        .scrollable(false)
        .padding({ bottom: this.getUIContext().px2vp(this.bottomRectHeight) })
        .onSelected((index: number) => {
          this.selectIdx = index;
        });
      }
      .backgroundColor(Color.White);
    }
    .hideToolBar(true)
    .mode(NavigationMode.Stack);
  }
}