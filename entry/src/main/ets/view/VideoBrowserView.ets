import { VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoFolderListView } from './VideoFolderListView';

const CREATE_FOLDER_EVENT = 'CreateFolder';
const IMPORT_VIDEO_EVENT = 'ImportVideo';
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

