import { LengthMetrics } from '@kit.ArkUI';
import { PlayListItemViewModel } from '../viewmodel/PlayListItemViewModel';

@Component
export struct PlayListBoxView {
  @ObjectLink playlistVM: PlayListItemViewModel;

  build() {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Row() {
        if (this.playlistVM.albumCover) {
          Image(this.playlistVM.albumCover)
            .width('100%')
            .height('100%')
            .draggable(false)
            .fillColor(Color.Pink)
            .objectFit(ImageFit.Cover);
        } else {
          Image($r('app.media.music_fill'))
            .width('50%')
            .aspectRatio(1)
            .draggable(false)
            .fillColor(Color.Pink)
            .objectFit(ImageFit.Contain);
        }
      }
      .height('90%')
      .aspectRatio(1)
      .layoutWeight(0)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);

      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween,
      }) {
        Column() {
          Text(this.playlistVM.playListName)
            .maxLines(1)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(`共${this.playlistVM.playListCount}首歌`)
            .fontSize(12)
            .fontColor(Color.Gray);
        }
        .height('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceAround);
      }
      .layoutWeight(1);
    }
    .padding(8)
    .height(80)
    .width('100%')
    .borderRadius(12)
    .backgroundColor(Color.White);
  }
}