import { LyricsInfo } from '../model/LyricsInfoModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { LengthMetrics } from '@kit.ArkUI';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';

@Component
export struct AudioLyricsView {
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  build() {
    Column({ space: 24 }) {
      Column({ space: 5 }) {
        Text(this.audioPlayerVM.currAudioItem?.title)
          .fontSize(24)
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Bold);
        Text(this.audioPlayerVM.currAudioItem?.artist)
          .fontSize(14)
          .fontColor(Color.Black);
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center);

      if (this.audioPlayerVM.lyricsInfoArr.length === 0) {
        Text('暂无歌词')
          .fontSize(32)
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1);
      } else {
        List({ space: 16, scroller: this.audioPlayerVM.lyricsScroller }) {
          ForEach(
            this.audioPlayerVM.lyricsInfoArr,
            (lyrics: LyricsInfo, index: number) => {
              ListItem() {
                Row() {
                  Text(lyrics.text)
                    .fontSize(this.audioPlayerVM.currLyricsIdx === index ? 18 : 14)
                    .fontColor(this.audioPlayerVM.currLyricsIdx === index ? Color.Black : Color.Gray);
                }
                .width('100%')
                .justifyContent(FlexAlign.Center);
              };
            }
          );

          ListItem() {
            // Nothing
          }
          .width('100%')
          .height('50%')
          .backgroundColor(Color.Transparent);
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(24) })
        .layoutWeight(1);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}