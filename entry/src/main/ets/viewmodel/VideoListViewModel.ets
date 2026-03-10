import VideoItemViewModel from './VideoItemViewModel';
import { Context } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import picker from '@ohos.file.picker';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { util } from '@kit.ArkTS';
import image from '@ohos.multimedia.image';
import VideoLibraryStore from '../model/VideoLibraryStore';

const VIDEO_DIR = '/videos';
const THUMBNAIL_DIR = '/thumbnails';
const DOWNLOAD_VIDEO_DIR = '/Videos';

@Observed
export class VideoItemViewModelList extends Array<VideoItemViewModel> {
}

@Observed
export default class VideoListViewModel {
  @Track videoList: VideoItemViewModelList = new VideoItemViewModelList();
  private videoStore: VideoLibraryStore = new VideoLibraryStore();
  private downloadPath: string = '';
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  private async createVidThumbDir(videoDir: string, thumbnailDir: string) {
    try {
      if (!fileIo.accessSync(videoDir)) {
        await fileIo.mkdir(videoDir);
      }
    } catch (error) {
      console.error(`Failed to create video directory. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    try {
      if (!fileIo.accessSync(thumbnailDir)) {
        await fileIo.mkdir(thumbnailDir);
      }
    } catch (error) {
      console.error(`Failed to create thumbnail directory. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
  }

  private async copyVideo2Sandbox(srcPath: string, dstPath: string): Promise<void> {
    let srcFile: fileIo.File | undefined;
    let dstFile: fileIo.File | undefined;
    try {
      srcFile = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      dstFile = await fileIo.open(dstPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      await fileIo.copyFile(srcFile.fd, dstFile.fd);
    } catch (error) {
      console.error(`Failed to copy video file ${srcPath} to ${dstPath}. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    } finally {
      if (srcFile) {
        await fileIo.close(srcFile.fd);
      }
      if (dstFile) {
        await fileIo.close(dstFile.fd);
      }
    }
  }

  private async createSaveThumbnail(videoPath: string, thumbnailPath: string): Promise<void> {
    let avImageGenerator: media.AVImageGenerator | undefined;
    let previewImg: image.PixelMap | undefined;
    let videoFile: fileIo.File | undefined;
    try {
      let videoStat = await fileIo.stat(videoPath);
      videoFile = await fileIo.open(videoPath, fileIo.OpenMode.READ_WRITE);
      avImageGenerator = await media.createAVImageGenerator();
      avImageGenerator.fdSrc = { fd: videoFile.fd, offset: 0, length: videoStat.size };

      let timeUs = 0;
      let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC;
      previewImg = await avImageGenerator.fetchFrameByTime(timeUs, queryOption, {});
    } catch (error) {
      console.error(`Failed to create thumbnail. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    } finally {
      if (videoFile) {
        await fileIo.close(videoFile.fd);
      }
      if (avImageGenerator) {
        await avImageGenerator.release();
      }
    }
    let imagePacker: image.ImagePacker | undefined;
    let thumbnailFile: fileIo.File | undefined;
    try {
      thumbnailFile = await fileIo.open(thumbnailPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      imagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };
      await imagePacker.packToFile(previewImg, thumbnailFile.fd, packOpts);
    } catch (error) {
      console.error(`Failed to save thumbnail. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    } finally {
      if (previewImg) {
        await previewImg.release();
      }
      if (imagePacker) {
        await imagePacker.release();
      }
      if (thumbnailFile) {
        await fileIo.close(thumbnailFile);
      }
    }
  }

  private async insert2DB(videoName: string, videoPath: string, thumbnailPath: string): Promise<number> {
    let videoFile: fileIo.File | undefined;
    let metadata: media.AVMetadata | undefined;
    let avMetadataExtractor: media.AVMetadataExtractor | undefined;
    try {
      let videoStat = await fileIo.stat(videoPath);
      videoFile = await fileIo.open(videoPath, fileIo.OpenMode.READ_WRITE);
      avMetadataExtractor = await media.createAVMetadataExtractor();
      avMetadataExtractor.fdSrc = { fd: videoFile.fd, offset: 0, length: videoStat.size };

      metadata = await avMetadataExtractor.fetchMetadata();
    } catch (error) {
      console.error(`Failed to fetch metadata, error: ${JSON.stringify(error)}`);
      throw new Error(error);
    } finally {
      if (avMetadataExtractor) {
        await avMetadataExtractor.release();
      }
      if (videoFile) {
        await fileIo.close(videoFile);
      }
    }
    return await this.videoStore.insertVideoInfo(videoName, JSON.stringify(metadata), videoPath, thumbnailPath);
  }

  private async updateVideoList(rowId: number): Promise<void> {
    try {
      let info = await this.videoStore.selectVideoById(rowId);
      let videoItem = new VideoItemViewModel();
      videoItem.updateVideoItem(info);
      this.videoList.push(videoItem);
      console.info(`Update video list successfully, ${JSON.stringify(info)}`);
    } catch (error) {
      throw new Error(error);
    }
  }

  private async importVideo(uri: string): Promise<void> {
    // Create video and thumbnail directory
    const videoDir = this.context.filesDir + VIDEO_DIR;
    const thumbnailDir = this.context.filesDir + THUMBNAIL_DIR;
    try {
      await this.createVidThumbDir(videoDir, thumbnailDir);
    } catch (error) {
      throw new Error(error);
    }
    // Copy video file to sandbox
    let videoPath: string = videoDir + `/${util.generateRandomUUID()}.mp4`;
    try {
      await this.copyVideo2Sandbox(uri, videoPath);
    } catch (error) {
      throw new Error(error);
    }
    // create and save thumbnail to sandbox
    let thumbnailPath: string = thumbnailDir + `/${util.generateRandomUUID()}.jpg`;
    try {
      await this.createSaveThumbnail(videoPath, thumbnailPath);
    } catch (error) {
      throw new Error(error);
    }
    // Insert video record to database
    let rowId: number = -1;
    let lastSlashIdx = uri.lastIndexOf('/');
    let videoName = uri.slice(lastSlashIdx + 1);
    try {
      rowId = await this.insert2DB(videoName, videoPath, thumbnailPath);
    } catch (error) {
      throw new Error(error);
    }

    try {
      await this.updateVideoList(rowId);
    } catch (error) {
      throw new Error(error);
    }
  }

  private async createVideoDownloadDir(): Promise<void> {
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    const documentViewPicker = new picker.DocumentViewPicker(this.context);
    documentViewPicker.save(documentSaveOptions)
      .then(async (result: string[]) => {
        if (!result || result.length <= 0) {
          console.error(`Failed to invoke DocumentViewPicker.save, result is empty`);
          return;
        }
        console.info(`Download Save Result: ${result}`);
        this.downloadPath = new fileUri.FileUri(result[0]).path;
        const downloadVideoPath = this.downloadPath + DOWNLOAD_VIDEO_DIR;
        try {
          if (!fileIo.accessSync(downloadVideoPath, fileIo.AccessModeType.EXIST)) {
            await fileIo.mkdir(downloadVideoPath);
          }
        } catch (error) {
          console.error(`Failed to make video directory ${downloadVideoPath}. Cause: ${JSON.stringify(error)}`);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke DocumentViewPicker.save. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importVideoFromFileMgr(): Promise<void> {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.fileSuffixFilters = ['视频|.mp4'];
    const documentViewPicker = new picker.DocumentViewPicker();
    documentViewPicker.select(documentSelectOptions)
      .then(async (selectedUri: string[]) => {
        for (let i = 0; i < selectedUri.length; ++i) {
          await this.importVideo(selectedUri[i]);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Faild to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importVideoFromMediaLib(): Promise<void> {
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    photoSelectOptions.isPhotoTakingSupported = false;
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoViewPicker.select(photoSelectOptions)
      .then(async (result: photoAccessHelper.PhotoSelectResult) => {
        let selectedUri = result.photoUris;
        for (let i = 0; i < selectedUri.length; ++i) {
          await this.importVideo(selectedUri[i]);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke PhotoViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importVideoFromDownloadDir(): Promise<void> {
    try {
      const downloadVideoPath = this.downloadPath + DOWNLOAD_VIDEO_DIR;
      let traverseDir = async (dir: string) => {
        let files = await fileIo.listFile(dir);
        for (let i = 0; i < files.length; ++i) {
          let path = dir + `/${files[i]}`;
          let stat = await fileIo.stat(path);
          if (stat.isDirectory()) {
            await traverseDir(path);
          } else {
            await this.importVideo(path);
          }
        }
      };
      await traverseDir(downloadVideoPath);
    } catch (error) {
      console.error(`Failed to import video from download directory`);
    }
  }

  async createVideoDir(): Promise<void> {
    // todo
  }

  async init(): Promise<void> {
    await this.videoStore.initStore(this.context);
    await this.createVideoDownloadDir();
    await this.loadVideoList();
  }

  async loadVideoList(): Promise<void> {
    let videoInfoList = await this.videoStore.selectAllVideoInfo();
    for (const info of videoInfoList) {
      let videoItem = new VideoItemViewModel();
      videoItem.updateVideoItem(info);
      this.videoList.push(videoItem);
    }
  }
}