import { AudioArtistListViewModel } from '../viewmodel/AudioArtistListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';

const ARTISTLIST_PATH_STACK = 'ArtistListPathStack';

@Component
export struct AudioArtistListView {
  @State audioArtistVM: AudioArtistListViewModel = new AudioArtistListViewModel();
  @Consume(ARTISTLIST_PATH_STACK) artistListStack: NavPathStack = new NavPathStack();

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioArtistVM.init(context);
  }

  build() {
    ListView({ unknownArtist: this.audioArtistVM.unknownArtist, artistList: this.audioArtistVM.artistList });
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