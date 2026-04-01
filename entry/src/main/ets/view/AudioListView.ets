import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList, AudioListViewModel } from '../viewmodel/AudioListViewModel';
import { AudioBoxView } from './AudioBoxView';

export enum AudioListType {
  PLAY_LIST = 'PlayList',
  ALNUM_LIST = 'AlbumList',
  ARTIST_LIST = 'ArtistList',
}

export class AudioListInfo {
  type: AudioListType = AudioListType.PLAY_LIST;
  name: string | null = null;
}

@Builder
export function AudioListBuilder() {
  AudioListView();
}

@Component
export struct AudioListView {
  @State audioListVM: AudioListViewModel = new AudioListViewModel();
  private audioListInfo: AudioListInfo = new AudioListInfo();

  build() {
    NavDestination() {
      ListView({ audioList: this.audioListVM.audioList });
    }
    .hideBackButton(true)
    .onReady(async (navDesContext: NavDestinationContext) => {
      let context = this.getUIContext().getHostContext() as Context;
      await this.audioListVM.init(context);
      if (navDesContext.pathInfo.param) {
        this.audioListInfo = navDesContext.pathInfo.param as AudioListInfo;
        this.audioListVM.loadAudioList(this.audioListInfo);
      }
    });
  }
}

@Component
struct ListView {
  @ObjectLink audioList: AudioItemViewModelList;

  build() {
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
}