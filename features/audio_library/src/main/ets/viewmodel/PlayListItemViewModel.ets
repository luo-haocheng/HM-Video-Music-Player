import image from '@ohos.multimedia.image';
import { PlayListInfoModel } from 'data_storage/src/main/ets/rdbms/PlayListInfoModel';

@Observed
export class PlayListItemViewModelArray extends Array<PlayListItemViewModel> {
}

@Observed
export class PlayListItemViewModel {
  @Track playListName: string | null = null;
  @Track albumCover?: image.PixelMap;
  @Track playListCount: number = 0;
  @Track isChoice: boolean = false;
  playlistInfo: PlayListInfoModel = new PlayListInfoModel();

  async updatePlaylistItem(playlistInfo: PlayListInfoModel) {
    this.playListName = playlistInfo.name;
    this.playlistInfo = playlistInfo;
  }

  async updateAlbumCover(coverPath: string): Promise<void> {
    let imageSource: image.ImageSource | undefined;
    try {
      imageSource = image.createImageSource(coverPath);
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