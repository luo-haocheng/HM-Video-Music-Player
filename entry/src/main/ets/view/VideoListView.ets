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
  @State videoListVM: VideoListViewModel = new VideoListViewModel(this.getUIContext().getHostContext() as Context);
  private folder: string = '/';
  private parent: string = '/';
  private createFolderCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.folder) {
        this.videoListVM.updateFolderList(rowId);
      }
    }
  };
  private importVideoCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let folder = event.data['folder'] as string;
      let rowId = event.data['rowId'] as number;
      if (folder === this.folder) {
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
        ListView({ folderList: this.videoListVM.folderList, videoList: this.videoListVM.videoList });
      }
      .width('100%')
      .height('100%');
    }
    .hideBackButton(true)
    .onReady((navContext: NavDestinationContext) => {
      if (navContext.pathInfo.param !== undefined) {
        let folderInfo = navContext.pathInfo.param as FolderInfoModel;
        this.parent = folderInfo.parent;
        this.folder = folderInfo.path;
        AppStorage.setOrCreate(CURRENT_FOLDER, this.folder);
      }
      console.info(`Video List Ready: ${this.folder}`);
      this.videoListVM.init(this.folder);
    })
    .onBackPressed(() => {
      console.info(`Video List Back: ${this.parent}`);
      AppStorage.setOrCreate(CURRENT_FOLDER, this.parent);
      return false;
    });
  }
}

@Component
struct ListView {
  @ObjectLink folderList: FolderItemViewModelList;
  @ObjectLink videoList: VideoItemViewModelList;

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
      .backgroundColor(Color.Red);
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
      .backgroundColor(Color.Red);
    }
    .padding({ left: 8, right: 8 });
  }

  @Builder
  videoLongPressDialog(index: number) {
    VideoBoxView({ videoItem: this.videoList[index] });
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
                    this.videoLongPressDialog(index);
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