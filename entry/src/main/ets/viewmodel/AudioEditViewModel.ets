import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { fileIo } from '@kit.CoreFileKit';
import picker from '@ohos.file.picker';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { util } from '@kit.ArkTS';
import image from '@ohos.multimedia.image';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AudioItemViewModel } from './AudioItemViewModel';

const LYRICS_DIR = '/lyrics';
const COVER_DIR = '/covers';

@Observed
export class AudioEditViewModel {
  @Track title: string = '';
  @Track album: string = '';
  @Track artist: string = '';
  @Track lyrics: string = '';
  @Track albumCover?: image.PixelMap;
  private originalLyrics: string = '';
  private originalAlbumCover?: image.PixelMap;
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async init(context: Context, audioInfo: AudioInfoModel): Promise<void> {
    await this.audioStore.initStore(context);
    this.title = audioInfo.title;
    this.album = audioInfo.album ?? '';
    this.artist = audioInfo.artist ?? '';
    if (audioInfo.lyricsPath) {
      try {
        this.lyrics = await fileIo.readText(audioInfo.lyricsPath);
        this.originalLyrics = this.lyrics;
      } catch (err) {
        console.error(`Failed read lyrics ${audioInfo.lyricsPath}. ${JSON.stringify(err)}`);
        return;
      }
    }
    if (audioInfo.coverPath) {
      try {
        this.albumCover = await this.decodeCover(audioInfo.coverPath);
        this.originalAlbumCover = this.albumCover;
      } catch (error) {
        console.error(`Failed to decode album cover. Cause: ${JSON.stringify(error)}`);
        return;
      }
    }
  }

  async submitEdit(context: Context, audioItem: AudioItemViewModel): Promise<void> {
    if (this.title !== audioItem.audioInfo.title && this.title.length > 0) {
      await this.audioStore.updateAudioTitle(audioItem.audioInfo, this.title);
      audioItem.audioInfo.title = this.title;
      audioItem.title = this.title;
    }
    if (this.album !== audioItem.audioInfo.album ?? '') {
      const album = this.album.length === 0 ? null : this.album;
      await this.audioStore.updateAudioAlbum(audioItem.audioInfo, album);
      audioItem.album = album ?? '未知专辑';
      audioItem.audioInfo.album = album;
    }
    if (this.artist !== audioItem.audioInfo.artist ?? '') {
      const artist = this.artist.length === 0 ? null : this.artist;
      await this.audioStore.updateAudioArtist(audioItem.audioInfo, artist);
      audioItem.artist = artist ?? '未知歌手';
      audioItem.audioInfo.artist = artist;
    }
    if (this.lyrics !== this.originalLyrics) {
      await this.updateLyrics(context, audioItem.audioInfo);
    }
    if (this.albumCover !== this.originalAlbumCover) {
      await this.updateAlbumCover(context, audioItem.audioInfo);
      await audioItem.albumCover?.release();
      audioItem.albumCover = this.albumCover;
    }
  }

  async selectLyricsFile(): Promise<void> {
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = ['歌词|.lrc'];
    const documentViewPicker = new picker.DocumentViewPicker();
    try {
      const selectedUris = await documentViewPicker.select(documentSelectOptions);
      if (selectedUris.length <= 0) {
        return;
      }
      this.lyrics = await this.readLyrics(selectedUris[0]);
    } catch (err) {
      console.error(`Failed to invoke DocumentViewPicker.select. Cause: ${JSON.stringify(err)}`);
      throw Error(err);
    }
  }

