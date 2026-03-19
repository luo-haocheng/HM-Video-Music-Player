import { VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoFolderListView } from './VideoFolderListView';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';

const CREATE_FOLDER_EVENT = 'CreateFolder';
const IMPORT_VIDEO_EVENT = 'ImportVideo';
const MOVE_FOLDER_EVENT = 'FolderVideo';
const MOVE_VIDEO_EVENT = 'MoveVideo';
const CURRENT_FOLDER = 'CurrentFolder';

@Component
export struct VideoBrowserView {
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
  private moveVideoCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let from = event.data['from'] as string;
      let to = event.data['to'] as string;
      let id = event.data['id'] as number;
      if (this.videoListVM.folder === from) {
        let idx = this.videoListVM.videoList.findIndex((item: VideoItemViewModel) => {
          return item.videoInfo.id === id;
        });
        if (idx !== -1) {
          this.videoListVM.videoList.splice(idx, 1);
        }
      }
      if (this.videoListVM.folder === to) {
        this.videoListVM.updateVideoList(id);
      }
    }
  };
  private moveFolderCallback: Callback<emitter.EventData> = (event: emitter.EventData) => {
    if (event.data) {
      let from = event.data['from'] as string;
      let to = event.data['to'] as string;
      let id = event.data['id'] as number;
      if (this.videoListVM.folder === from) {
        let idx = this.videoListVM.folderList.findIndex((item: FolderItemViewModel) => {
          return item.folderInfo.id === id;
        });
        if (idx !== -1) {
          this.videoListVM.folderList.splice(idx, 1);
        }
      }
      if (this.videoListVM.folder === to) {
        this.videoListVM.updateFolderList(id);
      }
    }
  };

  aboutToAppear(): void {
    emitter.on(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.on(IMPORT_VIDEO_EVENT, this.importVideoCallback);
    emitter.on(MOVE_FOLDER_EVENT, this.moveFolderCallback);
    emitter.on(MOVE_VIDEO_EVENT, this.moveVideoCallback);
  }

  aboutToDisappear(): void {
    emitter.off(CREATE_FOLDER_EVENT, this.createFolderCallback);
    emitter.off(IMPORT_VIDEO_EVENT, this.importVideoCallback);
    emitter.off(MOVE_FOLDER_EVENT, this.moveFolderCallback);
    emitter.off(MOVE_VIDEO_EVENT, this.moveVideoCallback);
  }

  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center
      }) {
        VideoFolderListView({
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

