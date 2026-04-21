import { AudioLibraryStore } from 'data_storage/src/main/ets/rdbms/AudioLibraryStore';
import picker from '@ohos.file.picker';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import image from '@ohos.multimedia.image';
import { AudioInfoModel } from 'data_storage/src/main/ets/rdbms/AudioInfoModel';
import { AudioItemViewModel } from './AudioItemViewModel';
import { PlayListInfoModel } from 'data_storage/src/main/ets/rdbms/PlayListInfoModel';
import { emitter } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { SettingKey, Settings, SortModeValue, SortRuleValue, ViewOptionValue } from 'data_storage';
import { util } from '@kit.ArkTS';

const SANDBOX_COVER_DIR = '/covers';
const DOWNLOAD_AUDIO_DIR = '/audios';
const SORT_AUDIO_EVENT = 'SortAudio';
const SORT_PLAYLIST_EVENT = 'SortPlaylist';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const CREATE_PLAYLIST_EVENT = 'CreatePlaylist';

@Observed
export class AudioLibraryViewModel {
  @Track audioSortMode: preferences.ValueType = SortModeValue.DATE_ADD;
  @Track audioSortRule: preferences.ValueType = SortRuleValue.ASCENDING;
  @Track playlistSortMode: preferences.ValueType = SortModeValue.DATE_ADD;
  @Track playlistSortRule: preferences.ValueType = SortRuleValue.ASCENDING;
  private audioStore: AudioLibraryStore = new AudioLibraryStore();
  private settings: Settings = new Settings();
  private downloadPath: string = '';

