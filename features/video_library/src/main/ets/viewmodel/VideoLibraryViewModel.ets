import { Context } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import picker from '@ohos.file.picker';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { util } from '@kit.ArkTS';
import image from '@ohos.multimedia.image';
import { VideoLibraryStore } from 'data_storage/src/main/ets/rdbms/VideoLibraryStore';
import { SettingKey, Settings, SortModeValue, SortRuleValue, VideoInfoModel, ViewOptionValue } from 'data_storage';
import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { emitter } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

const BUFFER_SIZE = 4096;
const MD_ALGO_NAME = 'SHA256';
const THUMBNAIL_DIR = '/thumbnails';
const DOWNLOAD_VIDEO_DIR = '/videos';
const SORT_VIDEO_FOLDER_EVENT = 'SortVideoFolder';
const IMPORT_VIDEO_EVENT = 'ImportVideo';
const CREATE_FOLDER_EVENT = 'CreateFolder';

@Observed
export class VideoLibraryViewModel {
  @Track sortMode: preferences.ValueType = SortModeValue.DATE_ADD;
  @Track sortRule: preferences.ValueType = SortRuleValue.ASCENDING;
  private videoStore: VideoLibraryStore = new VideoLibraryStore();
  private settings: Settings = new Settings();
  private downloadPath: string = '';
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  private async createThumbSandboxDir(thumbnailDir: string) {
    try {
      if (!fileIo.accessSync(thumbnailDir)) {
        await fileIo.mkdir(thumbnailDir);
      }
    } catch (error) {
      console.error(`Failed to create thumbnail directory. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
    }
  }

  private async fileSHA256(path: string): Promise<Uint8Array> {
    let file: fileIo.File | undefined = undefined;
    try {
      file = await fileIo.open(path, fileIo.OpenMode.READ_ONLY);

      const buffer = new ArrayBuffer(BUFFER_SIZE);
      const md = cryptoFramework.createMd(MD_ALGO_NAME);
      while (await fileIo.read(file.fd, buffer) > 0) {
        const bufferBlob: cryptoFramework.DataBlob = { data: new Uint8Array(buffer) };
        await md.update(bufferBlob);
      }
      const output = await md.digest();
      return output.data;
    } catch (error) {
      console.error(`Failed to calculate sha256 from file ${path}. Cause: ${JSON.stringify(error)}`);
      throw Error(error)
    } finally {
      if (file !== undefined) {
        await fileIo.close(file.fd);
      }
    }
  }

  private async isDuplicateFile(srcPath: string, dstPath: string): Promise<boolean> {
    try {
      const srcHashVal = await this.fileSHA256(srcPath);
      const dstHashVal = await this.fileSHA256(dstPath);
      if (srcHashVal.length === dstHashVal.length) {
        for (let i = 0; i < srcHashVal.length; ++i) {
          if (srcHashVal[i] !== dstHashVal[i]) {
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (error) {
      throw Error(error);
    }
  }

  private renameDuplicateFile(path: string): string {
    try {
      let count = 0;
      let newPath = path;
      const lastSlashIdx = path.lastIndexOf('/');
      if (lastSlashIdx === -1 || lastSlashIdx === path.length - 1) {
        throw Error(`Invalid file path: ${path}`);
      }
      let newFileName = path.slice(lastSlashIdx + 1);
      while (fileIo.accessSync(newPath, fileIo.AccessModeType.EXIST)) {
        count++;
        let lastDotIdx = newFileName.lastIndexOf('.');
        if (lastDotIdx === -1) {
          newFileName = newFileName + `(${count})`;
        } else {
          newFileName = newFileName.slice(0, lastDotIdx) + `(${count})` + newFileName.slice(lastDotIdx);
        }
        newPath = path.slice(0, lastSlashIdx + 1) + newFileName;
      }
      return newPath;
    } catch (error) {
      console.error(`Failed to rename duplicate file. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
    }
  }

  private async copyVideo2DownloadDir(srcUri: string, downloadVideoPath: string): Promise<string> {
    let srcFile: fileIo.File | undefined;
    let dstFile: fileIo.File | undefined;
    try {
      if (srcUri.includes(downloadVideoPath)) {
        const srcPath = new fileUri.FileUri(srcUri).path;
        return srcPath;
      }

      const dstUri: string = downloadVideoPath + '/' + this.getFileNameFromFileUri(srcUri);
      const srcPath = new fileUri.FileUri(srcUri).path;
      let dstPath = new fileUri.FileUri(dstUri).path;
      if (fileIo.accessSync(dstPath, fileIo.AccessModeType.EXIST)) {
        // Already have video file with same name
        if (await this.isDuplicateFile(srcPath, dstPath)) {
          throw Error(`Video file ${srcUri} repeated imported. File has imported at ${srcFile}`);
        } else {
          dstPath = this.renameDuplicateFile(dstPath);
        }
      }

      srcFile = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      dstFile = await fileIo.open(dstPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      await fileIo.copyFile(srcFile.fd, dstFile.fd);

      return dstPath;
    } catch (error) {
      console.error(`Failed to copy video file ${srcUri} to download directroy. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
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
      throw Error(error);
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
      throw Error(error);
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

  private async insert2DB(folder: string, name: string, videoPath: string, thumbnailPath: string): Promise<number> {
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
      throw Error(error);
    } finally {
      if (avMetadataExtractor) {
        await avMetadataExtractor.release();
      }
      if (videoFile) {
        await fileIo.close(videoFile);
      }
    }
    let info = new VideoInfoModel();
    info.name = name;
    info.folder = folder;
    info.videoPath = videoPath;
    info.thumbnailPath = thumbnailPath;
    info.metadata = JSON.stringify(metadata);
    return await this.videoStore.insertVideoInfo(info);
  }

  private async importVideo(uri: string, folder: string): Promise<void> {
    // Create video and thumbnail directory
    const thumbnailDir = this.context.filesDir + THUMBNAIL_DIR;
    try {
      await this.createThumbSandboxDir(thumbnailDir);
    } catch (error) {
      throw Error(error);
    }
    // Copy video file to sandbox
    let videoPath: string = '';
    try {
      const downloadVideoPath = this.downloadPath + DOWNLOAD_VIDEO_DIR;
      videoPath = await this.copyVideo2DownloadDir(uri, downloadVideoPath);
    } catch (error) {
      throw Error(error);
    }
    // create and save thumbnail to sandbox
    let thumbnailPath: string = thumbnailDir + `/${util.generateRandomUUID()}.jpg`;
    try {
      await this.createSaveThumbnail(videoPath, thumbnailPath);
    } catch (error) {
      throw Error(error);
    }
    // Insert video record to database
    let rowId: number = -1;
    const videoName = this.getFileNameFromFileUri(videoPath);
    try {
      rowId = await this.insert2DB(folder, videoName, videoPath, thumbnailPath);
    } catch (error) {
      throw Error(error);
    }
    // Update Video
    let eventData: emitter.EventData = {
      data: {
        'folder': folder,
        'rowId': rowId
      }
    };
    emitter.emit(IMPORT_VIDEO_EVENT, eventData);
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

  async importVideoFromFileMgr(folder: string): Promise<void> {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.fileSuffixFilters = ['视频|.mp4'];
    const documentViewPicker = new picker.DocumentViewPicker();
    documentViewPicker.select(documentSelectOptions)
      .then(async (selectedUri: string[]) => {
        for (let i = 0; i < selectedUri.length; ++i) {
          await this.importVideo(selectedUri[i], folder);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Faild to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importVideoFromMediaLib(folder: string): Promise<void> {
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    photoSelectOptions.isPhotoTakingSupported = false;
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoViewPicker.select(photoSelectOptions)
      .then(async (result: photoAccessHelper.PhotoSelectResult) => {
        let selectedUri = result.photoUris;
        for (let i = 0; i < selectedUri.length; ++i) {
          await this.importVideo(selectedUri[i], folder);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke PhotoViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importVideoFromDownloadDir(folder: string): Promise<void> {
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
            await this.importVideo(path, folder);
          }
        }
      };
      await traverseDir(downloadVideoPath);
    } catch (error) {
      console.error(`Failed to import video from download directory`);
    }
  }

  async createVideoFolder(folder: string, parent: string): Promise<void> {
    // Insert data to database
    let folderInfo = new FolderInfoModel();
    folderInfo.path = folder;
    folderInfo.parent = parent;
    let rowId: number = -1;
    try {
      rowId = await this.videoStore.insertFolderInfo(folderInfo);
    } catch (error) {
      throw Error(error);
    }
    // Update folder
    let eventData: emitter.EventData = {
      data: {
        'folder': parent,
        'rowId': rowId
      }
    };
    emitter.emit(CREATE_FOLDER_EVENT, eventData);
  }

  async selectSortMethod(selectSortMode: SortModeValue): Promise<void> {
    if (this.sortMode !== selectSortMode) {
      await this.settings.putSetting(SettingKey.VIDEO_SORT_MODE, selectSortMode);
    } else {
      const rule = (this.sortRule === SortRuleValue.ASCENDING ? SortRuleValue.DESCENDING : SortRuleValue.ASCENDING);
      await this.settings.putSetting(SettingKey.VIDEO_SORT_RULE, rule);
    }
    this.sortMode = await this.settings.getSetting(SettingKey.VIDEO_SORT_MODE);
    this.sortRule = await this.settings.getSetting(SettingKey.VIDEO_SORT_RULE);
    emitter.emit(SORT_VIDEO_FOLDER_EVENT);
  }

  async selectViewOption(viewOption: ViewOptionValue) {
    await this.settings.putSetting(SettingKey.VIDEO_VIEW_OPTION, viewOption);
  }

  async getViewOptions(): Promise<ViewOptionValue> {
    return await this.settings.getSetting(SettingKey.VIDEO_VIEW_OPTION) as ViewOptionValue;
  }

  async init(): Promise<void> {
    await this.videoStore.initStore(this.context);
    await this.createVideoDownloadDir();

    await this.settings.initPreference(this.context);
    this.sortMode = await this.settings.getSetting(SettingKey.VIDEO_SORT_MODE);
    this.sortRule = await this.settings.getSetting(SettingKey.VIDEO_SORT_RULE);
  }

  private getFileNameFromFileUri(uri: string): string {
    const lastSlashIdx = uri.lastIndexOf('/');
    if (lastSlashIdx === -1 || lastSlashIdx === uri.length - 1) {
      throw Error(`Invalid uri: ${uri}`);
    }
    const fileName = decodeURIComponent(uri.slice(lastSlashIdx + 1));
    return fileName;
  }
}