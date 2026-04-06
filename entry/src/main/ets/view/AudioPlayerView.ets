import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Builder
export function AudioPlayerBuilder() {
  AudioPlayerView();
}

@Component
export struct AudioPlayerView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  private timeStr(timeMs: number): string {
    let helper = (num: number): string => {
      return num >= 10 ? `${num}` : `0${num}`;
    };
    let timeSS = Math.floor(timeMs / 1000);
    let seconds = timeSS % 60;
    let minutes = Math.floor(timeSS / 60) % 60;
    let hours = Math.floor(timeSS / 3600);
    if (hours > 0) {
      return `${hours}:${helper(minutes)}:${helper(seconds)}`;
    } else {
      return `${helper(minutes)}:${helper(seconds)}`;
    }
  }

  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Column({ space: 3 }) {
          Text(this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].title)
            .fontSize(24)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);
          Text(this.audioPlayerVM.audioList[this.audioPlayerVM.currIndex].artist)
            .fontSize(12)
            .fontColor(Color.Black);
        }
        .width('100%')
        .layoutWeight(0)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Column({ space: 12 }) {
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
          .width('90%')
          .aspectRatio(1)
          .borderRadius(24)
          .backgroundColor(Color.White)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center);

          Row() {
            if (this.audioPlayerVM.bitRate && this.audioPlayerVM.codecMime && this.audioPlayerVM.sampleRate) {
              Text(this.audioPlayerVM.codecMime)
                .fontSize(10)
                .fontColor(Color.Black);

              Text(this.audioPlayerVM.sampleRate)
                .fontSize(10)
                .fontColor(Color.Black);

              Text(this.audioPlayerVM.bitRate)
                .fontSize(10)
                .fontColor(Color.Black);
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceEvenly);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Column({ space: 30 }) {
          Row({ space: 8 }) {
            Text(this.timeStr(this.audioPlayerVM.currTime))
              .fontSize(12)
              .fontColor(Color.Black)
              .layoutWeight(0);

            Slider({
              min: 0,
              max: this.audioPlayerVM.duration,
              value: this.audioPlayerVM.currTime,
              style: SliderStyle.NONE,
            })
              .height(24)
              .layoutWeight(1)
              .trackThickness(8)
              .trackColor('#22000000')
              .blockSize({ width: 12, height: 12 })
              .onChange(async (value: number, mode: SliderChangeMode) => {
                // todo
              });

            Text(this.timeStr(this.audioPlayerVM.duration))
              .fontSize(12)
              .fontColor(Color.Black)
              .layoutWeight(0);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);

          Row() {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.backward_end_fill'))
                .width(36)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image(this.audioPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
                .width(36)
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

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.forward_end_fill'))
                .width(36)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceAround);

          Row() {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.dot_grid_1x2'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.repeat'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.music_note_list'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.dot_radiowaves_left_and_right'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              // todo
            });
          }
          .width('90%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .layoutWeight(0)
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .height('100%')
      .padding({
        top: 32,
        bottom: 32
      });
    }
    .padding({
      left: 32,
      right: 32,
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .backgroundColor('#DCDCDC')
    .hideBackButton(true);
  }
}