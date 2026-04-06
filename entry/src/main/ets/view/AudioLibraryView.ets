import { AudioItemViewModel } from '../viewmodel/AudioItemViewModel';
import { AudioLibraryViewModel } from '../viewmodel/AudioLibraryViewModel';
import { AudioAlbumListView } from './AudioAlbumListView';
import { AudioArtistListView } from './AudioArtistListView';
import { AudioBottomBar } from './AudioBottomBar';
import { AudioListInfo, AudioListType } from './AudioListView';
import { AudioPlayListView } from './AudioPlayListView';

const ALL_AUDIO = '*';
const FAVORITE_AUDIO = '**';
const INVALID_VALUES = '/\\:*?"<>|';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const AUDIO_LIST_INFO = 'AudioListInfo';
const PLAYLIST_PATH_STACK = 'PlayListPathStack';
const ALBUMLIST_PATH_STACK = 'AlbumListPathStack';
const ARTISTLIST_PATH_STACK = 'ArtistListPathStack';
const IMPORT_OPTS: ImportOption[] = [
  { icon: $r('app.media.plus'), text: '新建歌单', color: Color.Green },
  { icon: $r('app.media.music'), text: '音频文件导入', color: Color.Blue },
  { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
  { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
  { icon: $r('app.media.question_circle'), text: '导入疑问', color: Color.Gray },
];

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Component
export struct AudioLibraryView {
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  @Provide(AUDIO_LIST_INFO) currAudioList?: AudioListInfo = undefined;
  @Provide(PLAYLIST_PATH_STACK) playListStack: NavPathStack = new NavPathStack();
  @Provide(ALBUMLIST_PATH_STACK) albumListStack: NavPathStack = new NavPathStack();
  @Provide(ARTISTLIST_PATH_STACK) artistListStack: NavPathStack = new NavPathStack();
  @State invalidName: boolean = false;
  @State audioList: AudioItemViewModel[] = [];
  @State audioLibVM: AudioLibraryViewModel = new AudioLibraryViewModel();
  private newPlaylistName?: string;
  private importDialogId: number = -1;
  private createPlaylistDialogId: number = 0;

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as Context;
    await this.audioLibVM.init(context);
    this.audioList = await this.audioLibVM.loadAllAudio();
  }

  @Builder
  importOptionBuilder(option: ImportOption) {
    Row({ space: 12 }) {
      Image(option.icon)
        .width(30)
        .aspectRatio(1)
        .fillColor(option.color)
        .backgroundColor(Color.Transparent);

      Text(option.text)
        .fontSize(16)
        .fontWeight(FontWeight.Normal);

      Blank();

      Image($r('app.media.chevron_right'))
        .width(12)
        .aspectRatio(1)
        .backgroundColor(Color.Transparent);
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 });
  }

  @Builder
  importDialogBuilder() {
    Column() {
      Row() {
        Text('选择导入方式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold);

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image($r('app.media.xmark'))
            .width(20)
            .aspectRatio(1)
            .fillColor(Color.Black);
        }
        .padding(8)
        .backgroundColor('#AADCDCDC')
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween);

      List() {
        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[0]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          this.getUIContext()
            .getPromptAction()
            .openCustomDialog({
              builder: () => {
                this.createFolderDialogBuilder();
              },
              width: '90%',
              autoCancel: false,
              alignment: DialogAlignment.Center,
              transition: TransitionEffect.SLIDE,
              onWillAppear: () => {
                this.newPlaylistName = undefined;
              }
            })
            .then((dialogId: number) => {
              this.createPlaylistDialogId = dialogId;
            })
            .catch((err: BusinessError) => {
              console.error(`Failed to open create playlist dialog. Cuase: ${JSON.stringify(err)}`);
            });
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[1]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromAudioLib(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[2]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromFileMgr(context);
        });

        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[3]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          let context = this.getUIContext().getHostContext() as Context;
          this.audioLibVM.importAudioFromDownloadDir(context);
        });


        ListItem() {
          this.importOptionBuilder(IMPORT_OPTS[4]);
        }
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.importDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          // todo
        });
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, startMargin: 46, color: 'rgb(240, 240, 240)' });
    }
    .padding(16);
  }

  @Builder
  createFolderDialogBuilder() {
    Column() {
      Row() {
        Text('新建歌单')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '新建歌单' })
        .id('createFolderTextInput')
        .fontSize(14)
        .maxLength(100)
        .showUnderline(true)
        .underlineColor(Color.Gray)
        .placeholderFont({ size: 14 })
        .backgroundColor(Color.Transparent)
        .bindPopup(this.invalidName, {
          message: `文件名不能包含以下任何字符: ${INVALID_VALUES}`,
          placement: Placement.BottomRight,
        })
        .onAppear(() => {
          try {
            this.getUIContext().getFocusController().requestFocus('createFolderTextInput');
          } catch (error) {
            console.error(`Failed to request focus for createFolder TextInput. Cause: ${JSON.stringify(error)}`);
          }
        })
        .onWillInsert((value: InsertValue) => {
          if (INVALID_VALUES.includes(value.insertValue)) {
            this.invalidName = true;
            setTimeout(() => {
              this.invalidName = false;
            }, 3000);
          } else {
            this.invalidName = false;
          }
          return !this.invalidName;
        })
        .onChange((value: string) => {
          this.newPlaylistName = value;
        });

      Row() {
        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('取消')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createPlaylistDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
        });

        Divider()
          .height(24)
          .vertical(true)
          .strokeWidth(1)
          .color('#DCDCDC');

        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('创建')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createPlaylistDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          if (this.newPlaylistName !== undefined) {
            this.audioLibVM.createAudioPlaylist(this.newPlaylistName);
          }
        });
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(16);
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      Row() {
        Row({ space: 12 }) {
          if (this.currAudioList) {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.back'))
                .width(14)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .width(36)
            .aspectRatio(1)
            .backgroundColor('#AADCDCDC')
            .onClick(() => {
              switch (this.currAudioList?.type) {
                case AudioListType.PLAY_LIST:
                  this.playListStack.pop();
                  break;
                case AudioListType.ALNUM_LIST:
                  this.albumListStack.pop();
                  break;
                case AudioListType.ARTIST_LIST:
                  this.artistListStack.pop();
                  break;
              }
            });
          }

          Text(this.setAudioTitleText(this.currAudioList))
            .maxLines(1)
            .fontSize(20)
            .layoutWeight(1)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1);

        Row({ space: 12 }) {
          if (this.currAudioList) {
            Button({ type: ButtonType.Capsule, stateEffect: false }) {
              Text('多选')
                .fontSize(14)
                .fontColor(Color.Black);
            }
            .width(36 * 1.5)
            .aspectRatio(1.5)
            .backgroundColor('#AADCDCDC');
          }

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.plus'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC')
          .onClick(() => {
            this.getUIContext()
              .getPromptAction()
              .openCustomDialog({
                builder: () => {
                  this.importDialogBuilder();
                },
                width: '100%',
                alignment: DialogAlignment.Bottom,
                transition: TransitionEffect.SLIDE,
                offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) }
              })
              .then((dialogId: number) => {
                this.importDialogId = dialogId;
              })
              .catch((err: BusinessError) => {
                console.error(`Failed to open import dialog. Cuase: ${JSON.stringify(err)}`);
              });
          });

          Button({ type: ButtonType.Circle, stateEffect: false }) {
            Image($r('app.media.dot_grid_2x2'))
              .width(24)
              .aspectRatio(1)
              .fillColor(Color.Black);
          }
          .width(36)
          .aspectRatio(1)
          .backgroundColor('#AADCDCDC');
        };
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        top: 8,
        left: 16,
        right: 16,
        bottom: 8,
      });

      Stack({ alignContent: Alignment.Bottom }) {
        Tabs() {
          TabContent() {
            Navigation(this.playListStack) {
              AudioPlayListView();
            }
            .hideToolBar(true)
            .mode(NavigationMode.Stack);
          }
          .tabBar(
            SubTabBarStyle
              .of('歌单')
              .labelStyle({
                maxLines: 1,
                font: { size: 14 },
                overflow: TextOverflow.Ellipsis
              })
          );

          TabContent() {
            Navigation(this.albumListStack) {
              AudioAlbumListView();
            }
            .hideToolBar(true)
            .mode(NavigationMode.Stack);
          }
          .tabBar(
            SubTabBarStyle
              .of('专辑')
              .labelStyle({
                maxLines: 1,
                font: { size: 14 },
                overflow: TextOverflow.Ellipsis
              })
          );

          TabContent() {
            Navigation(this.artistListStack) {
              AudioArtistListView();
            }
            .hideToolBar(true)
            .mode(NavigationMode.Stack);
          }
          .tabBar(
            SubTabBarStyle
              .of('艺术家')
              .labelStyle({
                maxLines: 1,
                font: { size: 14 },
                overflow: TextOverflow.Ellipsis
              })
          );
        }
        .scrollable(false)
        .onUnselected((index: number) => {
          if (index === 0) {
            this.playListStack.clear();
          } else if (index === 1) {
            this.albumListStack.clear();
          } else {
            this.artistListStack.clear();
          }
        });

        Row() {
          AudioBottomBar()
            .margin({ left: 8, right: 8 });
        }
        .height(60)
        .width('100%');
      };
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });
  }

  private setAudioTitleText(audioListInfo: AudioListInfo | undefined): string {
    if (!audioListInfo) {
      return '音频';
    }
    switch (audioListInfo.type) {
      case AudioListType.PLAY_LIST:
        if (audioListInfo.name === ALL_AUDIO) {
          return '全部音频';
        } else if (audioListInfo.name === FAVORITE_AUDIO) {
          return '我的收藏';
        }
        break;
      case AudioListType.ALNUM_LIST:
        if (!audioListInfo.name) {
          return '未知专辑';
        }
        break;
      case AudioListType.ARTIST_LIST:
        if (!audioListInfo.name) {
          return '未知艺术家';
        }
        break;
    }
    return audioListInfo.name!;
  }
}