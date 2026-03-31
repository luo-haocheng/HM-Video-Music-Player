import { media } from '@kit.MediaKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListBoxView } from './PlayListBoxView';

@Component
export struct AudioArtistListView {
  @State artistList: string[] = [];
  private artistMap: Map<string, AudioInfoModel[]> = new Map();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioStore.initStore(context);

    let audioInfoList = await this.audioStore.selectAllAudio();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let artist: string = '';
      let metadataStr = audioInfoList[i].metadata;
      if (metadataStr) {
        let metadata = JSON.parse(metadataStr) as media.AVMetadata;
        artist = metadata.artist ? metadata.artist : '未知艺术家';
      }
      if (this.artistMap.has(artist)) {
        this.artistMap.get(artist)?.push(audioInfoList[i]);
      } else {
        this.artistMap.set(artist, [audioInfoList[i]]);
      }
    }
    for (let artist of this.artistMap.keys()) {
      this.artistList.push(artist);
    }
  }

  build() {
    List() {
      ForEach(
        this.artistList,
        (item: string) => {
          PlayListBoxView({ playListName: item });
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