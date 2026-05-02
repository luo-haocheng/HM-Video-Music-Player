import { AudioLibraryView, AudioPlayerViewModel } from 'audio_library';
import { VideoLibraryView, VideoPlayerViewModel } from 'video_library';
import { ApplicationStateChangeCallback, common } from '@kit.AbilityKit';
import { ContinuousTaskManager } from 'util';

const VIDEO_PLAYER_VM = 'VideoPlayerVM';
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
  @Provide(VIDEO_PLAYER_VM) videoPlayerVM: VideoPlayerViewModel = new VideoPlayerViewModel();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear(): Promise<void> {
    const applicationContext = this.context.getApplicationContext();
    const applicationStageChangeCallback: ApplicationStateChangeCallback = {
      onApplicationForeground: async (): Promise<void> => {
        if (await ContinuousTaskManager.hasContinuousTasks(this.context)) {
          await ContinuousTaskManager.stopContinuousTask(this.context);
        }
        this.videoPlayerVM.onForeground();
        this.audioPlayerVM.onForeground();
      },
      onApplicationBackground: async (): Promise<void> => {
        if (await ContinuousTaskManager.hasContinuousTasks(this.context)) {
          await ContinuousTaskManager.stopContinuousTask(this.context);
        }
        this.videoPlayerVM.onBackground(this.context);
        this.audioPlayerVM.onBackground(this.context);
      }
    };
    applicationContext.on('applicationStateChange', applicationStageChangeCallback);
  }

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
          .tabBar(this.tabBarBuilder($r('app.media.video'), '视频', 0));

          TabContent() {
            AudioLibraryView();
          }
          .tabBar(this.tabBarBuilder($r('app.media.music'), '音频', 1));

          TabContent() {
            Text('设置')
              .fontSize(30);
          }
          .tabBar(this.tabBarBuilder($r('app.media.gear'), '设置', 2));
        }
        .scrollable(false)
        .barBackgroundColor('#F1F3F5')
        .onSelected((index: number) => {
          this.selectIdx = index;
        });
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')
      .padding({ bottom: this.getUIContext().px2vp(this.bottomRectHeight) });
    }
    .hideToolBar(true)
    .mode(NavigationMode.Stack);
  }
}