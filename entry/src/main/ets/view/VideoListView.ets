import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { FolderItemViewModelList, VideoItemViewModelList, VideoListViewModel } from '../viewmodel/VideoListViewModel';
import { FolderBoxView } from './FolderBoxView';
import { VideoBoxView } from './VideoBoxView';
import { emitter } from '@kit.BasicServicesKit';

const CURRENT_FOLDER = 'CurrentFolder';

@Component
export struct VideoListView {
  @State videoListVM: VideoListViewModel = new VideoListViewModel(this.getUIContext().getHostContext() as Context);
  private folder: string = '/';

  aboutToAppear(): void {
    emitter.on('CreateFolder', (event: emitter.EventData) => {
      if (event.data) {
        let folder = event.data['folder'] as string;
        let rowId = event.data['rowId'] as number;
        if (folder === this.folder) {
          this.videoListVM.updateFolderList(rowId);
        }
      }
    });
    emitter.on('ImportVideo', (event: emitter.EventData) => {
      if (event.data) {
        let folder = event.data['folder'] as string;
        let rowId = event.data['rowId'] as number;
        if (folder === this.folder) {
          this.videoListVM.updateVideoList(rowId);
        }
      }
    });
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
        this.folder = navContext.pathInfo.param as string;
        AppStorage.setOrCreate(CURRENT_FOLDER, this.folder);
      }
      this.videoListVM.init(this.folder);
    });
  }
}

@Component
struct ListView {
  @ObjectLink folderList: FolderItemViewModelList;
  @ObjectLink videoList: VideoItemViewModelList;

  build() {
    List() {
      ForEach(
        this.folderList,
        (item: FolderItemViewModel) => {
          ListItem() {
            FolderBoxView({ folderItem: item });
          }
          .padding({ left: 8, right: 8 });
        },
        (item: FolderItemViewModel, index: number) => {
          return item.folderName + `_${index}`;
        }
      );

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