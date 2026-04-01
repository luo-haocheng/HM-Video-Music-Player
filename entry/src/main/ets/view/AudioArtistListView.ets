import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';

const ARTISTLIST_PATH_STACK = 'ArtistListPathStack';

@Component
export struct AudioArtistListView {
  @State artistList: (string | null)[] = [];
  @Consume(ARTISTLIST_PATH_STACK) artistListStack: NavPathStack = new NavPathStack();
  private artistMap: Map<string | null, AudioInfoModel[]> = new Map();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioStore.initStore(context);

    let audioInfoList = await this.audioStore.selectAllAudio();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let artist: string | null = audioInfoList[i].artist;
      if (this.artistMap.has(artist)) {
        this.artistMap.get(artist)?.push(audioInfoList[i]);
      } else {
        this.artistMap.set(artist, [audioInfoList[i]]);
      }
    }
    this.artistList = Array.from(this.artistMap.keys());
  }

  build() {
    List() {
      ForEach(
        this.artistList,
        (item: string) => {
          PlayListBoxView({ playListName: item })
            .onClick(() => {
              const audioListInfo: AudioListInfo = {
                type: AudioListType.ARTIST_LIST,
                name: item
              };
              this.artistListStack.pushPath({ name: 'AudioList', param: audioListInfo });
            });
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
}