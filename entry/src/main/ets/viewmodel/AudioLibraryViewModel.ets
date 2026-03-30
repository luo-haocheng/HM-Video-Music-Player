import { AudioLibraryStore } from '../model/AudioLibraryStore';
import picker from '@ohos.file.picker';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioItemViewModel } from './AudioItemViewModel';

const AUDIO_DIR = '/audios';
const COVER_DIR = '/covers';
const DOWNLOAD_AUDIO_DIR = '/Audios';


@Observed
export class AudioLibraryViewModel {
  private audioStore: AudioLibraryStore = new AudioLibraryStore();
  private downloadPath: string = '';

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    await this.createAudioDownloadDir(context);
  }

  async loadAllAudio(): Promise<AudioItemViewModel[]> {
    const audioInfoList: AudioInfoModel[] = await this.audioStore.selectAllAudio();
    const audioItemList: AudioItemViewModel[] = [];
    for (let i = 0; i < audioInfoList.length; ++i) {
      let audioItem = new AudioItemViewModel();
      audioItem.updateAudioItem(audioInfoList[i]);
      audioItemList.push(audioItem);
    }
    return audioItemList;
  }

  async importAudioFromAudioLib(context: Context): Promise<void> {
    const audioViewPicker = new picker.AudioViewPicker(context);
    audioViewPicker.select()
      .then(async (selectedUris: Array<string>) => {
        for (let i = 0; i < selectedUris.length; ++i) {
          await this.importAudio(selectedUris[i], context);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke AudioViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importAudioFromFileMgr(context: Context): Promise<void> {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.fileSuffixFilters = ['音频(.mp3, .m4a)|.mp3,.m4a'];
    const documentViewPicker = new picker.DocumentViewPicker();
    documentViewPicker.select(documentSelectOptions)
      .then(async (selectedUris: Array<string>) => {
        for (let i = 0; i < selectedUris.length; ++i) {
          await this.importAudio(selectedUris[i], context);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importAudioFromDownloadDir(context: Context): Promise<void> {
    try {
      const downloadVideoPath = this.downloadPath + DOWNLOAD_AUDIO_DIR;
      let traverseDir = async (dir: string) => {
        let files = await fileIo.listFile(dir);
        for (let i = 0; i < files.length; ++i) {
          let path = dir + `/${files[i]}`;
          let stat = await fileIo.stat(path);
          if (stat.isDirectory()) {
            await traverseDir(path);
          } else {
            await this.importAudio(path, context);
          }
        }
      };
      await traverseDir(downloadVideoPath);
    } catch (error) {
      console.error(`Failed to import video from download directory`);
    }
  }

  private async importAudio(uri: string, context: Context): Promise<void> {
    // Create audio and cover sandbox directory if not exist
    const audioDir = context.filesDir + AUDIO_DIR;
    const coverDir = context.filesDir + COVER_DIR;
    try {
      await this.createAudioCoverDir(audioDir, coverDir);
    } catch (error) {
      throw new Error(error);
    }
    // Copy audio file to sandbox
    let audioPath: string = audioDir + `/${util.generateRandomUUID()}.mp4`;
    try {
      await this.copyAudio2Sandbox(uri, audioPath);
    } catch (error) {
      throw new Error(error);
    }
    // Fetch and save album cover to sandbox
    let coverPath: string | null = coverDir + `/${util.generateRandomUUID()}.jpg`;
    try {
      coverPath = await this.fetchSaveAlbumCover(audioPath, coverPath);
    } catch (error) {
      throw new Error(error);
    }
    // Insert audio record to database
    const lastSlashIdx = uri.lastIndexOf('/');
    const audioName = decodeURIComponent(uri.slice(lastSlashIdx + 1));
    try {
      await this.insertAudio2DB(audioName, audioPath, coverPath);
    } catch (error) {
      throw new Error(error);
    }
  }

  private async createAudioCoverDir(audioDir: string, coverDir: string) {
    try {
      if (!fileIo.accessSync(audioDir)) {
        await fileIo.mkdir(audioDir);
      }
    } catch (error) {
      console.error(`Failed to create audio directory. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    try {
      if (!fileIo.accessSync(coverDir)) {
        await fileIo.mkdir(coverDir);
      }
    } catch (error) {
      console.error(`Failed to create cover directory. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
  }

  private async copyAudio2Sandbox(srcPath: string, dstPath: string): Promise<void> {
    let srcFile: fileIo.File | undefined;
    let dstFile: fileIo.File | undefined;
    try {
      srcFile = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      dstFile = await fileIo.open(dstPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      await fileIo.copyFile(srcFile.fd, dstFile.fd);
    } catch (error) {
      console.error(`Failed to copy audio file from ${srcPath} to ${dstPath}. Cause: ${JSON.stringify(error)}`);
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

  private async fetchSaveAlbumCover(audioPath: string, coverPath: string): Promise<string | null> {
    let avMetadataExtractor: media.AVMetadataExtractor | undefined;
    let coverImg: image.PixelMap | undefined;
    let audioFile: fileIo.File | undefined;
    try {
      let audioStat = await fileIo.stat(audioPath);
      audioFile = await fileIo.open(audioPath, fileIo.OpenMode.READ_ONLY);

      avMetadataExtractor = await media.createAVMetadataExtractor();
      avMetadataExtractor.fdSrc = { fd: audioFile.fd, offset: 0, length: audioStat.size };

      coverImg = await avMetadataExtractor.fetchAlbumCover();
    } catch (error) {
      console.error(`Failed to fetchAlbumCover. Cause: ${JSON.stringify(error)}`);
      return null;
    } finally {
      if (audioFile) {
        await fileIo.close(audioFile);
      }
      if (avMetadataExtractor) {
        await avMetadataExtractor.release();
      }
    }

    let imagePacker: image.ImagePacker | undefined;
    let coverFile: fileIo.File | undefined;
    try {
      coverFile = await fileIo.open(coverPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);

      imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };

      await imagePacker.packToFile(coverImg, coverFile.fd, packOpts);
    } catch (error) {
      console.error(`Faile to save album cover. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    } finally {
      if (coverImg) {
        await coverImg.release();
      }
      if (imagePacker) {
        await imagePacker.release();
      }
      if (coverFile) {
        await fileIo.close(coverFile);
      }
    }

    return coverPath;
  }

  private async insertAudio2DB(name: string, audioPath: string, coverPath: string | null): Promise<void> {
    let audioFile: fileIo.File | undefined;
    let metadata: media.AVMetadata | undefined;
    let avMetadataExtractor: media.AVMetadataExtractor | undefined;
    try {
      let audioStat = await fileIo.stat(audioPath);
      audioFile = await fileIo.open(audioPath, fileIo.OpenMode.READ_ONLY);

      avMetadataExtractor = await media.createAVMetadataExtractor();
      avMetadataExtractor.fdSrc = { fd: audioFile.fd, offset: 0, length: audioStat.size };

      metadata = await avMetadataExtractor.fetchMetadata();
    } catch (error) {
      console.error(`Failed to fetch metadata, error: ${JSON.stringify(error)}`);
    } finally {
      if (avMetadataExtractor) {
        await avMetadataExtractor.release();
      }
      if (audioFile) {
        await fileIo.close(audioFile);
      }
    }

    const audioInfo = new AudioInfoModel();
    audioInfo.name = name;
    audioInfo.audioPath = audioPath;
    audioInfo.coverPath = coverPath ? coverPath : null;
    audioInfo.metadata = metadata ? JSON.stringify(metadata) : null;
    try {
      await this.audioStore.insertAudioInfo(audioInfo);
    } catch (error) {
      throw new Error(error);
    }
  }

  private async createAudioDownloadDir(context: Context): Promise<void> {
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    const documentViewPicker = new picker.DocumentViewPicker(context);
    documentViewPicker.save(documentSaveOptions)
      .then(async (result: string[]) => {
        if (!result || result.length <= 0) {
          console.error(`Failed to invoke DocumentViewPicker.save, result is empty`);
          return;
        }
        console.info(`Download Save Result: ${result}`);
        this.downloadPath = new fileUri.FileUri(result[0]).path;
        const downloadVideoPath = this.downloadPath + DOWNLOAD_AUDIO_DIR;
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
}