import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList, AudioListViewModel } from '../viewmodel/AudioListViewModel';
import { AudioBoxView } from './AudioBoxView';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from '../model/AudioInfoModel';

const IMPORT_AUDIO_EVENT = 'ImportAudio';

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
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioListVM.updateAudio(audioInfo);
    }
  };

  aboutToAppear(): void {
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  aboutToDisappear(): void {
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  build() {
    NavDestination() {
      ListView({ audioListVM: this.audioListVM, audioList: this.audioListVM.audioList });
    }
    .hideBackButton(true)
    .onReady(async (navDesContext: NavDestinationContext) => {
      let context = this.getUIContext().getHostContext() as Context;
      await this.audioListVM.init(context);
      if (navDesContext.pathInfo.param) {
        this.audioListVM.audioListInfo = navDesContext.pathInfo.param as AudioListInfo;
        this.audioListVM.loadAudioList();
      }
    });
  }
}

@Component
struct ListView {
  @Link audioListVM: AudioListViewModel;
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
                audioItem: item,
                audioListVM: this.audioListVM,
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