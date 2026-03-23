import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoInfoModel } from '../model/VideoInfoModel';
import { VideoLibraryStore } from '../model/VideoLibraryStore';
import { FolderItemViewModel } from './FolderItemViewModel';
import { FolderItemViewModelList } from './VideoListViewModel';
import { emitter } from '@kit.BasicServicesKit';

const ROOT_PATH = '/';
const MOVE_VIDEO_EVENT = 'MoveVideo';
const MOVE_FOLDER_EVENT = 'FolderVideo';

@Observed
export class FolderBrowserViewModel {
  public origFolder: string = ROOT_PATH;
  public moveFolderList: FolderInfoModel[] = [];
  private videoStore: VideoLibraryStore = new VideoLibraryStore();

  async initFolderList(folder: string, context: Context): Promise<FolderItemViewModelList> {
    await this.videoStore.initStore(context);
    let folderInfoList = await this.videoStore.selectFolderByFolder(folder);
    let folderItemList = new FolderItemViewModelList();
    for (const folderInfo of folderInfoList) {
      // Can't move folder to self
      let isMoveFolder = this.moveFolderList.find((moveFolderInfo: FolderInfoModel) => {
        return moveFolderInfo.id === folderInfo.id;
      });
      if (isMoveFolder !== undefined) {
        continue;
      }
      // Other folders
      let folderItem = new FolderItemViewModel();
      folderItem.updateFolderItem(folderInfo);
      folderItemList.push(folderItem);
    }
    return folderItemList;
  }

  async moveVideo(videoInfo: VideoInfoModel, moveFolder: string): Promise<void> {
    // Rename in database
    await this.videoStore.moveVideo(videoInfo, moveFolder);
    // Update View
    let eventData: emitter.EventData = {
      data: {
        'from': videoInfo.folder,
        'to': moveFolder,
        'id': videoInfo.id
      }
    };
    emitter.emit(MOVE_VIDEO_EVENT, eventData);
  }

  async moveFolder(folderInfo: FolderInfoModel, moveFolder: string): Promise<void> {
    // todo
    let origFolder = folderInfo.parent;
    let updateVideoList: VideoInfoModel[] = [];
    let updateFolderList: FolderInfoModel[] = [];
    let traverseFolder = async (info: FolderInfoModel, moveFolder: string) => {
      let folders = await this.videoStore.selectFolderByFolder(info.path);
      let videos = await this.videoStore.selectVideoByFolder(info.path);
      let folderName = this.getFolderName(info.path);
      info.path = moveFolder + `${folderName}/`;
      info.parent = moveFolder;
      updateFolderList.push(info);
      for (let i = 0; i < videos.length; ++i) {
        videos[i].folder = info.path;
      }
      updateVideoList.push(...videos);
      for (let i = 0; i < folders.length; ++i) {
        await traverseFolder(folders[i], info.path);
      }
    };
    await traverseFolder(folderInfo, moveFolder);
    await this.videoStore.moveFolder(updateVideoList, updateFolderList);
    // Update View
    let eventData: emitter.EventData = {
      data: {
        'from': origFolder,
        'to': moveFolder,
        'id': folderInfo.id
      }
    };
    emitter.emit(MOVE_FOLDER_EVENT, eventData);
  }

  private getFolderName(path: string): string {
    let prevSlashIdx = path.lastIndexOf('/', path.length - 2);
    let folderName = path.slice(prevSlashIdx + 1, path.length - 1);
    return folderName;
  }
}
