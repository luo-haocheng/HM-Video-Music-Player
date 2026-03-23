import { VideoItemViewModel } from '../viewmodel/VideoItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';

const MULTI_CHOICE = 'MultiChoice';
const CHOICE_COUNT = 'ChoiceCount';

@Component
export struct VideoBoxView {
  @ObjectLink videoItem: VideoItemViewModel;
  @Consume(CHOICE_COUNT) choiceCount: number = 0;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume('MainPageStack') mainPageStack: NavPathStack;
  public isAllChoice: Callback<void> = () => {
  };

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Start,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Image(this.videoItem.previewImg)
        .height('90%')
        .layoutWeight(0)
        .borderRadius(12)
        .draggable(false)
        .aspectRatio(16 / 9)
        .objectFit(ImageFit.Cover);

      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween,
      }) {
        Column() {
          Text(this.videoItem.videoName)
            .maxLines(2)
            .fontSize(12)
            .fontColor(Color.Black)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Row({ space: 12 }) {
            Row({ space: 3 }) {
              Image($r('app.media.clock'))
                .width(12)
                .aspectRatio(1)
                .draggable(false)
                .fillColor(Color.Gray);
              Text(this.videoItem.duration)
                .fontSize(10)
                .fontColor(Color.Gray);
            };

            Row({ space: 3 }) {
              Image($r('app.media.save'))
                .width(12)
                .aspectRatio(1)
                .draggable(false)
                .fillColor(Color.Gray);
              Text(this.videoItem.videoSize)
                .fontSize(10)
                .fontColor(Color.Gray);
            };
          }
          .justifyContent(FlexAlign.Start);
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
              .select($$this.videoItem.isChoice)
              .onDisAppear(() => {
                // delay some time for getting choice item
                setTimeout(() => {
                  this.videoItem.isChoice = false;
                }, 200);
              })
              .onChange((value: boolean) => {
                this.choiceCount += value ? 1 : -1;
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
        this.videoItem.isChoice = !this.videoItem.isChoice;
      } else {
        this.mainPageStack.pushPath({ name: "VideoPlayer", param: this.videoItem.videoInfo });
      }
    });
  }
}