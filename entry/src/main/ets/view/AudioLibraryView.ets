import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioBoxView } from './AudioBoxView';

const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

const audioItem_1 = new AudioItemViewModel();
audioItem_1.audioInfo.id = 0;
audioItem_1.audioName = 'Audio One';
audioItem_1.audioSize = '3.21MB';
audioItem_1.duration = '04:53';

const audioItem_2 = new AudioItemViewModel();
audioItem_2.audioInfo.id = 1;
audioItem_2.audioName = 'Audio Two';
audioItem_2.audioSize = '5.55MB';
audioItem_2.duration = '03:23';

const audioItem_3 = new AudioItemViewModel();
audioItem_3.audioInfo.id = 2;
audioItem_3.audioName = 'Audio Three';
audioItem_3.audioSize = '40.50MB';
audioItem_3.duration = '10:31';

const AUDIO_LIST: AudioItemViewModel[] = [audioItem_1, audioItem_2, audioItem_3];

@Component
export struct AudioLibraryView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @State audioList: AudioItemViewModel[] = AUDIO_LIST;

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      Row() {
        Row({ space: 12 }) {
          Button({ type: ButtonType.Capsule, stateEffect: false }) {
            Image($r('app.media.open_sidebar'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC');

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

      List() {
        ForEach(
          this.audioList,
          (item: AudioItemViewModel) => {
            ListItem() {
              AudioBoxView({
                audioItem: item
              });
            };
          },
          (item: AudioItemViewModel, index: number) => {
            index;
            return item.audioInfo.id.toString();
          }
        );
      }
      .width('100%')
      .height('100%')
      .contentEndOffset(8)
      .contentStartOffset(8)
      .scrollBar(BarState.Off)
      .padding({ left: 8, right: 8 })
      .backgroundColor(`rgb(243, 243, 243)`)
      .divider({ strokeWidth: 8, color: 'rgb(243, 243, 243)' });
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });

  }
}