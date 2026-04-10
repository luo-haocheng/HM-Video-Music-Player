import image from '@ohos.multimedia.image';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { media } from '@kit.MediaKit';

@Observed
export class AudioItemViewModel {
  @Track public id: number = -1;
  @Track public title: string = '';
  @Track public album: string = '未知专辑';
  @Track public artist: string = '未知歌手';
  @Track public isFavorite: boolean = false;
  @Track public albumCover?: image.PixelMap;
  @Track public isChoice: boolean = false;
  public audioInfo: AudioInfoModel = new AudioInfoModel();

  audioSizeStr(bytesCount: number): string {
    let kbBytes = 1024;
    let mbBytes = 1024 * 1024;
    let gbBytes = 1024 * 1024 * 1024;
    if (bytesCount >= gbBytes) {
      let gb = bytesCount / gbBytes;
      return `${gb.toFixed(2)}GB`;
    } else if (bytesCount >= mbBytes) {
      let mb = bytesCount / mbBytes;
      return `${mb.toFixed(2)}MB`;
    } else if (bytesCount >= kbBytes) {
      let kb = bytesCount / kbBytes;
      return `${kb.toFixed(2)}KB`;
    } else {
      return `${bytesCount}B`;
    }
  }

  durationStr(timeMs: number): string {
    let helper = (num: number): string => {
      return num >= 10 ? `${num}` : `0${num}`;
    };
    let timeSS = Math.floor(timeMs / 1000);
    let seconds = timeSS % 60;
    let minutes = Math.floor(timeSS / 60) % 60;
    let hours = Math.floor(timeSS / 3600);
    if (hours > 0) {
      return `${hours}:${helper(minutes)}:${helper(seconds)}`;
    } else {
      return `${helper(minutes)}:${helper(seconds)}`;
    }
  }

  updateFavorite(isFavorite: boolean) {
    this.isFavorite = isFavorite;
    this.audioInfo.favorite = isFavorite ? 1 : 0;
  }

  async updateAudioItem(audioInfo: AudioInfoModel) {
    this.id = audioInfo.id;
    this.audioInfo = audioInfo;
    this.title = audioInfo.name;
    this.isFavorite = audioInfo.favorite === 0 ? false : true;

    if (audioInfo.metadata) {
      let metadata = JSON.parse(audioInfo.metadata) as media.AVMetadata;
      this.title = metadata.title ? metadata.title : audioInfo.name;
      this.artist = metadata.artist ? metadata.artist : this.artist;
      this.album = metadata.album ? metadata.album : this.album;
    }

    if (audioInfo.coverPath) {
      let imageSource: image.ImageSource | undefined;
      try {
        imageSource = image.createImageSource(audioInfo.coverPath);
        this.albumCover = await imageSource.createPixelMap();
      } catch (error) {
        console.error(`Failed to create album cover. Cause: ${JSON.stringify(error)}`);
      } finally {
        if (imageSource) {
          await imageSource.release();
        }
      }
    }
  }
}