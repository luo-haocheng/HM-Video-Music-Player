import { AudioEditViewModel } from '../viewmodel/AudioEditViewModel';
import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';

@CustomDialog
export struct AudioEditDialog {
  @State audioEditVM: AudioEditViewModel = new AudioEditViewModel();
  public audioItem: AudioItemViewModel = new AudioItemViewModel();
  public scroller: Scroller = new Scroller();
  public controller: CustomDialogController;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as Context;
    this.audioEditVM.init(context, this.audioItem.audioInfo.lyricsPath);
  }

  build() {
    Scroll(this.scroller) {
      Column({ space: 24 }) {
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
        .width('50%')
        .aspectRatio(1)
        .layoutWeight(0)
        .borderRadius(12)
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center);

        Column() {
          Text('标题')
            .fontSize(14)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);
          TextInput({ text: this.audioItem.title })
            .fontSize(14)
            .maxLength(100)
            .showUnderline(true)
            .underlineColor(Color.Gray)
            .placeholderFont({ size: 14 })
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(Color.Transparent);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start);

        Column() {
          Text('专辑')
            .fontSize(14)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);
          TextInput({ text: this.audioItem.album })
            .fontSize(14)
            .maxLength(100)
            .showUnderline(true)
            .underlineColor(Color.Gray)
            .placeholderFont({ size: 14 })
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(Color.Transparent);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start);

        Column() {
          Text('艺术家')
            .fontSize(14)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);
          TextInput({ text: this.audioItem.artist })
            .fontSize(14)
            .maxLength(100)
            .showUnderline(true)
            .underlineColor(Color.Gray)
            .placeholderFont({ size: 14 })
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(Color.Transparent);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start);

        Column({ space: 8 }) {
          Text('歌词')
            .fontSize(14)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold);

          Stack({ alignContent: Alignment.TopEnd }) {
            TextArea({ text: $$this.audioEditVM.lyrics })
              .height('100%')
              .fontSize(14)
              .borderWidth('1px')
              .borderColor(Color.Gray)
              .placeholderFont({ size: 14 })
              .backgroundColor(Color.Transparent);

            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.plus'))
                .width(18)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .padding(6)
            .offset({ x: -8, y: 8 })
            .backgroundColor('#55F1F3F5')
            .onClick(() => {
              const context = this.getUIContext().getHostContext() as Context;
              this.audioEditVM.selectLyricsFile(context, this.audioItem.audioInfo);
            });
          }
          .width('100%')
          .height(200);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center);
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#DCDCDC')
    .scrollBar(BarState.Off)
    .scrollable(ScrollDirection.Vertical);
  }
}