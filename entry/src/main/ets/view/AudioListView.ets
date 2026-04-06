import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioItemViewModelList, AudioListViewModel } from '../viewmodel/AudioListViewModel';
import { AudioBoxView } from './AudioBoxView';
import { emitter } from '@kit.BasicServicesKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioPlayerViewModel } from '../viewmodel/AudioPlayerViewModel';
import { AddToPlaylistDialog } from './AddToPlaylistDialog';

const ALL_AUDIO = '*';
const AUDIO_LIST_INFO = 'AudioListInfo';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const AUDIO_PLAYER_VM = 'AudioPlayerVM';
const MULTI_CHOICE = 'MultiChoice';
const CHOICE_ALL = 'ChoiceAll';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const IMPORT_AUDIO_EVENT = 'ImportAudio';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const ADD_PLAYLIST_CHOICE_EVENT = 'AddPlaylistChoice';
const DELETE_PLAYLIST_CHOICE_EVENT = 'DeletePlaylistChoice';

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
  @Consume(CHOICE_ALL) choiceAll: boolean = true;
  @Consume(AUDIO_LIST_INFO) currAudioList?: AudioListInfo = undefined;
  private addPlaylistDialogController?: CustomDialogController;
  private importAudioCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    if (eventData.data) {
      const audioInfo = eventData.data['info'] as AudioInfoModel;
      this.audioListVM.updateAudio(audioInfo);
    }
  };
  private choiceAllCallback: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    eventData;
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      item.isChoice = this.choiceAll;
    });
    this.choiceAll = !this.choiceAll;
  };
  private deleteChoiceCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    for (let i = 0; i < choiceAudioArr.length; ++i) {
      await this.audioListVM.deleteAudio(choiceAudioArr[i]);
    }
  };
  private addToPlaylistCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    this.addPlaylistDialogController = new CustomDialogController({
      width: '100%',
      height: '60%',
      alignment: DialogAlignment.Bottom,
      builder: AddToPlaylistDialog({ audioInfoList: choiceAudioArr }),
      offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
    });
    this.addPlaylistDialogController.open();
  };
  private deleteFromPlaylistCallback: Callback<emitter.EventData> = async (eventData: emitter.EventData) => {
    eventData;
    const choiceAudioArr: AudioInfoModel[] = [];
    this.audioListVM.audioList.forEach((item: AudioItemViewModel) => {
      if (item.isChoice) {
        choiceAudioArr.push(item.audioInfo);
      }
    });
    for (let i = 0; i < choiceAudioArr.length; ++i) {
      this.audioListVM.deleteFromPlaylist(choiceAudioArr[i]);
    }
  };

  aboutToAppear(): void {
    emitter.on(DELETE_PLAYLIST_CHOICE_EVENT, this.deleteFromPlaylistCallback);
    emitter.on(ADD_PLAYLIST_CHOICE_EVENT, this.addToPlaylistCallback);
    emitter.on(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.on(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.on(CHOICE_ALL_EVENT, this.choiceAllCallback);
  }

  aboutToDisappear(): void {
    emitter.off(DELETE_PLAYLIST_CHOICE_EVENT, this.deleteFromPlaylistCallback);
    emitter.off(ADD_PLAYLIST_CHOICE_EVENT, this.addToPlaylistCallback);
    emitter.off(DELETE_CHOICE_EVENT, this.deleteChoiceCallback);
    emitter.off(IMPORT_AUDIO_EVENT, this.importAudioCallback);
    emitter.off(CHOICE_ALL_EVENT, this.choiceAllCallback);
  }

  build() {
    NavDestination() {
      ListView({ audioListVM: this.audioListVM, audioList: this.audioListVM.audioList });
    }
    .hideBackButton(true)
    .onWillDisappear(() => {
      this.currAudioList = undefined;
    })
    .onReady(async (navDesContext: NavDestinationContext) => {
      let context = this.getUIContext().getHostContext() as Context;
      await this.audioListVM.init(context);
      if (navDesContext.pathInfo.param) {
        this.audioListVM.audioListInfo = navDesContext.pathInfo.param as AudioListInfo;
        this.currAudioList = this.audioListVM.audioListInfo;
        this.audioListVM.loadAudioList();
      }
    });
  }
}

@Component
struct ListView {
  @Link audioListVM: AudioListViewModel;
  @ObjectLink audioList: AudioItemViewModelList;
  @Consume(MULTI_CHOICE) multiChoice: boolean = false;
  @Consume(CHOICE_ALL) choiceAll: boolean = true;
  @Consume(AUDIO_PLAYER_VM) audioPlayerVM: AudioPlayerViewModel = new AudioPlayerViewModel();
  private selectedIdx: number = -1;
  private addPlaylistDialogController?: CustomDialogController;
  private isAllChoice: Callback<void> = () => {
    const choiceAll = this.audioListVM.audioList.find((item: AudioItemViewModel) => {
      return !item.isChoice;
    });
    this.choiceAll = (choiceAll !== undefined);
  };

  @Builder
  longPressMenuBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center,
    }) {
      Row() {
        Text('添加到歌单')
          .fontSize(14)
          .fontColor(Color.Black);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.addPlaylistDialogController = new CustomDialogController({
          width: '100%',
          height: '60%',
          alignment: DialogAlignment.Bottom,
          builder: AddToPlaylistDialog({ audioInfoList: [this.audioList[this.selectedIdx].audioInfo] }),
          offset: { dx: 0, dy: this.getUIContext().px2vp(AppStorage.get(BOTTOM_RECT_HEIGHT)) }
        });
        this.addPlaylistDialogController.open();
      });

      Divider()
        .vertical(false)
        .strokeWidth(0.5);

      if (this.audioListVM.audioListInfo.type === AudioListType.PLAY_LIST &&
        this.audioListVM.audioListInfo.name !== ALL_AUDIO) {
        Row() {
          Text('从歌单中移除')
            .fontSize(14)
            .fontColor(Color.Black);
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .onClick(() => {
          this.audioListVM.deleteFromPlaylist(this.audioList[this.selectedIdx].audioInfo);
        });

        Divider()
          .vertical(false)
          .strokeWidth(0.5);
      }

      Row() {
        Text('删除')
          .fontSize(14)
          .fontColor(Color.Red);
      }
      .width('100%')
      .padding({ top: 16, bottom: 16 })
      .onClick(() => {
        this.audioListVM.deleteAudio(this.audioList[this.selectedIdx].audioInfo);
      });
    }
    .width(160)
    .padding({ left: 16, right: 16 });
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      List() {
        ForEach(
          this.audioList,
          (item: AudioItemViewModel, index: number) => {
            ListItem() {
              AudioBoxView({ audioItem: item, isAllChoice: this.isAllChoice });
            }
            .bindContextMenu(
              this.longPressMenuBuilder,
              ResponseType.LongPress,
              {
                previewBorderRadius: 12,
                placement: Placement.Bottom,
                preview: MenuPreviewMode.IMAGE,
                aboutToAppear: () => {
                  this.selectedIdx = index;
                }
              })
            .onClick(() => {
              if (this.multiChoice) {
                item.isChoice = !item.isChoice;
              } else {
                const context = this.getUIContext().getHostContext() as Context;
                this.audioPlayerVM.init(item.audioInfo, context);
                this.audioPlayerVM.audioList = this.audioList;
                this.audioPlayerVM.currIndex = index;
              }
            });
          },
          (item: AudioItemViewModel, index: number) => {
            index;
            return item.audioInfo.id.toString();
          }
        );
      }
      .width('100%')
      .height('100%')
      .contentStartOffset(8)
      .contentEndOffset(60 + 8)
      .scrollBar(BarState.Off)
      .padding({ left: 8, right: 8 })
      .backgroundColor(`rgb(243, 243, 243)`)
      .divider({ strokeWidth: 8, color: 'rgb(243, 243, 243)' });
    }
    .width('100%')
    .height('100%');
  }
}