import { VideoListView } from '../view/VideoListView';

const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Entry
@Component
struct Index {
  @State selectIdx: number = 0;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Provide('MainPageStack') mainPageStack: NavPathStack = new NavPathStack();
  @Provide('VideoTabStack') videoTabStack: NavPathStack = new NavPathStack();

  @Builder
  tabBarBuilder(icon: ResourceStr, name: ResourceStr, index: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1)
        .fillColor(this.selectIdx === index ? Color.Green : Color.Black);
      Text(name)
        .fontSize(12)
        .fontColor(this.selectIdx === index ? Color.Green : Color.Black);
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
            Flex({
              direction: FlexDirection.Column,
              justifyContent: FlexAlign.Start,
              alignItems: ItemAlign.Center
            }) {
              Row() {
                Text('视频')
                  .fontSize(24)
                  .fontColor(Color.Black);
              }
              .width('100%')
              .margin({ top: 8, bottom: 8 })
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center);

              Navigation(this.videoTabStack) {
                VideoListView();
              }
              .hideToolBar(true)
              .mode(NavigationMode.Stack);
            }
            .margin({ top: this.getUIContext().px2vp(this.topRectHeight) });
          }
          .tabBar(this.tabBarBuilder($r('app.media.video'), '视频库', 0));

          TabContent() {
            Text('音频')
              .fontSize(30);
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