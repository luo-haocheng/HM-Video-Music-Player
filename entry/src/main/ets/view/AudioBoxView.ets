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
        Image($r('app.media.music_fill'))
          .width('50%')
          .aspectRatio(1)
          .draggable(false)
          .fillColor(Color.Pink)
          .objectFit(ImageFit.Contain);
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
          Text(this.audioItem.audioName)
            .maxLines(1)
            .fontSize(14)
            .fontColor(Color.Black)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Row({ space: 12 }) {
            Text('未知歌手')
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