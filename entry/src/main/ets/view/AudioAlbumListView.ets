import { media } from '@kit.MediaKit';
import { AudioInfoModel } from '../model/AudioInfoModel';
import { AudioLibraryStore } from '../model/AudioLibraryStore';
import { PlayListBoxView } from './PlayListBoxView';

@Component
export struct AudioAlbumListView {
  @State albumList: string[] = [];
  private albumMap: Map<string, AudioInfoModel[]> = new Map();
  private audioStore: AudioLibraryStore = new AudioLibraryStore();

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioStore.initStore(context);

    let audioInfoList = await this.audioStore.selectAllAudio();
    for (let i = 0; i < audioInfoList.length; ++i) {
      let album: string = '';
      let metadataStr = audioInfoList[i].metadata;
      if (metadataStr) {
        let metadata = JSON.parse(metadataStr) as media.AVMetadata;
        album = metadata.album ? metadata.album : '未知专辑';
      }
      if (this.albumMap.has(album)) {
        this.albumMap.get(album)?.push(audioInfoList[i]);
      } else {
        this.albumMap.set(album, [audioInfoList[i]]);
      }
    }
    for (let album of this.albumMap.keys()) {
      this.albumList.push(album);
    }
  }

  build() {
    List() {
      ForEach(
        this.albumList,
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