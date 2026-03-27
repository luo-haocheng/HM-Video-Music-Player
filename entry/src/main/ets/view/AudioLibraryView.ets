const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct AudioLibraryView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      Row() {
        Row({ space: 12 }) {
          Text('音频')
            .maxLines(1)
            .fontSize(20)
            .layoutWeight(1)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1);

        Row({ space: 12 }) {
          Button({ type: ButtonType.Capsule, stateEffect: false }) {
            Text('多选')
              .fontSize(14)
              .fontColor(Color.Black);
          }
          .width(36 * 1.5)
          .aspectRatio(1.5)
          .backgroundColor('#AADCDCDC');

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.plus'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC');

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.dot_grid_2x2'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC');
        };
      }
      .padding(16)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween);

      Navigation() {

      }
      .hideToolBar(true)
      .mode(NavigationMode.Stack)
      .backgroundColor(`rgb(243, 243, 243)`);
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });

  }
}