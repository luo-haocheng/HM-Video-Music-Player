import { AudioPlayListViewModel } from '../viewmodel/AudioPlayListViewModel';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';
import { PlayListItemViewModel, PlayListItemViewModelArray } from './PlayListItemViewModel';
import { emitter } from '@kit.BasicServicesKit';
import { PlayListInfoModel } from '../model/PlayListInfoModel';
import { AudioInfoModel } from '../model/AudioInfoModel';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const PLAYLIST_PATH_STACK = 'PlayListPathStack';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const CREATE_PLAYLIST_EVENT = 'CreatePlaylist';

@Component
export struct AudioPlayListView {
  @State audioPlaylistVM: AudioPlayListViewModel = new AudioPlayListViewModel();
  private createPlaylistCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const playlistInfo = eventData.data['info'] as PlayListInfoModel;
      this.audioPlaylistVM.updatePlayList(playlistInfo);
    }
  };
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioPlaylistVM.updateAudio(audioInfo);
    }
  };

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext() as Context;
    this.audioPlaylistVM.init(context);
    emitter.on(CREATE_PLAYLIST_EVENT, this.createPlaylistCallback);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  aboutToDisappear(): void {
    emitter.off(CREATE_PLAYLIST_EVENT, this.createPlaylistCallback);
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
  }

  build() {
    ListView({
      allPlaylist: this.audioPlaylistVM.allPlaylist,
      favoritePlaylist: this.audioPlaylistVM.favoritePlaylist,
      userPlaylistArray: this.audioPlaylistVM.userPlaylistArray,
    });
  }
}

@Component
struct ListView {
  @ObjectLink allPlaylist: PlayListItemViewModel;
  @ObjectLink favoritePlaylist: PlayListItemViewModel;
  @ObjectLink userPlaylistArray: PlayListItemViewModelArray;
  @Consume(PLAYLIST_PATH_STACK) playListStack: NavPathStack = new NavPathStack();

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        ListItem() {
          PlayListBoxView({ playlistVM: this.allPlaylist });
        }
        .onClick(() => {
          const audioListInfo: AudioListInfo = {
            type: AudioListType.PLAY_LIST,
            name: ALL_AUDIO
          };
          this.playListStack.pushPath({ name: 'AudioList', param: audioListInfo });
        });

        ListItem() {
          PlayListBoxView({ playlistVM: this.favoritePlaylist });
        }
        .onClick(() => {
          const audioListInfo: AudioListInfo = {
            type: AudioListType.PLAY_LIST,
            name: FAVORITE_AUDIO
          };
          this.playListStack.pushPath({ name: 'AudioList', param: audioListInfo });
        });

        ForEach(
          this.userPlaylistArray,
          (item: PlayListItemViewModel) => {
            ListItem() {
              PlayListBoxView({ playlistVM: item })
                .onClick(() => {
                  const audioListInfo: AudioListInfo = {
                    type: AudioListType.PLAY_LIST,
                    name: item.playListName
                  };
                  this.playListStack.pushPath({ name: 'AudioList', param: audioListInfo });
                });
            };
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