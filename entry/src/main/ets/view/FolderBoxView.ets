import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';

@Component
export struct FolderBoxView {
  @ObjectLink folderItem: FolderItemViewModel;
  @Consume('VideoTabStack') videoTabStack: NavPathStack = new NavPathStack();

  build() {
    Row({ space: 12 }) {
      Image($r('app.media.folder_fill'))
        .height('90%')
        .borderRadius(12)
        .draggable(false)
        .aspectRatio(16 / 9)
        .fillColor(Color.Orange)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#88DCDCDC');

      Column() {
        Text(this.folderItem.folderName)
          .fontSize(12)
          .fontColor(Color.Black);

        Row({ space: 3 }) {
          Image($r('app.media.calendar'))
            .width(12)
            .aspectRatio(1)
            .draggable(false)
            .fillColor(Color.Green);

          Text(this.folderItem.dateAdd)
            .fontSize(10)
            .fontColor(Color.Gray);
        };
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
      this.videoTabStack.pushPath({ name: "VideoList", param: this.folderItem.folderInfo });
    });
  }
}