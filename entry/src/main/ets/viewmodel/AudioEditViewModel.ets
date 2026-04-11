import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { fileIo } from '@kit.CoreFileKit';
import picker from '@ohos.file.picker';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { util } from '@kit.ArkTS';

const LYRICS_DIR = '/lyrics';

@Observed
export class AudioEditViewModel {
  @Track lyrics: string = '';
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context, lyricsPath: string | null): Promise<void> {
    await this.audioStore.initStore(context);
    if (lyricsPath) {
      try {
        this.lyrics = await fileIo.readText(lyricsPath);
      } catch (err) {
        console.error(`Failed read lyrics ${lyricsPath}. ${JSON.stringify(err)}`);
        return;
      }
    }
  }

  async selectLyricsFile(context: Context, audioInfo: AudioInfoModel): Promise<void> {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = ['歌词|.lrc'];
    const documentViewPicker = new picker.DocumentViewPicker();
    let lyricsPath: string | undefined;
    try {
      const selectedUris = await documentViewPicker.select(documentSelectOptions);
      if (selectedUris.length <= 0) {
        return;
      }
      lyricsPath = selectedUris[0];
    } catch (err) {
      console.error(`Failed to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      throw Error(err);
    }
    try {
      this.importLyrics(context, lyricsPath, audioInfo);
    } catch (err) {
      throw Error(err);
    }
  }

  private async importLyrics(context: Context, srcPath: string, audioInfo: AudioInfoModel): Promise<void> {
    // Create lyrics directory if not exist
    const lyricsDir = context.filesDir + LYRICS_DIR;
    try {
      await this.createLyricsDir(lyricsDir);
    } catch (err) {
      throw Error(err);
    }
    // copy lyrics file to sandbox
    let srcFile: fileIo.File | undefined;
    let desFile: fileIo.File | undefined;
    try {
      const desPath = lyricsDir + `/${util.generateRandomUUID()}.mp4`;
      srcFile = await fileIo.open(srcPath, fileIo.OpenMode.READ_ONLY);
      desFile = await fileIo.open(desPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.copyFile(srcFile.fd, desFile.fd);
      this.lyrics = await fileIo.readText(desPath);
      audioInfo.lyricsPath = desPath;
    } catch (err) {
      console.error(`Failed to coy selected lyrics file. ${JSON.stringify(err)}`);
      throw Error(err);
    } finally {
      if (srcFile) {
        await fileIo.close(srcFile);
      }
      if (desFile) {
        await fileIo.close(desFile);
      }
    }
    // Update database
    try {
      this.audioStore.updateAudioLyrics(audioInfo, audioInfo.lyricsPath);
    } catch (err) {
      throw Error(err);
    }
  }

  private async createLyricsDir(lyricsDir: string): Promise<void> {
    try {
      if (!fileIo.accessSync(lyricsDir)) {
        await fileIo.mkdir(lyricsDir);
      }
    } catch (error) {
      console.error(`Failed to create lyrics directory. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
    }
  }
}