  async selectAlbumCover(): Promise<void> {
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.isPhotoTakingSupported = false;
    photoSelectOptions.maxSelectNumber = 1;
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoViewPicker.select(photoSelectOptions)
      .then(async (result: photoAccessHelper.PhotoSelectResult) => {
        let selectedUri = result.photoUris;
        if (selectedUri.length <= 0) {
          return;
        }
        if (this.albumCover) {
          await this.albumCover.release();
        }
        this.albumCover = await this.decodeCover(selectedUri[0]);
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke PhotoViewPicker.select. Cause: ${JSON.stringify(err)}`);
      });
  }

  async deleteAlbumCover(): Promise<void> {
    if (this.albumCover) {
      await this.albumCover.release();
      this.albumCover = undefined;
    }
  }

  private async updateLyrics(context: Context, audioInfo: AudioInfoModel): Promise<void> {
    // Create lyrics directory if not exist
    const lyricsDir = context.filesDir + LYRICS_DIR;
    try {
      await this.createLyricsDir(lyricsDir);
    } catch (err) {
      throw Error(err);
    }
    // Update lyrics file
    let lyricsPath = audioInfo.lyricsPath;
    let lyricsFile: fileIo.File | undefined;
    try {
      if (!lyricsPath) {
        lyricsPath = lyricsDir + `/${util.generateRandomUUID()}.lrc`;
      }
      lyricsFile = await fileIo.open(lyricsPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      await fileIo.write(lyricsFile.fd, this.lyrics);
    } catch (err) {
      console.error(`Failed to write lyrics to file. ${JSON.stringify(err)}`);
      throw Error(err);
    } finally {
      if (lyricsFile) {
        await fileIo.close(lyricsFile);
      }
    }
    // Update database
    if (!audioInfo.lyricsPath) {
      try {
        this.audioStore.updateAudioLyrics(audioInfo, lyricsPath);
        audioInfo.lyricsPath = lyricsPath;
      } catch (err) {
        throw Error(err);
      }
    }
  }

  private async updateAlbumCover(context: Context, audioInfo: AudioInfoModel) {
    // Create cover directory if not exist
    const coverDir = context.filesDir + COVER_DIR;
    try {
      await this.createLyricsDir(coverDir);
    } catch (err) {
      throw Error(err);
    }
    // Update cover file
    if (!this.albumCover && audioInfo.coverPath) {
      try {
        this.audioStore.updateAudioAlbumCover(audioInfo, null);
        audioInfo.coverPath = null;
      } catch (err) {
        throw Error(err);
      }
      return;
    }

    let coverPath = audioInfo.coverPath;
    let coverFile: fileIo.File | undefined;
    let imagePacker: image.ImagePacker | undefined;
    try {
      if (!coverPath) {
        coverPath = coverDir + `/${util.generateRandomUUID()}.jpg`;
      }
      coverFile = await fileIo.open(coverPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);

      imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };
      await imagePacker.packToFile(this.albumCover, coverFile.fd, packOpts);
    } catch (err) {
      console.error(`Failed to pack album cover to file. ${JSON.stringify(err)}`);
      throw Error(err);
    } finally {
      if (coverFile) {
        await fileIo.close(coverFile);
      }
      if (imagePacker) {
        await imagePacker.release();
      }
    }
    // Update database
    if (!audioInfo.coverPath) {
      try {
        this.audioStore.updateAudioAlbumCover(audioInfo, coverPath);
        audioInfo.coverPath = coverPath;
      } catch (err) {
        throw Error(err);
      }
    }
  }

  private async decodeCover(coverPath: string): Promise<image.PixelMap> {
    let coverFile: fileIo.File | undefined;
    let imageSource: image.ImageSource | undefined;
    try {
      coverFile = await fileIo.open(coverPath, fileIo.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(coverFile.fd);
      const coverImg = imageSource.createPixelMap();
      return coverImg;
    } catch (error) {
      console.error(`Failed to create preview image. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
    } finally {
      if (coverFile) {
        await fileIo.close(coverFile);
      }
      if (imageSource) {
        await imageSource.release();
      }
    }
  }

  private async readLyrics(lyricsPath: string): Promise<string> {
    let lyricsFile: fileIo.File | undefined;
    try {
      lyricsFile = await fileIo.open(lyricsPath, fileIo.OpenMode.READ_ONLY);
      const fileSize = (await fileIo.stat(lyricsFile.fd)).size;
      const buffer = new ArrayBuffer(fileSize);
      await fileIo.read(lyricsFile.fd, buffer);

      const textDecoder = new util.TextDecoder();
      const lyrics = textDecoder.decodeToString(new Uint8Array(buffer));
      return lyrics;
    } catch (error) {
      console.error(`Failed to read lyrics from ${lyricsPath}. Cause: ${JSON.stringify(error)}`);
      throw Error(error);
    } finally {
      if (lyricsFile) {
        await fileIo.close(lyricsFile);
      }
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