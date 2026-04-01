import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { AudioListInfo, AudioListType } from './AudioListView';
import { PlayListBoxView } from './PlayListBoxView';

const ALBUMLIST_PATH_STACK = 'AlbumListPathStack';

@Component
export struct AudioAlbumListView {
  @State albumList: (string | null)[] = [];
  @Consume(ALBUMLIST_PATH_STACK) albumListStack: NavPathStack = new NavPathStack();
  private albumMap: Map<string | null, AudioInfoModel[]> = new Map();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioStore.initStore(context);

    let audioInfoList = await this.audioStore.selectAllAudio();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let album: string | null = audioInfoList[i].album;
      if (this.albumMap.has(album)) {
        this.albumMap.get(album)?.push(audioInfoList[i]);
      } else {
        this.albumMap.set(album, [audioInfoList[i]]);
      }
    }
    this.albumList = Array.from(this.albumMap.keys());
  }

  build() {
    List() {
      ForEach(
        this.albumList,
        (item: string | null) => {
          PlayListBoxView({ playListName: item === null ? '未知专辑' : item })
            .onClick(() => {
              const audioListInfo: AudioListInfo = {
                type: AudioListType.ALNUM_LIST,
                name: item
              };
              this.albumListStack.pushPath({ name: 'AudioList', param: audioListInfo });
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