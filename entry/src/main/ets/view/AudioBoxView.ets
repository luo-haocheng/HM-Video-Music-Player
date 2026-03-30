import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';

@Component
export struct AudioBoxView {
  @ObjectLink audioItem: AudioItemViewModel;

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Start,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Row() {
        if (this.audioItem.albumCover) {
          Image(this.audioItem.albumCover)
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
          Text(this.audioItem.title)
            .maxLines(1)
            .fontSize(14)
            .fontColor(Color.Black)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Row() {
            Text(this.audioItem.artist)
              .fontSize(12)
              .fontColor(Color.Gray);
            Text(' · ')
              .fontSize(12)
              .fontColor(Color.Black);
            Text(this.audioItem.album)
              .fontSize(12)
              .fontColor(Color.Gray);
          };
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