import VideoItemViewModel from '../viewmodel/VideoItemViewModel';

@Component
export struct VideoBoxView {
  @ObjectLink videoItem: VideoItemViewModel;
  @Consume('MainPageStack') mainPageStack: NavPathStack;

  build() {
    Row({ space: 12 }) {
      Image(this.videoItem.previewImg)
        .height('90%')
        .aspectRatio(16 / 9)
        .borderRadius(12)
        .objectFit(ImageFit.Cover);

      Column() {
        Text(this.videoItem.videoName)
          .fontSize(12)
          .fontColor(Color.Black);

        Row({ space: 8 }) {
          Row({ space: 2 }) {
            Image($r('app.media.clock'))
              .width(12)
              .aspectRatio(1)
              .fillColor(Color.Green);
            Text(this.videoItem.duration)
              .fontSize(10)
              .fontColor(Color.Gray);
          };

          Row({ space: 2 }) {
            Image($r('app.media.save'))
              .width(12)
              .aspectRatio(1)
              .fillColor(Color.Green);
            Text(this.videoItem.videoSize)
              .fontSize(10)
              .fontColor(Color.Gray);
          };
        }
        .width('100%')
        .justifyContent(FlexAlign.Start);
      }
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceAround);
    }
    .height(100)
    .width('100%')
    .padding(8)
    .borderRadius(12)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.mainPageStack.pushPath({ name: "VideoPlayer", param: this.videoItem.videoInfo });
    });
  }
}