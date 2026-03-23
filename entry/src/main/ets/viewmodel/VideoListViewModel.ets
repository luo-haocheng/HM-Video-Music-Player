import { VideoItemViewModel } from './VideoItemViewModel';
import { common, Context } from '@kit.AbilityKit';
import { VideoLibraryStore } from '../model/VideoLibraryStore';
import { FolderItemViewModel } from './FolderItemViewModel';
import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoInfoModel } from '../model/VideoInfoModel';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { emitter } from '@kit.BasicServicesKit';

const ROOT_FOLDER = '/';
const MOVE_VIDEO_EVENT = 'MoveVideo';
const MOVE_FOLDER_EVENT = 'FolderVideo';

@Observed
export class VideoItemViewModelList extends Array<VideoItemViewModel> {
}

@Observed
export class FolderItemViewModelList extends Array<FolderItemViewModel> {
}

@Observed
export class VideoListViewModel {
  @Track videoList: VideoItemViewModelList = new VideoItemViewModelList();
  @Track folderList: FolderItemViewModelList = new FolderItemViewModelList();
  public folder: string = ROOT_FOLDER;
  public parent: string = ROOT_FOLDER;
  private videoStore: VideoLibraryStore = new VideoLibraryStore();

  async updateVideoList(rowId: number): Promise<void> {
    try {
      let info = await this.videoStore.selectVideoById(rowId);
      let videoItem = new VideoItemViewModel();
      videoItem.updateVideoItem(info);
      this.videoList.push(videoItem);
    } catch (error) {
      throw new Error(error);
    }
  }

