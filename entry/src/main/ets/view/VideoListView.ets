import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModelList, VideoItemViewModelList, VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { FolderBoxView } from './FolderBoxView';
import { VideoBoxView } from './VideoBoxView';
import { emitter } from '@kit.BasicServicesKit';
import { FolderInfoModel } from '../model/FolderInfoModel';

const CREATE_FOLDER_EVENT = 'CreateFolder';
const IMPORT_VIDEO_EVENT = 'ImportVideo';
const CURRENT_FOLDER = 'CurrentFolder';

@Component
export struct VideoListView {
  @State videoListVM: VideoListViewModel = new VideoListViewModel();
  private createFolderCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.videoListVM.folder) {
        this.videoListVM.updateFolderList(rowId);
      }
    }
  };
  private importVideoCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.videoListVM.folder) {
        this.videoListVM.updateVideoList(rowId);
      }
    }
  };

  aboutToAppear(): void {
    emitter.on(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.on(IMPORT_VIDEO_EVENT, this.importVideoCallback);
  }

  aboutToDisappear(): void {
    emitter.off(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.off(IMPORT_VIDEO_EVENT, this.importVideoCallback);
  }

  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center
      }) {
        ListView({
          folderList: this.videoListVM.folderList,
          videoList: this.videoListVM.videoList,
          videoListVM: this.videoListVM,
        });
      }
      .width('100%')
      .height('100%');
    }
    .hideBackButton(true)
    .onReady((navContext: NavDestinationContext) => {
      if (navContext.pathInfo.param !== undefined) {
        let folderInfo = navContext.pathInfo.param as FolderInfoModel;
        this.videoListVM.parent = folderInfo.parent;
        this.videoListVM.folder = folderInfo.path;
        AppStorage.setOrCreate(CURRENT_FOLDER, this.videoListVM.folder);
      }
      let context = this.getUIContext().getHostContext() as Context;
      this.videoListVM.init(this.videoListVM.folder, context);
    })
    .onBackPressed(() => {
      AppStorage.setOrCreate(CURRENT_FOLDER, this.videoListVM.parent);
      return false;
    });
  }
}

@Component
struct ListView {
  @ObjectLink folderList: FolderItemViewModelList;
  @ObjectLink videoList: VideoItemViewModelList;
  @Link videoListVM: VideoListViewModel;

  @Builder
  folderSwipeEnd(index: number) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue);

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange);

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteFolder(this.folderList[index].folderInfo, index);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  @Builder
  videoSwipeEnd(index: number) {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.arrow_right_folder_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Blue);

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.rename'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Orange);

      Button({ type: ButtonType.Circle, stateEffect: false }) {
        Image($r('app.media.trash_fill'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.White);
      }
      .padding(8)
      .backgroundColor(Color.Red)
      .onClick(() => {
        this.videoListVM.deleteVideo(this.videoList[index].videoInfo, index);
      });
    }
    .padding({ left: 8, right: 8 });
  }

  build() {
    List() {
      ForEach(
        this.folderList,
        (item: FolderItemViewModel, index: number) => {
          ListItem() {
            FolderBoxView({ folderItem: item });
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
                this.folderSwipeEnd(index);
              }
            }
          });
        },
        (item: FolderItemViewModel, index: number) => {
          return item.folderName + `_${index}`;
        }
      );

      ForEach(
        this.videoList,
        (item: VideoItemViewModel, index: number) => {
          ListItem() {
            VideoBoxView({ videoItem: item });
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
                this.videoSwipeEnd(index);
              }
            }
          });
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