  async init(context: Context): Promise<void> {
    await this.audioStore.initStore(context);
    await this.createAudioDownloadDir(context);
    await this.settings.initPreference(context);
    this.audioSortMode = await this.settings.getSetting(SettingKey.AUDIO_SORT_MODE);
    this.audioSortRule = await this.settings.getSetting(SettingKey.AUDIO_SORT_RULE);
    this.playlistSortMode = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_MODE);
    this.playlistSortRule = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_RULE);
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

  async selectAudioSortMethod(selectSortMode: SortModeValue): Promise<void> {
    if (this.audioSortMode !== selectSortMode) {
      await this.settings.putSetting(SettingKey.AUDIO_SORT_MODE, selectSortMode);
    } else {
      const rule =
        (this.audioSortRule === SortRuleValue.ASCENDING ? SortRuleValue.DESCENDING : SortRuleValue.ASCENDING);
      await this.settings.putSetting(SettingKey.AUDIO_SORT_RULE, rule);
    }
    this.audioSortMode = await this.settings.getSetting(SettingKey.AUDIO_SORT_MODE);
    this.audioSortRule = await this.settings.getSetting(SettingKey.AUDIO_SORT_RULE);
    // Notify
    emitter.emit(SORT_AUDIO_EVENT);
  }

  async selectPlaylistSortMethod(selectSortMode: SortModeValue): Promise<void> {
    if (this.playlistSortMode !== selectSortMode) {
      await this.settings.putSetting(SettingKey.PLAYLIST_SORT_MODE, selectSortMode);
    } else {
      const rule =
        (this.playlistSortRule === SortRuleValue.ASCENDING ? SortRuleValue.DESCENDING : SortRuleValue.ASCENDING);
      await this.settings.putSetting(SettingKey.PLAYLIST_SORT_RULE, rule);
    }
    this.playlistSortMode = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_MODE);
    this.playlistSortRule = await this.settings.getSetting(SettingKey.PLAYLIST_SORT_RULE);
    // Notify
    emitter.emit(SORT_PLAYLIST_EVENT);
  }

  async createAudioPlaylist(playlistName: string): Promise<void> {
    const playlistInfo = new PlayListInfoModel();
    playlistInfo.name = playlistName;
    playlistInfo.dateAdd = new Date().getTime();
    await this.audioStore.insertPlaylistInfo(playlistInfo);
    // Notify
    const eventData: emitter.EventData = {
      data: {
        'info': playlistInfo
      }
    };
    emitter.emit(CREATE_PLAYLIST_EVENT, eventData);
  }

  async importAudioFromAudioLib(context: Context): Promise<void> {
    const audioViewPicker = new picker.AudioViewPicker(context);
    audioViewPicker.select()
      .then(async (selectedUris: Array<string>) => {
        for (let i = 0; i < selectedUris.length; ++i) {
          try {
            await this.importAudio(selectedUris[i], context);
          } catch (error) {
            // todo
          }
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
          try {
            await this.importAudio(selectedUris[i], context);
          } catch (error) {
            // todo
          }
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async importAudioFromDownloadDir(context: Context): Promise<void> {
    try {
      const downloadAudioPath = this.downloadPath + DOWNLOAD_AUDIO_DIR;
      let traverseDir = async (dir: string) => {
        let files = await fileIo.listFile(dir);
        for (let i = 0; i < files.length; ++i) {
          let path = dir + `/${files[i]}`;
          let stat = await fileIo.stat(path);
          if (stat.isDirectory()) {
            await traverseDir(path);
          } else {
            try {
              await this.importAudio(path, context);
            } catch (error) {
              // todo
            }
          }
        }
      };
      await traverseDir(downloadAudioPath);
    } catch (error) {
      console.error(`Failed to import video from download directory`);
    }
  }

  async selectViewOption(viewOption: ViewOptionValue) {
    await this.settings.putSetting(SettingKey.AUDIO_VIEW_OPTION, viewOption);
  }

  async getViewOptions(): Promise<ViewOptionValue> {
    return await this.settings.getSetting(SettingKey.AUDIO_VIEW_OPTION) as ViewOptionValue;
  }

  private async importAudio(srcUri: string, context: Context): Promise<void> {
    // Create audio and cover sandbox directory if not exist
    try {
      await this.createCoverSandboxDir(context);
    } catch (error) {
      throw Error(error);
    }
    // Copy audio file to download directory
    let audioPath: string = '';
    try {
      const downloadAudioPath = this.downloadPath + DOWNLOAD_AUDIO_DIR;
      audioPath = await this.copyAudio2DownloadDir(srcUri, downloadAudioPath);
    } catch (error) {
      throw Error(error);
    }
    // Fetch and save album cover to sandbox
    let coverPath: string | null = context.filesDir + SANDBOX_COVER_DIR + `/${util.generateRandomUUID()}.jpg`;
    try {
      coverPath = await this.fetchSaveAlbumCover(audioPath, coverPath);
    } catch (error) {
      throw Error(error);
    }
    // Insert audio record to database
    let audioInfo: AudioInfoModel | undefined;
    const audioName = this.getFileNameFromFileUri(srcUri);
    try {
      audioInfo = await this.insertAudio2DB(audioName, audioPath, coverPath);
    } catch (error) {
      throw Error(error);
    }
    // Notify
    if (audioInfo) {
      const eventData: emitter.EventData = {
        data: {
          'info': audioInfo
        }
      };
      emitter.emit(IMPORT_AUDIO_EVENT, eventData);
    }
  }

  private async copyAudio2DownloadDir(srcUri: string, downloadAudioPath: string): Promise<string> {
    let srcFile: fileIo.File | undefined;
    let dstFile: fileIo.File | undefined;
    try {
      if (srcUri.includes(downloadAudioPath)) {
        const srcPath = new fileUri.FileUri(srcUri).path;
        return srcPath;
      }

      const dstUri: string = downloadAudioPath + '/' + this.getFileNameFromFileUri(srcUri);
      const srcPath = new fileUri.FileUri(srcUri).path;
      const dstPath = new fileUri.FileUri(dstUri).path;

      srcFile = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      dstFile = await fileIo.open(dstPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      await fileIo.copyFile(srcFile.fd, dstFile.fd);

      return dstPath;
    } catch (error) {
      console.error(`Failed to copy audio file ${srcUri} to download directory. Cause: ${JSON.stringify(error)}`);
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
      const documentViewPicker = new picker.DocumentViewPicker();
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;

      const documentSaveResult = await documentViewPicker.save(documentSaveOptions);
      if (documentSaveResult.length <= 0) {
        throw Error('Document save result is zero');
      }

      coverFile = await fileIo.open(coverPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);

      imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };

      await imagePacker.packToFile(coverImg, coverFile.fd, packOpts);

      return coverPath;
    } catch (error) {
      console.error(`Faile to save album cover. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
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
  }

  private async insertAudio2DB(audioName: string, audioPath: string,
    coverPath: string | null): Promise<AudioInfoModel> {
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
    audioInfo.favorite = 0;
    audioInfo.audioPath = audioPath;
    audioInfo.dateAdd = new Date().getTime();
    audioInfo.coverPath = coverPath ? coverPath : null;
    audioInfo.title = metadata?.title ? metadata.title : audioName;
    audioInfo.metadata = metadata ? JSON.stringify(metadata) : null;
    audioInfo.album = (metadata && metadata.album) ? metadata.album : null;
    audioInfo.artist = (metadata && metadata.artist) ? metadata.artist : null;
    try {
      audioInfo.id = await this.audioStore.insertAudioInfo(audioInfo);
    } catch (error) {
      throw Error(error);
    }

    return audioInfo;
  }

  private async createCoverSandboxDir(context: Context) {
    const sandboxCoverPath = context.filesDir + SANDBOX_COVER_DIR;
    try {
      if (!fileIo.accessSync(sandboxCoverPath, fileIo.AccessModeType.EXIST)) {
        await fileIo.mkdir(sandboxCoverPath);
      }
    } catch (error) {
      console.error(`Failed to make cover sandbox directory. Cause: ${JSON.stringify(error)}`);
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
        this.downloadPath = new fileUri.FileUri(result[0]).path;
        try {
          const downloadAudioPath = this.downloadPath + DOWNLOAD_AUDIO_DIR;
          if (!fileIo.accessSync(downloadAudioPath, fileIo.AccessModeType.EXIST)) {
            await fileIo.mkdir(downloadAudioPath);
          }
        } catch (error) {
          console.error(`Failed to make audio download directory. Cause: ${JSON.stringify(error)}`);
        }
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke DocumentViewPicker.save. Cause: ${JSON.stringify(err)}`);
      });
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