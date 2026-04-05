import { AudioInfoModel } from '../model/AudioInfoModel';
import { AddToPlaylistViewModel } from '../viewmodel/AddToPlaylistViewModel';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../viewmodel/PlayListItemViewModel';

@CustomDialog
export struct AddToPlaylistDialog {
  public controller: CustomDialogController;
  public audioInfoList: AudioInfoModel[] = [];
  @State addToPlaylistVM: AddToPlaylistViewModel = new AddToPlaylistViewModel();

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as Context;
    await this.addToPlaylistVM.init(context);
  }

  build() {
    Column() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center,
      }) {
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.xmark'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .padding(8)
          .backgroundColor('#AADCDCDC')
          .onClick(() => {
            this.controller.close();
          });

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.checkmark'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .padding(8)
          .backgroundColor('#AADCDCDC')
          .onClick(async () => {
            for (let i = 0; i < this.audioInfoList.length; ++i) {
              await this.addToPlaylistVM.addToPlaylist(this.audioInfoList[i]);
            }
            this.controller.close();
          });
        }
        .width('100%')
        .layoutWeight(0)
        .margin({ bottom: 8 })
        .justifyContent(FlexAlign.SpaceBetween);

        ListView({
          favoritePlaylist: this.addToPlaylistVM.favoritePlaylist,
          userPlaylistArray: this.addToPlaylistVM.userPlaylistArray
        })
          .layoutWeight(1);
      }
      .padding(16)
      .width('100%')
      .height('100%')
      .backgroundColor('#FFF1F3F5');
    };
  }
}

@Component
struct playlistBox {
  @ObjectLink playlistItem: PlayListItemViewModel;

  build() {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Column() {
        Text(this.playlistItem.playListName)
          .maxLines(1)
          .fontSize(14)
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Bold)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Text(`${this.playlistItem.playListCount}个内容`)
          .fontSize(12)
          .fontColor(Color.Gray);
      }
      .height('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceAround);

      Column() {
        Checkbox()
          .width(18)
          .aspectRatio(1)
          .select($$this.playlistItem.isChoice);
      }
      .height('100%')
      .layoutWeight(0)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    }
    .padding(8)
    .height(60)
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(() => {
      this.playlistItem.isChoice = !this.playlistItem.isChoice;
    });
  }
}

@Component
struct ListView {
  @ObjectLink favoritePlaylist: PlayListItemViewModel;
  @ObjectLink userPlaylistArray: PlayListItemViewModelArray;

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        ListItem() {
          playlistBox({ playlistItem: this.favoritePlaylist });
        };

        ForEach(
          this.userPlaylistArray,
          (item: PlayListItemViewModel) => {
            ListItem() {
              playlistBox({ playlistItem: item });
            };
          }
        );
      }
      .width('100%')
      .borderRadius(12)
      .contentEndOffset(8)
      .contentStartOffset(8)
      .scrollBar(BarState.Off)
      .backgroundColor(Color.White)
      .divider({
        startMargin: 8,
        endMargin: 8,
        strokeWidth: 1,
        color: '#33182431'
      });
    }
    .width('100%');
  }
}