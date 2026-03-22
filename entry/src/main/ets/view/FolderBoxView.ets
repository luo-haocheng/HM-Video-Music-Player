import { FolderItemViewModel } from '../viewmodel/FolderItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';

const MULTI_CHOICE = 'MultiChoice';

@Component
export struct FolderBoxView {
  @ObjectLink folderItem: FolderItemViewModel;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume('VideoTabStack') videoTabStack: NavPathStack = new NavPathStack();
  public isAllChoice: Callback<void> = () => {
  };

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Start,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Image($r('app.media.folder_fill'))
        .height('90%')
        .layoutWeight(0)
        .borderRadius(12)
        .draggable(false)
        .aspectRatio(16 / 9)
        .fillColor(Color.Orange)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#88DCDCDC');

      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween,
      }) {
        Column() {
          Text(this.folderItem.folderName)
            .maxLines(2)
            .fontSize(12)
            .fontColor(Color.Black)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

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
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceAround);

        if (this.multiChoice) {
          Column() {
            Checkbox()
              .width(18)
              .aspectRatio(1)
              .select($$this.folderItem.isChoice)
              .onDisAppear(() => {
                // delay some time for getting choice item
                setTimeout(() => {
                  this.folderItem.isChoice = false;
                }, 200);
              })
              .onChange(() => {
                this.isAllChoice();
              });
          }
          .height('100%')
          .layoutWeight(0)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }
      }
      .layoutWeight(1);
    }
    .padding(8)
    .height(100)
    .width('100%')
    .borderRadius(12)
    .backgroundColor(Color.White)
    .onClick(() => {
      if (this.multiChoice) {
        this.folderItem.isChoice = !this.folderItem.isChoice;
      } else {
        this.videoTabStack.pushPath({ name: "VideoBrowser", param: this.folderItem.folderInfo });
      }
    });
  }
}