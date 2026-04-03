import image from '@ohos.multimedia.image';

@Observed
export class PlayListItemViewModelArray extends Array<PlayListItemViewModel> {
}

@Observed
export class PlayListItemViewModel {
  @Track playListName: string | null = null;
  @Track albumCover?: image.PixelMap;
  @Track playListCount: number = 0;

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