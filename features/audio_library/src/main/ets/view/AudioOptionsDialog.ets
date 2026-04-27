@CustomDialog
export struct AudioOptionsDialog {
  controller: CustomDialogController;

  build() {
    Column() {
      Text('Audio Options')
        .fontSize(30)
        .fontColor(Color.Black);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}