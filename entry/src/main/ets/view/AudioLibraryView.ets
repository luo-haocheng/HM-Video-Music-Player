import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioLibraryViewModel } from '../viewmodel/AudioLibraryViewModel';
import { AudioPlayListView } from './AudioPlayListView';

const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const PLAYLIST_PATH_STACK = 'PlayListPathStack';
const IMPORT_OPTS: ImportOption[] = [
  { icon: $r('app.media.music'), text: '音频文件导入', color: Color.Blue },
  { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
  { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
  { icon: $r('app.media.question_circle'), text: '导入疑问', color: Color.Gray },
];

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Component
export struct AudioLibraryView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Provide(PLAYLIST_PATH_STACK) playListStack: NavPathStack = new NavPathStack();
  @State audioList: AudioItemViewModel[] = [];
  @State audioLibVM: AudioLibraryViewModel = new AudioLibraryViewModel();
  private importDialogId: number = -1;

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioLibVM.init(context);
    this.audioList = await this.audioLibVM.loadAllAudio();
  }

  @Builder
  importOptionBuilder(option: ImportOption) {
    Row({ space: 12 }) {
      Image(option.icon)
        .width(30)
        .aspectRatio(1)
        .fillColor(option.color)
        .backgroundColor(Color.Transparent);

      Text(option.text)
        .fontSize(16)
        .fontWeight(FontWeight.Normal);

      Blank();

      Image($r('app.media.chevron_right'))
        .width(12)
        .aspectRatio(1)
        .backgroundColor(Color.Transparent);
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 });
  }

  @Builder
  importDialogBuilder() {
    Column() {
      Row() {
        Text('选择导入方式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold);

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.xmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor(Color.Black);
        }
        .padding(6)
        .backgroundColor('#AADCDCDC')
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween);

      List() {
        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[0]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromAudioLib(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[1]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromFileMgr(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[2]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromDownloadDir(context);
        });


        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[3]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          // todo
        });
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, startMargin: 46, color: 'rgb(240, 240, 240)' });
    }
    .padding(16);
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      Row() {
        Row({ space: 12 }) {
          Text('音频')
            .maxLines(1)
            .fontSize(20)
            .layoutWeight(1)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1);

        Row({ space: 12 }) {
          Button({ type: ButtonType.Capsule, stateEffect: false }) {
            Text('多选')
              .fontSize(14)
              .fontColor(Color.Black);
          }
          .width(36 * 1.5)
          .aspectRatio(1.5)
          .backgroundColor('#AADCDCDC');

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.plus'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC')
          .onClick(() => {
            this.getUIContext()
              .getPromptAction()
              .openCustomDialog({
                builder: () => {
                  this.importDialogBuilder();
                },
                width: '100%',
                alignment: DialogAlignment.Bottom,
                transition: TransitionEffect.SLIDE,
                offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
              })
              .then((dialogId: number) => {
                this.importDialogId = dialogId;
              })
              .catch((err: BusinessError) => {
                console.error(`Failed to open import dialog. Cuase: ${JSON.stringify(err)}`);
              });
          });

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.dot_grid_2x2'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC');
        };
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: 16,
        right: 16,
        bottom: 8,
        top: 8
      });

      Tabs() {
        TabContent() {
          Navigation(this.playListStack) {
            AudioPlayListView();
          }
          .hideToolBar(true)
          .mode(NavigationMode.Stack);
        }
        .tabBar('歌单');

        TabContent() {
          Text('专辑')
            .fontSize(30)
            .fontColor(Color.Black);
        }
        .tabBar('专辑');

        TabContent() {
          Text('艺术家')
            .fontSize(30)
            .fontColor(Color.Black);
        }
        .tabBar('艺术家');
      };

    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });

  }
}