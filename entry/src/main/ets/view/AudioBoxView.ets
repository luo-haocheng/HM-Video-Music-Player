import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { LengthMetrics } from '@kit.ArkUI';
import { AudioListType } from './AudioListView';
import { AudioListViewModel } from '../viewmodel/AudioListViewModel';
import { AddToPlaylistDialog } from './AddToPlaylistDialog';

const ALL_AUDIO = '*';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Component
export struct AudioBoxView {
  @Link audioListVM: AudioListViewModel;
  @ObjectLink audioItem: AudioItemViewModel;
  private addPlaylistDialogController?: CustomDialogController;

  @Builder
  longPressMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('添加到歌单')
          .fontSize(16)
          .fontColor(Color.Black);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        setTimeout(() => {
          this.addPlaylistDialogController = new CustomDialogController({
            width: '100%',
            height: '60%',
            alignment: DialogAlignment.Bottom,
            builder: AddToPlaylistDialog({ audioInfoList: [this.audioItem.audioInfo] }),
            offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
          });
          this.addPlaylistDialogController.open();
        }, 500);
      });

      Divider()
        .vertical(false)
        .strokeWidth(0.5);

      if (this.audioListVM.audioListInfo.type === AudioListType.PLAY_LIST &&
        this.audioListVM.audioListInfo.name !== ALL_AUDIO) {
        Row() {
          Text('从歌单中移除')
            .fontSize(16)
            .fontColor(Color.Black);
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .onClick(() => {
          this.audioListVM.deleteFromPlaylist(this.audioItem.audioInfo);
        });

        Divider()
          .vertical(false)
          .strokeWidth(0.5);
      }

      Row() {
        Text('删除')
          .fontSize(16)
          .fontColor(Color.Red);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.audioListVM.deleteAudio(this.audioItem.audioInfo);
      });
    }
    .width(160)
    .padding({ left: 16, right: 16 });
  }

  build() {
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
            .fontColor(Color.Black)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Row() {
            Text(this.audioItem.artist)
              .fontSize(12)
              .fontColor(Color.Gray);
            Text(' · ')
              .fontSize(12)
              .fontColor(Color.Black);
            Text(this.audioItem.album)
              .fontSize(12)
              .fontColor(Color.Gray);
          };
        }
        .height('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceAround);
      }
      .layoutWeight(1);
    }
    .padding(8)
    .height(80)
    .width('100%')
    .borderRadius(12)
    .backgroundColor(Color.White)
    .bindContextMenu(
      this.longPressMenuBuilder,
      ResponseType.LongPress,
      {
        placement: Placement.Bottom,
        preview: MenuPreviewMode.IMAGE
      });
  }
}