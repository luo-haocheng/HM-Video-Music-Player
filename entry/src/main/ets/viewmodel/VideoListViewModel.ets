import { VideoItemViewModel } from './VideoItemViewModel';
import { Context } from '@kit.AbilityKit';
import { VideoLibraryStore } from '../model/VideoLibraryStore';
import { FolderItemViewModel } from './FolderItemViewModel';
import { FolderInfoModel } from '../model/FolderInfoModel';
import { VideoInfoModel } from '../model/VideoInfoModel';
import { fileIo } from '@kit.CoreFileKit';

@Observed
export class VideoItemViewModelList extends Array<VideoItemViewModel> {
}

@Observed
export class FolderItemViewModelList extends Array<FolderItemViewModel> {
}

@Observed
export class VideoListViewModel {
  @Track folderList: FolderItemViewModelList = new FolderItemViewModelList();
  @Track videoList: VideoItemViewModelList = new VideoItemViewModelList();
  public folder: string = '/';
  public parent: string = '/';
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

  async deleteFolder(folderInfo: FolderInfoModel, index: number): Promise<void> {
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
    this.folderList.splice(index, 1);
  }

  async deleteVideo(videoInfo: VideoInfoModel, index: number): Promise<void> {
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
      console.error(`Failed to unlink thumbnail file: ${videoInfo.thumbnailPath}. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    // Remove the video from list
    this.videoList.splice(index, 1);
  }

  async init(folder: string, context: Context): Promise<void> {
    await this.videoStore.initStore(context);
    await this.loadVideoList(folder);
  }

  async loadVideoList(folder: string): Promise<void> {
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