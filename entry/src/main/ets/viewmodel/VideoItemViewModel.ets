import { VideoInfoModel } from '../model/VideoInfoModel';
import image from '@ohos.multimedia.image';
import { fileIo } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

@Observed
export class VideoItemViewModel {
  @Track public isChoice: boolean = false;
  @Track public videoName: string = '';
  @Track public videoSize: string = '';
  @Track public duration: string = '';
  @Track public dateAdd: string = '';
  @Track public previewImg?: image.PixelMap;
  public videoInfo: VideoInfoModel = new VideoInfoModel();

  videoSizeStr(bytesCount: number): string {
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

  async updateVideoItem(videoInfo: VideoInfoModel) {
    this.videoInfo = videoInfo;
    this.videoName = videoInfo.name;
    this.dateAdd = new Date(videoInfo.dateAdd).toISOString().slice(0, 10);

    try {
      let videoStat = await fileIo.stat(videoInfo.videoPath);
      this.videoSize = this.videoSizeStr(videoStat.size);
    } catch (error) {
      console.error(`Failed to invoke fileIo.stat. Cause: ${JSON.stringify(error)}`);
    }

    let metadata = JSON.parse(videoInfo.metadata) as media.AVMetadata;
    this.duration = this.durationStr(metadata.duration ? parseInt(metadata.duration) : 0);

    let imageSource: image.ImageSource | undefined;
    try {
      imageSource = image.createImageSource(videoInfo.thumbnailPath);
      this.previewImg = await imageSource.createPixelMap();
    } catch (error) {
      console.error(`Failed to create preview image. Cause: ${JSON.stringify(error)}`);
    } finally {
      if (imageSource) {
        imageSource.release();
      }
    }
  }
}