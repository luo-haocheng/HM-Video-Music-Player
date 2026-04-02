import { AudioAlbumListViewModel } from '../viewmodel/AudioAlbumListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from '../model/AudioInfoModel';

const IMPORT_AUDIO_EVENT = 'ImportAudio';
const ALBUMLIST_PATH_STACK = 'AlbumListPathStack';

@Component
export struct AudioAlbumListView {
  @State audioAlbumListVM: AudioAlbumListViewModel = new AudioAlbumListViewModel();
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioAlbumListVM.updateAudio(audioInfo);
    }
  };

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioAlbumListVM.init(context);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  async aboutToDisappear(): Promise<void> {
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  build() {
    ListView({ unknownAlbum: this.audioAlbumListVM.unknownAlbum, albumList: this.audioAlbumListVM.albumList });
  }
}

@Component
struct ListView {
  @ObjectLink albumList: PlayListItemViewModelArray;
  @ObjectLink unknownAlbum: PlayListItemViewModel | undefined;
  @Consume(ALBUMLIST_PATH_STACK) albumListStack: NavPathStack = new NavPathStack();

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        if (this.unknownAlbum) {
          ListItem() {
            PlayListBoxView({ playlistVM: this.unknownAlbum })
              .onClick(() => {
                const audioListInfo: AudioListInfo = {
                  type: AudioListType.ALNUM_LIST,
                  name: null
                };
                this.albumListStack.pushPath({ name: 'AudioList', param: audioListInfo });
              });
          };
        }

        ForEach(
          this.albumList,
          (item: PlayListItemViewModel) => {
            ListItem() {
              PlayListBoxView({ playlistVM: item })
                .onClick(() => {
                  const audioListInfo: AudioListInfo = {
                    type: AudioListType.ALNUM_LIST,
                    name: item.playListName
                  };
                  this.albumListStack.pushPath({ name: 'AudioList', param: audioListInfo });
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