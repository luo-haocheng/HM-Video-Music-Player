import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioBoxView } from './AudioBoxView';

@Builder
export function AudioListBuilder() {
  AudioListView();
}

@Component
export struct AudioListView {
  @State audioList: AudioItemViewModel[] = [];
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  build() {
    NavDestination() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Start,
        alignItems: ItemAlign.Center
      }) {
        List() {
          ForEach(
            this.audioList,
            (item: AudioItemViewModel) => {
              ListItem() {
                AudioBoxView({
                  audioItem: item
                });
              };
            },
            (item: AudioItemViewModel, index: number) => {
              index;
              return item.audioInfo.id.toString();
            }
          );
        }
        .width('100%')
        .height('100%')
        .contentEndOffset(8)
        .contentStartOffset(8)
        .scrollBar(BarState.Off)
        .padding({ left: 8, right: 8 })
        .backgroundColor(`rgb(243, 243, 243)`)
        .divider({ strokeWidth: 8, color: 'rgb(243, 243, 243)' });
      }
      .width('100%')
      .height('100%');
    }
    .hideBackButton(true)
    .onReady(async (navContext: NavDestinationContext) => {
      let context = this.getUIContext().getHostContext() as Context;
      await this.audioStore.initStore(context);
      if (navContext.pathInfo.param) {
        const playlistName = navContext.pathInfo.param;
        const audioInfoList = await this.audioStore.selectAudioByPlayList(playlistName as string);
        for (let i = 0; i < audioInfoList.length; ++i) {
          let audioItem = new AudioItemViewModel();
          audioItem.updateAudioItem(audioInfoList[i]);
          this.audioList.push(audioItem);
        }
      }
    });
  }
}