  async updateFolderList(rowId: number): Promise<void> {
    try {
      let info = await this.videoStore.selectFolderById(rowId);
      let folderItem = new FolderItemViewModel();
      folderItem.updateFolderItem(info);
      this.folderList.push(folderItem);
    } catch (error) {
      throw new Error(error);
    }
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

  async shareVideos(shareVideos: VideoInfoModel[], context: common.UIAbilityContext): Promise<void> {
    if (shareVideos.length <= 0) {
      return;
    }

    let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
    let shareData: systemShare.SharedData | undefined = undefined;
    shareData = new systemShare.SharedData({
      utd: utdTypeId,
      title: shareVideos[0].name,
      uri: fileUri.getUriFromPath(shareVideos[0].videoPath),
      thumbnailUri: fileUri.getUriFromPath(shareVideos[0].thumbnailPath),
    });
    for (let i = 1; i < shareVideos.length; ++i) {
      try {
        shareData.addRecord({
          utd: utdTypeId,
          title: shareVideos[i].name,
          uri: fileUri.getUriFromPath(shareVideos[i].videoPath),
          thumbnailUri: fileUri.getUriFromPath(shareVideos[i].thumbnailPath),
        });
      } catch (error) {
        console.error(`Failed to invoke ShareData.addRecord. Cause: ${JSON.stringify(error)}`);
      }
    }
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let selectionMode = shareVideos.length === 1 ? systemShare.SelectionMode.SINGLE : systemShare.SelectionMode.BATCH;
    await controller.show(context, ({
      selectionMode: selectionMode,
      previewMode: systemShare.SharePreviewMode.DETAIL,
    }))
      .then(() => {
        console.info(`ShareController show success.`);
      })
      .catch((err: BusinessError<void>) => {
        console.error(`ShareController show error. Cause: ${JSON.stringify(err)}`);
      });
  }

  async renameVideo(newName: string, videoInfo: VideoInfoModel): Promise<void> {
    // Rename in database
    await this.videoStore.renameVideo(videoInfo, newName);
    // Rename in list
    let idx = this.videoList.findIndex((item: VideoItemViewModel) => {
      return item.videoInfo.id === videoInfo.id;
    });
    if (idx !== -1) {
      this.videoList[idx].videoName = newName;
    }
  }

  async renameFolder(newName: string, folderInfo: FolderInfoModel): Promise<void> {
    // traverse folder
    let updateVideoList: VideoInfoModel[] = [];
    let updateFolderList: FolderInfoModel[] = [];
    let traverseFolder = async (info: FolderInfoModel, newPath: string) => {
      let folders = await this.videoStore.selectFolderByFolder(info.path);
      let videos = await this.videoStore.selectVideoByFolder(info.path);
      info.path = newPath;
      updateFolderList.push(info);
      for (let i = 0; i < videos.length; ++i) {
        videos[i].folder = newPath;
      }
      updateVideoList.push(...videos);
      for (let i = 0; i < folders.length; ++i) {
        folders[i].parent = newPath;
        let prevSlashIdx = folders[i].path.lastIndexOf('/', folders[i].path.length - 2);
        let folderName = folders[i].path.slice(prevSlashIdx + 1, folders[i].path.length - 1);
        let folderPath = newPath + `${folderName}/`;
        await traverseFolder(folders[i], folderPath);
      }
    };
    let newPath = folderInfo.parent + `${newName}/`;
    await traverseFolder(folderInfo, newPath);
    await this.videoStore.renameFolder(updateVideoList, updateFolderList);
    // update list
    let idx = this.folderList.findIndex((item: FolderItemViewModel) => {
      return item.folderInfo.id === folderInfo.id;
    });
    if (idx !== -1) {
      this.folderList[idx].folderName = newName;
    }
  }

  async deleteChoiceItem(): Promise<void> {
    // Delete choice videos
    let choiceVideos: VideoInfoModel[] = [];
    this.videoList.forEach((item: VideoItemViewModel) => {
      if (item.isChoice) {
        choiceVideos.push(item.videoInfo);
      }
    });
    // Delete choice folders
    let choiceFolders: FolderInfoModel[] = [];
    this.folderList.forEach((item: FolderItemViewModel) => {
      if (item.isChoice) {
        choiceFolders.push(item.folderInfo);
      }
    });
    for (let i = 0; i < choiceVideos.length; ++i) {
      await this.deleteVideo(choiceVideos[i]);
    }
    for (let i = 0; i < choiceFolders.length; ++i) {
      await this.deleteFolder(choiceFolders[i]);
    }
  }

  async deleteFolder(folderInfo: FolderInfoModel): Promise<void> {
    // traverse folder
    let delVideoList: VideoInfoModel[] = [];
    let delFolderList: FolderInfoModel[] = [];
    let traverseFolder = async (info: FolderInfoModel) => {
      delFolderList.push(info);
      let delFolders = await this.videoStore.selectFolderByFolder(info.path);
      let delVideos = await this.videoStore.selectVideoByFolder(info.path);
      delVideoList.push(...delVideos);
      for (let i = 0; i < delFolders.length; ++i) {
        await traverseFolder(delFolders[i]);
      }
    };
    await traverseFolder(folderInfo);
    // delete from database
    await this.videoStore.deleteFolderAndVideo(delFolderList, delVideoList);
    // Delete video file and thumbnail file in sandbox
    for (let i = 0; i < delVideoList.length; ++i) {
      try {
        await fileIo.unlink(delVideoList[i].videoPath);
      } catch (error) {
        console.error(`Failed to unlink video file: ${delVideoList[i].videoPath}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
      try {
        await fileIo.unlink(delVideoList[i].thumbnailPath);
      } catch (error) {
        console.error(`Failed to unlink thumbnail file: ${delVideoList[i].thumbnailPath}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    // delete from list
    let idx = this.folderList.findIndex((item: FolderItemViewModel) => {
      return item.folderInfo.id === folderInfo.id;
    });
    if (idx !== -1) {
      this.folderList.splice(idx, 1);
    }
  }

  async deleteVideo(videoInfo: VideoInfoModel): Promise<void> {
    // Delete the video record from database
    await this.videoStore.deleteVideoById(videoInfo.id);
    // Delete video file and thumbnail file in sandbox
    try {
      await fileIo.unlink(videoInfo.videoPath);
    } catch (error) {
      console.error(`Failed to unlink video file: ${videoInfo.videoPath}. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    try {
      await fileIo.unlink(videoInfo.thumbnailPath);
    } catch (error) {
      console.error(`Failed to unlink thumbnail file: $ {videoInfo.thumbnailPath}. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    // Remove the video from list
    let idx = this.videoList.findIndex((item: VideoItemViewModel) => {
      return item.videoInfo.id === videoInfo.id;
    });
    if (idx !== -1) {
      this.videoList.splice(idx, 1);
    }
  }

  async init(folder: string, context: Context): Promise<void> {
    await this.videoStore.initStore(context);
    await this.loadVideoFolderList(folder);
  }

  private async loadVideoFolderList(folder: string): Promise<void> {
    let folderInfoList = await this.videoStore.selectFolderByFolder(folder);
    for (const info of folderInfoList) {
      let folderItem = new FolderItemViewModel();
      folderItem.updateFolderItem(info);
      this.folderList.push(folderItem);
    }
    let videoInfoList = await this.videoStore.selectVideoByFolder(folder);
    for (const info of videoInfoList) {
      let videoItem = new VideoItemViewModel();
      videoItem.updateVideoItem(info);
      this.videoList.push(videoItem);
    }
  }
}