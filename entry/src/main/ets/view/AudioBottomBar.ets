import { LengthMetrics } from '@kit.ArkUI';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';

@Component
export struct AudioBottomBar {
  @Consume('MainPageStack') mainPageStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceAround,
      space: { main: LengthMetrics.vp(12) }
    }) {
      Row() {
        if (this.audioPlayerVM.currIndex !== -1 &&
        this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].albumCover) {
          Image(this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].albumCover)
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
      .height('100%')
      .aspectRatio(1)
      .layoutWeight(0)
      .borderRadius(12)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center);

      Column() {
        if (this.audioPlayerVM.currIndex !== -1) {
          Text(this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].title)
            .maxLines(1)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].artist)
            .fontSize(10)
            .fontColor(Color.Black);
        } else {
          Text('未在播放')
            .maxLines(1)
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);
        }
      }
      .height('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.SpaceAround);

      Row({ space: 16 }) {
        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image(this.audioPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
            .width(24)
            .aspectRatio(1)
            .fillColor(Color.Black);
        }
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          if (this.audioPlayerVM.isPlaying) {
            await this.audioPlayerVM.pause();
          } else {
            await this.audioPlayerVM.play();
          }
        });

        Image($r('app.media.music_note_list'))
          .width(24)
          .aspectRatio(1)
          .fillColor(Color.Black);
      }
      .layoutWeight(0)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .opacity(0.8)
    .borderRadius(12)
    .backgroundColor(Color.Gray)
    .onClick(() => {
      if (this.audioPlayerVM.currIndex !== -1) {
        this.mainPageStack.pushPath({ name: 'AudioPlayer' });
      }
    });
  }
}