import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AudioLyricsView } from './AudioLyricsView';
import { AudioPlayerView } from './AudioPlayerView';

const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';

@Builder
export function AudioImmersiveBuilder() {
  AudioImmersiveView();
}

@Component
export struct AudioImmersiveView {
  @State selectedIdx: number = 0;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();

  @Builder
  playerTabBarBuilder() {
    Row() {
      if (this.selectedIdx === 0) {
        Row()
          .width(10)
          .height(5)
          .borderRadius('50%')
          .backgroundColor(Color.Gray);
      } else {
        Circle({ width: 5, height: 5 })
          .fill(Color.Gray)
          .fillOpacity(0.5);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ right: 3 })
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  lyricsTabBarBuilder() {
    Row() {
      if (this.selectedIdx === 1) {
        Row()
          .width(10)
          .height(5)
          .borderRadius('50%')
          .backgroundColor(Color.Gray);
      } else {
        Circle({ width: 5, height: 5 })
          .fill(Color.Gray)
          .fillOpacity(0.5);
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 3 })
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center);
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          AudioPlayerView();
        }
        .tabBar(this.playerTabBarBuilder());

        TabContent() {
          AudioLyricsView();
        }
        .tabBar(this.lyricsTabBarBuilder());
      }
      .barHeight(32)
      .onSelected((index: number) => {
        this.selectedIdx = index;
      });
    }
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .backgroundColor('#DCDCDC')
    .hideBackButton(true);
  }
}