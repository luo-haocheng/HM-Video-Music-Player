import { AudioArtistListViewModel } from '../viewmodel/AudioArtistListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from '../viewmodel/PlayListItemViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from '../model/AudioInfoModel';


const IMPORT_AUDIO_EVENT = 'ImportAudio';
const ARTISTLIST_PATH_STACK = 'ArtistListPathStack';

@Component
export struct AudioArtistListView {
  @State audioArtistListVM: AudioArtistListViewModel = new AudioArtistListViewModel();
  @Consume(ARTISTLIST_PATH_STACK) artistListStack: NavPathStack = new NavPathStack();
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioArtistListVM.updateAudio(audioInfo);
    }
  };

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioArtistListVM.init(context);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  async aboutToDisappear(): Promise<void> {
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  build() {
    ListView({ unknownArtist: this.audioArtistListVM.unknownArtist, artistList: this.audioArtistListVM.artistList });
  }
}

@Component
struct ListView {
  @ObjectLink artistList: PlayListItemViewModelArray;
  @ObjectLink unknownArtist: PlayListItemViewModel | undefined;
  @Consume(ARTISTLIST_PATH_STACK) artistListStack: NavPathStack = new NavPathStack();

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        if (this.unknownArtist) {
          ListItem() {
            PlayListBoxView({ playlistVM: this.unknownArtist })
              .onClick(() => {
                const audioListInfo: AudioListInfo = {
                  type: AudioListType.ARTIST_LIST,
                  name: null
                };
                this.artistListStack.pushPath({ name: 'AudioList', param: audioListInfo });
              });
          };
        }

        ForEach(
          this.artistList,
          (item: PlayListItemViewModel) => {
            ListItem() {
              PlayListBoxView({ playlistVM: item })
                .onClick(() => {
                  const audioListInfo: AudioListInfo = {
                    type: AudioListType.ARTIST_LIST,
                    name: item.playListName
                  };
                  this.artistListStack.pushPath({ name: 'AudioList', param: audioListInfo });
                });
            };
          },
          (item: string, index: number) => {
            index;
            return item;
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