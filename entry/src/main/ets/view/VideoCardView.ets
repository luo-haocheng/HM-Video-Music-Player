import VideoItemViewModel from '../viewmodel/VideoItemViewModel';

@Component
export struct VideoCardView {
  @ObjectLink videoItem: VideoItemViewModel;
  @Consume('MainPageStack') mainPageStack: NavPathStack;

  build() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.videoItem.previewImg)
          .width('100%')
          .height(100)
          .borderRadius(12)
          .objectFit(ImageFit.Cover);

        Row() {
          Text(this.videoItem.duration)
            .fontSize(12)
            .fontColor(Color.Black);
        }
        .padding(6);
      };

      Text(this.videoItem.videoName)
        .fontSize(14)
        .fontColor(Color.Black);

      Blank();

      Row() {
        Text(this.videoItem.videoSize)
          .fontSize(12)
          .fontColor(Color.Gray);

        Text(this.videoItem.dateAdd)
          .fontSize(12)
          .fontColor(Color.Gray);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .height(180)
    .padding(8)
    .borderRadius(12)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.mainPageStack.pushPath({ name: "VideoPlayer", param: this.videoItem.videoName });
    });
  }
}