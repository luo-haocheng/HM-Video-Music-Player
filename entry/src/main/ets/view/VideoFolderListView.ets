import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoInfoModel } from '../model/VideoInfoModel';
import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModelList, VideoItemViewModelList, VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { FolderBoxView } from './FolderBoxView';
import { MovingToDialog } from './MovingToDialog';
import { VideoBoxView } from './VideoBoxView';
import { common } from '@kit.AbilityKit';

const CHOICE_ALL = 'ChoiceAll';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct VideoFolderListView {
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(CHOICE_ALL) choiceAll: boolean = false;
  @ObjectLink folderList: FolderItemViewModelList;
  @ObjectLink videoList: VideoItemViewModelList;
  @Link videoListVM: VideoListViewModel;
  private moveDialogController?: CustomDialogController;
  private scroller: ListScroller = new ListScroller();
  private renameDialogId: number = 0;
  private newName?: string = '';
  private isAllChoice: Callback<void> = () => {
    const folderAllChoice = this.folderList.find((item: FolderItemViewModel) => {
      return !item.isChoice;
    });
    const videoAllChoice = this.videoList.find((item: VideoItemViewModel) => {
      return !item.isChoice;
    });
    this.choiceAll = (folderAllChoice !== undefined) || (videoAllChoice !== undefined);
  };

  @Builder
  renameDialogBuilder(info: VideoInfoModel | FolderInfoModel, type: 'folder' | 'video') {
    Column() {
      Row() {
        Text('重命名')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '重命名' })
        .id('renameTextInput')
        .fontSize(14)
        .showUnderline(true)
        .underlineColor(Color.Gray)
        .placeholderFont({ size: 14 })
        .backgroundColor(Color.Transparent)
        .onAppear(() => {
          try {
            this.getUIContext().getFocusController().requestFocus('renameTextInput');
          } catch (error) {
            console.error(`Failed to request focus for renameTextInput. Cause: ${JSON.stringify(error)}`);
          }
        })
        .onChange((value: string) => {
          this.newName = value;
        });

      Row() {
        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('取消')
            .fontSize(14)
            .fontColor('#FF4876FF');
        }
        .padding(8)
        .width('45%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.renameDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });

        Divider()
          .height(24)
          .vertical(true)
          .strokeWidth(1)
          .color('#DCDCDC');

        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('确认')
            .fontSize(14)
            .fontColor('#FF4876FF');
        }
        .padding(8)
        .width('45%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.renameDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          if (this.newName !== undefined) {
            if (type === 'video') {
              this.videoListVM.renameVideo(this.newName, info as VideoInfoModel);
            } else {
              this.videoListVM.renameFolder(this.newName, info as FolderInfoModel);
            }
          }
        });
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(16);
  }

  @Builder
  folderSwipeEnd(info: FolderInfoModel) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          builder: MovingToDialog({ origFolder: this.videoListVM.folder, moveFolderList: [info] }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();

        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange)
      .onClick(() => {
        this.getUIContext()
          .getPromptAction()
          .openCustomDialog({
            builder: () => {
              this.renameDialogBuilder(info, 'folder');
            },
            width: '90%',
            autoCancel: false,
            alignment: DialogAlignment.Center,
            transition: TransitionEffect.SLIDE,
            onWillAppear: () => {
              this.newName = undefined;
            }
          })
          .then((dialogId: number) => {
            this.renameDialogId = dialogId;
          })
          .catch((err: BusinessError) => {
            console.error(`Failed to open create folder dialog. Cuase: ${JSON.stringify(err)}`);
          });

        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteFolder(info);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  @Builder
  videoSwipeEnd(info: VideoInfoModel) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.share'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Green)
      .onClick(() => {
        let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.videoListVM.shareVideos([info], context);
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue)
      .onClick(() => {
        this.moveDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          builder: MovingToDialog({ origFolder: this.videoListVM.folder, moveVideoList: [info] }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
        });
        this.moveDialogController.open();
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange)
      .onClick(() => {
        this.getUIContext()
          .getPromptAction()
          .openCustomDialog({
            builder: () => {
              this.renameDialogBuilder(info, 'video');
            },
            width: '90%',
            autoCancel: false,
            alignment: DialogAlignment.Center,
            transition: TransitionEffect.SLIDE,
            onWillAppear: () => {
              this.newName = undefined;
            }
          })
          .then((dialogId: number) => {
            this.renameDialogId = dialogId;
          })
          .catch((err: BusinessError) => {
            console.error(`Failed to open create folder dialog. Cuase: ${JSON.stringify(err)}`);
          });
        // Close swipe action
        try {
          this.scroller.closeAllSwipeActions();
        } catch (error) {
          console.error(`Failed to invoke ListScroller.closeAllSwipeActions. Cause: ${JSON.stringify(error)}`);
        }
      });

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteVideo(info);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  build() {
    List({ scroller: this.scroller }) {
      ForEach(
        this.folderList,
        (item: FolderItemViewModel) => {
          ListItem() {
            FolderBoxView({
              folderItem: item, isAllChoice: () => {
                this.isAllChoice();
              }
            });
          }
          .padding({ left: 8, right: 8 })
          .gesture(
            LongPressGesture({ repeat: false })
              .onAction(() => {
                console.info(`Folder Item Long Press`);
              })
          )
          .swipeAction({
            end: {
              builder: () => {
                this.folderSwipeEnd(item.folderInfo);
              }
            }
          });
        },
        (item: FolderItemViewModel, index: number) => {
          index;
          return item.folderInfo.id.toString();
        }
      );

      ForEach(
        this.videoList,
        (item: VideoItemViewModel) => {
          ListItem() {
            VideoBoxView({
              videoItem: item, isAllChoice: () => {
                this.isAllChoice();
              }
            });
          }
          .padding({ left: 8, right: 8 })
          .gesture(
            LongPressGesture({ repeat: false })
              .onAction(() => {
                this.getUIContext().getPromptAction().openCustomDialog({
                  builder: () => {
                    console.info(`Video Item Long Press`);
                  }
                })
                  .catch((err: BusinessError) => {
                    console.error(`Failed to open video long press dialog. Cause: ${JSON.stringify(err)}`);
                  });
              })
          )
          .swipeAction({
            end: {
              builder: () => {
                this.videoSwipeEnd(item.videoInfo);
              }
            }
          });
        },
        (item: VideoItemViewModel, index: number) => {
          index;
          return item.videoInfo.id.toString();
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