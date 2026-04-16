import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { ViewOptionValue } from 'data_storage';

const MULTI_CHOICE = 'MultiChoice';
const CHOICE_COUNT = 'ChoiceCount';
const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const AUDIO_VIEW_OPTION = 'AudioViewOption';

@Component
export struct AudioBoxView {
  @ObjectLink audioItem: AudioItemViewModel;
  @Consume(CHOICE_COUNT) choiceCount: number = 0;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume(AUDIO_VIEW_OPTION) audioViewOptions: ViewOptionValue = ViewOptionValue.LIST_VIEW;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  public isAllChoice: Callback<void> = () => {
  };

  build() {
    if (this.audioViewOptions === ViewOptionValue.LIST_VIEW) {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Start,
        space: { main: LengthMetrics.vp(12) }
      }) {
        Row() {
          if (this.audioItem.albumCover) {
            Image(this.audioItem.albumCover)
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
            Text(this.audioItem.title)
              .maxLines(1)
              .fontSize(14)
              .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Black)
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Row() {
              Text(this.audioItem.artist)
                .fontSize(12)
                .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Gray);
              Text(' · ')
                .fontSize(12)
                .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Gray);
              Text(this.audioItem.album)
                .fontSize(12)
                .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Gray);
            }
            .width('100%');
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
                .select($$this.audioItem.isChoice)
                .onDisAppear(() => {
                  // delay some time for getting choice item
                  setTimeout(() => {
                    this.audioItem.isChoice = false;
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
      .height(80)
      .width('100%')
      .borderRadius(12);
    } else {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
        space: { main: LengthMetrics.vp(12) }
      }) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Row() {
            if (this.audioItem.albumCover) {
              Image(this.audioItem.albumCover)
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
          .width('100%')
          .aspectRatio(1)
          .layoutWeight(1)
          .borderRadius(12)
          .backgroundColor(Color.White)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center);

          if (this.multiChoice) {
            Checkbox()
              .width(18)
              .aspectRatio(1)
              .select($$this.audioItem.isChoice)
              .onDisAppear(() => {
                // delay some time for getting choice item
                setTimeout(() => {
                  this.audioItem.isChoice = false;
                }, 200);
              })
              .onChange((value: boolean) => {
                this.choiceCount += value ? 1 : -1;
                this.isAllChoice();
              });
          }
        };

        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween,
        }) {
          Column() {
            Text(this.audioItem.title)
              .maxLines(1)
              .fontSize(14)
              .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Black)
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(this.audioItem.artist)
              .fontSize(12)
              .fontColor(this.audioItem.id === this.audioPlayerVM.currAudioItem?.id ? '#FF007DFF' : Color.Gray);
          }
          .height('100%')
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
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