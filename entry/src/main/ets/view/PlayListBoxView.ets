import { LengthMetrics } from '@kit.ArkUI';

@Component
export struct PlayListBoxView {
  @State playListName: string = '';

  build() {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
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
          Text(this.playListName)
            .maxLines(1)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text('共3首歌')
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