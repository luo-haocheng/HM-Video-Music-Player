import { AddToPlaylistDialog } from './AddToPlaylistDialog';
import { AlbumDialog } from './AlbumDialog';
import { ArtistDialog } from './ArtistDialog';
import { common } from '@kit.AbilityKit';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MAIN_PAGE_STACK = 'MainPageStack';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@CustomDialog
export struct AudioOptionsDialog {
  controller: CustomDialogController;
  @Consume(MAIN_PAGE_STACK) mainPageStack: NavPathStack = new NavPathStack();
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  @Builder
  optionItemBuilder(icon: Resource, text: string) {
    Row({ space: 12 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1);

      Text(text)
        .fontSize(14)
        .fontColor(Color.Black);
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .padding({
      top: 12,
      left: 8,
      right: 8,
      bottom: 12
    });
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        if (this.audioPlayerVM.currAudioItem && this.audioPlayerVM.currAudioItem.albumCover) {
          Image(this.audioPlayerVM.currAudioItem.albumCover)
            .width(48)
            .aspectRatio(1)
            .borderRadius(8);
        } else {
          Image($r('app.media.audio_default'))
            .width(48)
            .aspectRatio(1)
            .borderRadius(8);
        }

        Text(this.audioPlayerVM.currAudioItem?.title)
          .fontSize(12)
          .fontColor(Color.Black);
      }
      .width('100%')
      .layoutWeight(0)
      .margin({ bottom: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center);

      List() {
        ListItem() {
          this.optionItemBuilder($r('app.media.portrait'), `歌手:  ${this.audioPlayerVM.currAudioItem?.artist}`);
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: ArtistDialog({ artist: this.audioPlayerVM.currAudioItem.audioInfo.artist }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.record_circle'), `专辑:  ${this.audioPlayerVM.currAudioItem?.album}`);
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: AlbumDialog({ album: this.audioPlayerVM.currAudioItem.audioInfo.album }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.plus_square'), '添加到歌单');
        }
        .width('100%')
        .onClick(() => {
          this.controller.close();

          if (this.audioPlayerVM.currAudioItem) {
            this.controller = new CustomDialogController({
              width: '100%',
              height: '60%',
              alignment: DialogAlignment.Bottom,
              builder: AddToPlaylistDialog({ audioInfoList: [this.audioPlayerVM.currAudioItem.audioInfo] }),
              offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
            });
            this.controller.open();
          }
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.square_grid_2x2'), '播放器样式');
        }
        .width('100%')
        .onClick(() => {
          // todo
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.rectangle_rotate'), '横屏模式');
        }
        .width('100%')
        .onClick(() => {
          // todo
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.rectangle_and_arrowshape_turn_up_right'), '系统投播');
        }
        .width('100%')
        .onClick(() => {
          // todo
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.share'), '系统分享');
        }
        .width('100%')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.audioPlayerVM.shareAudio(context);
          this.controller.close();
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.timer'), '定时关闭');
        }
        .width('100%')
        .onClick(() => {
          // todo
        });

        ListItem() {
          this.optionItemBuilder($r('app.media.fast_forward'), '播放倍速');
        }
        .width('100%')
        .onClick(() => {
          // todo
        });
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off);
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}