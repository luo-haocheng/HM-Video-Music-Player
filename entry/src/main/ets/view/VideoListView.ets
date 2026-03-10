import VideoItemViewModel from '../viewmodel/VideoItemViewModel';
import VideoListViewModel, { VideoItemViewModelList } from '../viewmodel/VideoListViewModel';
import { VideoBoxView } from './VideoBoxView';

const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Component
export struct VideoListView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @State videoListVM: VideoListViewModel = new VideoListViewModel(this.getUIContext().getHostContext() as Context);
  private importDialogId: number = 0;
  private importOptions: ImportOption[] = [
    { icon: $r('app.media.picture_2'), text: '系统图库导入', color: Color.Blue },
    { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
    { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
    { icon: $r('app.media.folder_badge_plus'), text: '创建文件夹', color: Color.Green },
    { icon: $r('app.media.question_circle'), text: '导入疑问', color: Color.Gray },
  ];

  async aboutToAppear(): Promise<void> {
    this.videoListVM.init();
  }

  @Builder
  headBar() {
    Row() {
      Text('视频')
        .fontSize(24)
        .fontColor(Color.Black);
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center);
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
          this.importOptionBuilder(this.importOptions[0]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.videoListVM.importVideoFromMediaLib();
        });

        ListItem() {
          this.importOptionBuilder(this.importOptions[1]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.videoListVM.importVideoFromFileMgr();
        });

        ListItem() {
          this.importOptionBuilder(this.importOptions[2]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.videoListVM.importVideoFromDownloadDir();
        });

        ListItem() {
          this.importOptionBuilder(this.importOptions[3]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.videoListVM.createVideoDir();
        });

        ListItem() {
          this.importOptionBuilder(this.importOptions[4]);
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
      .height('50%')
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
      this.headBar();

      Stack({ alignContent: Alignment.BottomEnd }) {
        ListView({ videoList: this.videoListVM.videoList });

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.plus'))
            .width(36)
            .aspectRatio(1)
            .fillColor(Color.White);
        }
        .padding(5)
        .margin({ right: 32, bottom: 32 })
        .backgroundColor(Color.Green)
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
              console.error(`Failed to openCustomDialog. Cuase: ${JSON.stringify(err)}`);
            });
        });
      };
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });
  }
}

@Component
struct ListView {
  @ObjectLink videoList: VideoItemViewModelList;

  build() {
    List() {
      ForEach(
        this.videoList,
        (item: VideoItemViewModel) => {
          ListItem() {
            VideoBoxView({ videoItem: item });
          }
          .padding({ left: 8, right: 8 });
        },
        (item: VideoItemViewModel, index: number) => {
          return item.videoName + `_${index}`;
        }
      );
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .contentStartOffset(8)
    .contentEndOffset(8)
    .divider({ strokeWidth: 8, color: 'rgb(243, 243, 243)' })
    .backgroundColor(`rgb(243, 243, 243)`);
  }
}