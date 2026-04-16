import { LengthMetrics } from '@kit.ArkUI';
import { ViewOptionValue } from 'data_storage';
import { PlayListItemViewModel } from '../viewmodel/PlayListItemViewModel';

const AUDIO_VIEW_OPTION = 'AudioViewOption';

@Component
export struct PlayListBoxView {
  @ObjectLink playlistVM: PlayListItemViewModel;
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;

  build() {
    if (this.audioViewOptions === ViewOptionValue.LIST_VIEW) {
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
              .borderRadius(12)
              .draggable(false)
              .objectFit(ImageFit.Cover);
          } else {
            Image($r('app.media.music_fill'))
              .width('50%')
              .aspectRatio(1)
              .draggable(false)
              .fillColor('#FF007DFF')
              .objectFit(ImageFit.Contain);
          }
        }
        .height('90%')
        .aspectRatio(1)
        .layoutWeight(0)
        .borderRadius(12)
        .backgroundColor(Color.White)
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

            Text(`${this.playlistVM.playListCount}个内容`)
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
      .borderRadius(12);

      // .backgroundColor(Color.White);
    } else {
      Flex({
        direction: FlexDirection.Column,
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
              .borderRadius(12)
              .objectFit(ImageFit.Cover);
          } else {
            Image($r('app.media.music_fill'))
              .width('50%')
              .aspectRatio(1)
              .draggable(false)
              .fillColor('#FF007DFF')
              .objectFit(ImageFit.Contain);
          }
        }
        .width('100%')
        .aspectRatio(1)
        .layoutWeight(0)
        .borderRadius(12)
        .backgroundColor(Color.White)
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

            Text(`${this.playlistVM.playListCount}个内容`)
              .fontSize(12)
              .fontColor(Color.Gray);
          }
          .height('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.SpaceAround);
        }
        .layoutWeight(1);
      }
      .padding(8)
      .height(220)
      .width('100%')
      .borderRadius(12);
    }
  }
}