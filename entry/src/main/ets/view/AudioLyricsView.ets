@Component
export struct AudioLyricsView {
  build() {
    Column() {
      Text('暂无歌词')
        .fontSize(32)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold);
    }
    .padding(32)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}