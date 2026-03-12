import { VideoItemViewModel } from './VideoItemViewModel';
import { Context } from '@kit.AbilityKit';
import { VideoLibraryStore } from '../model/VideoLibraryStore';
import { FolderItemViewModel } from './FolderItemViewModel';

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
  private videoStore: VideoLibraryStore = new VideoLibraryStore();
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

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

  async init(folder: string): Promise<void> {
    await this.videoStore.initStore(this.context);
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