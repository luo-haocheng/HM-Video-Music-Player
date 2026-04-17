import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { AVVolumePanel } from '@kit.AudioKit';
import { VideoInfoModel } from 'data_storage';

@Builder
export function VideoPlayerBuilder() {
  VideoPlayerView();
}

const MAX_VOLUME_LEVEL = 15;
const MAX_WINDOW_BRIGHTNESS = 1.0;
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct VideoPlayerView {
  context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  xComponentCtrl: XComponentController = new XComponentController();
  navPathStack: NavPathStack = new NavPathStack();
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @State videoPlayerVM: VideoPlayerViewModel = new VideoPlayerViewModel();

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

  aboutToAppear(): void {
    this.videoPlayerVM.setStatusBarColor(this.context, 0xFFFFFF);
  }

  aboutToDisappear(): void {
    this.videoPlayerVM.release();
  }

  build() {
    NavDestination() {
      Stack() {
        XComponent({
          type: XComponentType.SURFACE,
          controller: this.xComponentCtrl,
        })
          .width('100%')
          .height('100%')
          .renderFit(RenderFit.RESIZE_CONTAIN)
          .onLoad(() => {
            let surfaceId = this.xComponentCtrl.getXComponentSurfaceId();
            this.videoPlayerVM.init(this.context, surfaceId);
          });

        AVVolumePanel({
          volumeLevel: this.videoPlayerVM.volumeLevel,
          volumeParameter: {
            position: { x: -100, y: 0 }
          }
        });

        Column() {
          if (this.videoPlayerVM.isSeeking) {
            Row() {
              Text(`${this.timeStr(this.videoPlayerVM.seekTime)} / ${this.timeStr(this.videoPlayerVM.duration)}`)
                .fontSize(12)
                .fontColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#22FFFFFF')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isControlVolume) {
            Row({ space: 6 }) {
              Image(this.videoPlayerVM.volumeLevel === 0 ? $r('app.media.speaker_wave_slash') :
                $r('app.media.speaker_wave'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);

              Slider({
                min: 0,
                max: MAX_VOLUME_LEVEL,
                value: this.videoPlayerVM.volumeLevel,
                style: SliderStyle.NONE,
              })
                .width(100)
                .height(24)
                .trackThickness(2);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#22FFFFFF')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isControlBrightness) {
            Row({ space: 6 }) {
              Image($r('app.media.sun_max'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);

              Slider({
                min: 0,
                max: MAX_WINDOW_BRIGHTNESS,
                value: this.videoPlayerVM.brightness,
                style: SliderStyle.NONE,
              })
                .width(100)
                .height(24)
                .trackThickness(2);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#22FFFFFF')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center);
          } else if (this.videoPlayerVM.isPlaying && this.videoPlayerVM.isSpeeding) {
            Row({ space: 2 }) {
              Image($r('app.media.fast_forward'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.White);
              Text('倍速播放中')
                .fontSize(12)
                .fontColor(Color.White);
            }
            .padding(8)
            .borderRadius(8)
            .backgroundColor('#22FFFFFF')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .margin({ top: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.topRectHeight) });
          }
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(this.videoPlayerVM.isSpeeding ? FlexAlign.Start : FlexAlign.Center);

        Column() {
          Row() {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.back'))
                .width(18)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.videoPlayerVM.setDefaultBrightness(this.context);
              this.videoPlayerVM.setStatusBarColor(this.context, 0x000000);
              if (this.videoPlayerVM.isLandscape) {
                this.videoPlayerVM.setWindowOrientation(this.context, window.Orientation.PORTRAIT);
              }
              this.navPathStack.pop();
            });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.dot_grid_2x2'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              // todo
            });
          }
          .width('100%')
          .padding(16)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween);

          Blank();

          Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceBetween,
          }) {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image(this.videoPlayerVM.isPlaying ? $r('app.media.pause') : $r('app.media.play'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .width(24)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .onClick(async () => {
              if (this.videoPlayerVM.isPlaying) {
                await this.videoPlayerVM.pause();
              } else {
                await this.videoPlayerVM.play();
              }
            });

            Flex({
              direction: FlexDirection.Row,
              alignItems: ItemAlign.Center,
              justifyContent: FlexAlign.SpaceBetween,
            }) {
              Slider({
                min: 0,
                max: this.videoPlayerVM.duration,
                value: this.videoPlayerVM.currTime,
              })
                .height(24)
                .layoutWeight(1)
                .trackColor('#22FFFFFF')
                .blockSize({ width: 12, height: 12 })
                .onChange(async (value: number, mode: SliderChangeMode) => {
                  if (mode === SliderChangeMode.Begin) {
                    this.videoPlayerVM.isSeeking = true;
                  } else if (mode === SliderChangeMode.Moving) {
                    this.videoPlayerVM.seekTime = value;
                  } else {
                    await this.videoPlayerVM.seek(value);
                    this.videoPlayerVM.isSeeking = false;
                  }
                });

              Row() {
                Text(`${this.timeStr(this.videoPlayerVM.currTime)}/${this.timeStr(this.videoPlayerVM.duration)}`)
                  .margin({ left: 3 })
                  .fontSize(10)
                  .fontColor(Color.White);
              }
              .height(24)
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center);
            }
            .padding({ right: 6 });

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image(this.videoPlayerVM.isLandscape ? $r('app.media.portrait') : $r('app.media.landscape'))
                .width(20)
                .aspectRatio(1)
                .fillColor(Color.White);
            }
            .width(24)
            .aspectRatio(1)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.videoPlayerVM.isLandscape) {
                this.videoPlayerVM.setWindowOrientation(this.context, window.Orientation.PORTRAIT);
              } else {
                this.videoPlayerVM.setWindowOrientation(this.context, window.Orientation.LANDSCAPE);
              }
            });
          }
          .width('100%')
          .height(40)
          .padding(16);
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.Transparent)
        .visibility(this.videoPlayerVM.isCtrlPanelShow ? Visibility.Visible : Visibility.Hidden);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .padding({
        top: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.topRectHeight),
        bottom: this.videoPlayerVM.isLandscape ? 16 : this.getUIContext().px2vp(this.bottomRectHeight),
      })
      .onClick(() => {
        this.videoPlayerVM.setControlPanelShow();
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          LongPressGesture({ repeat: false })
            .onAction(() => {
              this.videoPlayerVM.isSpeeding = true;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_3_00_X);
            })
            .onActionEnd(() => {
              this.videoPlayerVM.isSpeeding = false;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
            })
            .onActionCancel(() => {
              this.videoPlayerVM.isSpeeding = false;
              this.videoPlayerVM.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
            }),
          PanGesture({ direction: PanDirection.Horizontal, distance: 20 })
            .onActionStart(() => {
              this.videoPlayerVM.isSeeking = true;
              this.videoPlayerVM.startHorizontalSlide();
            })
            .onActionUpdate((event: GestureEvent) => {
              this.videoPlayerVM.updateHorizontalSlide(event.offsetX);
            })
            .onActionEnd(() => {
              this.videoPlayerVM.isSeeking = false;
              this.videoPlayerVM.endHorizontalSlide();
            })
            .onActionCancel(() => {
              this.videoPlayerVM.isSeeking = false;
              this.videoPlayerVM.endHorizontalSlide();
            }),
          PanGesture({ direction: PanDirection.Vertical, distance: 20 })
            .onActionStart((event: GestureEvent) => {
              let uiContext = this.getUIContext() as UIContext;
              if (event.fingerInfos && event.fingerInfos.length > 0) {
                this.videoPlayerVM.startVerticalSlide(this.context, uiContext, event.fingerInfos[0].globalX);
              }
            })
            .onActionUpdate((event: GestureEvent) => {
              this.videoPlayerVM.updateVerticalSlide(this.context, event.offsetY);
            })
            .onActionEnd(() => {
              this.videoPlayerVM.isControlVolume = false;
              this.videoPlayerVM.isControlBrightness = false;
            })
            .onActionCancel(() => {
              this.videoPlayerVM.isControlVolume = false;
              this.videoPlayerVM.isControlBrightness = false;
            })
        )
      );
    }
    .onBackPressed((): boolean => {
      this.videoPlayerVM.setDefaultBrightness(this.context);
      this.videoPlayerVM.setStatusBarColor(this.context, 0x000000);
      if (this.videoPlayerVM.isLandscape) {
        this.videoPlayerVM.setWindowOrientation(this.context, window.Orientation.PORTRAIT);
      }
      return false;
    })
    .hideBackButton(true)
    .onReady((navContext: NavDestinationContext) => {
      this.navPathStack = navContext.pathStack;
      this.videoPlayerVM.videoInfo = navContext.pathInfo.param as VideoInfoModel;
    });
  }
}