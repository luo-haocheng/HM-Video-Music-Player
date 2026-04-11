import { AudioRepeatMode } from '../model/SettingsModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AVCastPicker } from '@kit.AVSessionKit';
import { CurrentPlaylistView } from './CurrentPlaylistView';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct AudioPlayerView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private currPlaylistDialogController?: CustomDialogController;

  @Builder
  pickerBuilder() {
    Button({ type: ButtonType.Circle, stateEffect: false }) {
      Image($r('app.media.dot_radiowaves_left_and_right'))
        .width(24)
        .aspectRatio(1)
        .fillColor(Color.Black);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent);
  }

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
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      Column({ space: 24 }) {
        Row() {
          if (this.audioPlayerVM.currAudioItem && this.audioPlayerVM.currAudioItem.albumCover) {
            Image(this.audioPlayerVM.currAudioItem.albumCover)
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
        .borderRadius(12)
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center);

        Row() {
          Column({ space: 5 }) {
            Text(this.audioPlayerVM.currAudioItem?.title)
              .fontSize(24)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold);
            Text(this.audioPlayerVM.currAudioItem?.artist)
              .fontSize(14)
              .fontColor(Color.Black);
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start);

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image(this.audioPlayerVM.isFavorite ? $r('app.media.heart_fill') : $r('app.media.heart'))
              .width(28)
              .aspectRatio(1);
          }
          .backgroundColor(Color.Transparent)
          .onClick(async () => {
            await this.audioPlayerVM.toggleFavorite();
          });
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .justifyContent(FlexAlign.SpaceBetween);
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center);


      Column({ space: 32 }) {
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
              if (mode === SliderChangeMode.End) {
                this.audioPlayerVM.seek(value);
              }
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
            const context = this.getUIContext().getHostContext() as Context;
            this.audioPlayerVM.switchPrev(context);
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
            const context = this.getUIContext().getHostContext() as Context;
            this.audioPlayerVM.switchNext(context);
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
            if (this.audioPlayerVM.repeatMode === AudioRepeatMode.SINGLE_REPEAT) {
              Image($r('app.media.repeat_1'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            } else if (this.audioPlayerVM.repeatMode === AudioRepeatMode.LIST_REPEAT) {
              Image($r('app.media.repeat'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            } else {
              Image($r('app.media.shuffle'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
          }
          .backgroundColor(Color.Transparent)
          .onClick(async () => {
            this.audioPlayerVM.switchRepeatMode();
          });

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.music_note_list'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .backgroundColor(Color.Transparent)
          .onClick(async () => {
            if (this.audioPlayerVM.currAudioItem) {
              this.currPlaylistDialogController = new CustomDialogController({
                width: '100%',
                height: '60%',
                builder: CurrentPlaylistView(),
                alignment: DialogAlignment.Bottom,
                offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
              });
              this.currPlaylistDialogController.open();
            }
          });

          AVCastPicker({
            customPicker: () => {
              this.pickerBuilder();
            }
          })
            .width(24)
            .aspectRatio(1);
        }
        .width('90%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
      }
      .layoutWeight(0)
      .alignItems(HorizontalAlign.Center);
    }
    .padding(32)
    .width('100%')
    .height('100%');
  }
}