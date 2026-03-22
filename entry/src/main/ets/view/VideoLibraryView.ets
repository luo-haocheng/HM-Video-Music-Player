import { VideoLibraryViewModel } from '../viewmodel/VideoLibraryViewModel';
import { VideoBrowserView } from './VideoBrowserView';
import { emitter } from '@kit.BasicServicesKit';

const ROOT_FOLDER = '/';
const INVALID_VALUES = '/\\:*?"<>|';
const CHOICE_ALL = 'ChoiceAll';
const CHOICE_ALL_EVENT = 'ChoiceAll';
const MOVE_CHOICE_EVENT = 'MoveChoice';
const SHARE_CHOICE_EVENT = 'ShareChoice';
const DELETE_CHOICE_EVENT = 'DeleteChoice';
const MULTI_CHOICE = 'MultiChoice';
const CURRENT_FOLDER = 'CurrentFolder';
const TOP_RECT_HEIGHT = 'TopRectHeight';
const BOTTOM_RECT_HEIGHT = 'BottomRectHeight';
const IMPORT_OPTS: ImportOption[] = [
  { icon: $r('app.media.picture_2'), text: '系统图库导入', color: Color.Blue },
  { icon: $r('app.media.folder'), text: '文件管理导入', color: Color.Orange },
  { icon: $r('app.media.download_folder'), text: '下载目录导入', color: Color.Red },
  { icon: $r('app.media.folder_badge_plus'), text: '创建文件夹', color: Color.Green },
  { icon: $r('app.media.question_circle'), text: '导入疑问', color: Color.Gray },
];

interface ImportOption {
  color: ResourceColor,
  icon: Resource,
  text: string
};

@Builder
export function VideoBrowserBuilder() {
  VideoBrowserView();
}

@Component
export struct VideoLibraryView {
  @Provide(CHOICE_ALL) choiceAll: boolean = true;
  @Provide(MULTI_CHOICE) multiChoice: boolean = false;
  @Provide(CURRENT_FOLDER) currFolder: string = ROOT_FOLDER;
  @Provide('VideoTabStack') videoTabStack: NavPathStack = new NavPathStack();
  @State videoLibVM: VideoLibraryViewModel = new VideoLibraryViewModel(this.getUIContext().getHostContext() as Context);
  @State invalidName: boolean = false;
  @StorageProp(TOP_RECT_HEIGHT) topRectHeight: number = 0;
  @StorageProp(BOTTOM_RECT_HEIGHT) bottomRectHeight: number = 0;
  private newFolderName?: string;
  private importDialogId: number = 0;
  private multiChoiceDialogId: number = 0;
  private createFolderDialogId: number = 0;
  private moreOptionsMenuList: MenuElement[] = [
    {
      value: '宫格视图',
      action: () => {
      }
    },
    {
      value: '排序方式',
      action: () => {
      }
    },
    {
      value: '保险柜',
      action: () => {
      }
    },
    {
      value: '设置',
      action: () => {
      }
    },
    {
      value: '关于',
      action: () => {
      }
    },
  ];

  async aboutToAppear(): Promise<void> {
    await this.videoLibVM.init();
    this.videoTabStack.pushPath({ name: 'VideoBrowser' });
  }

  private getFolderName(path: string): string {
    let prevSlashIdx = path.lastIndexOf('/', path.length - 2);
    let folderName = path.slice(prevSlashIdx + 1, path.length - 1);
    return folderName;
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
  createFolderDialogBuilder() {
    Column() {
      Row() {
        Text('新建文件夹')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '新建文件夹' })
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
          this.newFolderName = value;
        });

      Row() {
        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('取消')
            .fontSize(14)
            .fontColor('#FF4876FF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createFolderDialogId);
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
            .fontColor('#FF4876FF');
        }
        .padding(8)
        .width('50%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          try {
            this.getUIContext().getPromptAction().closeCustomDialog(this.createFolderDialogId);
          } catch (error) {
            console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
          }
          if (this.newFolderName != undefined) {
            let newFolder = this.currFolder + this.newFolderName + '/';
            this.videoLibVM.createVideoFolder(newFolder, this.currFolder);
          }
        });
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(16);
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
        .padding(6)
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
          this.videoLibVM.importVideoFromMediaLib(this.currFolder);
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
          this.videoLibVM.importVideoFromFileMgr(this.currFolder);
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
          this.videoLibVM.importVideoFromDownloadDir(this.currFolder);
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
                this.newFolderName = undefined;
              }
            })
            .then((dialogId: number) => {
              this.createFolderDialogId = dialogId;
            })
            .catch((err: BusinessError) => {
              console.error(`Failed to open create folder dialog. Cuase: ${JSON.stringify(err)}`);
            });
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
  ChoiceOptionBuilder(icon: ResourceStr, name: ResourceStr, callback: Callback<void>) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .aspectRatio(1)
        .fillColor(Color.Black);
      Text(name)
        .fontSize(12)
        .fontColor(Color.Black);
    }
    .height('100%')
    .padding({ top: 8 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      callback();
    });
  }

  @Builder
  multiChoiceBuilder() {
    Row() {
      this.ChoiceOptionBuilder($r('app.media.trash'), '删除', () => {
        emitter.emit(DELETE_CHOICE_EVENT);
        try {
          this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
        } catch (error) {
          console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
        }
      });

      this.ChoiceOptionBuilder($r('app.media.arrow_right_folder_circle'), '移动', () => {
        emitter.emit(MOVE_CHOICE_EVENT);
        try {
          this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
        } catch (error) {
          console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
        }
      });

      this.ChoiceOptionBuilder($r('app.media.lock'), '保险柜', () => {
        console.info('Move all choice videos and folders to secret folder');
        // todo
      });

      this.ChoiceOptionBuilder($r('app.media.share'), '分享', () => {
        emitter.emit(SHARE_CHOICE_EVENT);
        try {
          this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
        } catch (error) {
          console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
        }
      });
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
    .alignItems(VerticalAlign.Top)
    .justifyContent(FlexAlign.SpaceBetween);
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Start,
      alignItems: ItemAlign.Center
    }) {
      if (!this.multiChoice) {
        Row() {
          Row({ space: 12 }) {
            if (this.currFolder !== ROOT_FOLDER) {
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
                this.videoTabStack.pop();
              });
            }

            Text(this.currFolder === ROOT_FOLDER ? '视频' : this.getFolderName(this.currFolder))
              .maxLines(1)
              .fontSize(20)
              .layoutWeight(1)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .layoutWeight(1);

          Row({ space: 12 }) {
            Button({ type: ButtonType.Capsule, stateEffect: false }) {
              Text('多选')
                .fontSize(14)
                .fontColor(Color.Black);
            }
            .width(36 * 1.5)
            .aspectRatio(1.5)
            .backgroundColor('#AADCDCDC')
            .onClick(() => {
              this.getUIContext()
                .getPromptAction()
                .openCustomDialog({
                  builder: () => {
                    this.multiChoiceBuilder();
                  },
                  width: '100%',
                  height: 56 + this.getUIContext().px2vp(this.bottomRectHeight),
                  isModal: false,
                  cornerRadius: 0,
                  alignment: DialogAlignment.Bottom,
                  transition: TransitionEffect.SLIDE,
                  offset: { dx: 0, dy: this.getUIContext().px2vp(this.bottomRectHeight) },
                  onWillAppear: () => {
                    this.multiChoice = true;
                  },
                  onWillDisappear: () => {
                    this.multiChoice = false;
                    this.choiceAll = true;
                  }
                })
                .then((dialogId: number) => {
                  this.multiChoiceDialogId = dialogId;
                })
                .catch((err: BusinessError) => {
                  console.error(`Failed to open import dialog. Cuase: ${JSON.stringify(err)}`);
                });
            });

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
            .backgroundColor('#AADCDCDC')
            .bindMenu(this.moreOptionsMenuList);
          }
          .layoutWeight(0);
        }
        .padding(16)
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
      } else {
        Row() {
          Row({ space: 12 }) {
            Button({ type: ButtonType.Circle, stateEffect: false }) {
              Image($r('app.media.xmark'))
                .width(24)
                .aspectRatio(1)
                .fillColor(Color.Black);
            }
            .width(36)
            .aspectRatio(1)
            .backgroundColor('#AADCDCDC')
            .onClick(() => {
              try {
                this.getUIContext().getPromptAction().closeCustomDialog(this.multiChoiceDialogId);
              } catch (error) {
                console.error(`Failed to closeCustomDailog. Cause: ${JSON.stringify(error)}`);
              }
            });

            Text('未选择')
              .fontSize(18)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold);
          };

          Button({ type: ButtonType.Capsule, stateEffect: false }) {
            Text(this.choiceAll ? '全选' : '取消全选')
              .fontSize(14)
              .fontColor(Color.Black);
          }
          .width(36 * (this.choiceAll ? 1.5 : 2))
          .aspectRatio(this.choiceAll ? 1.5 : 2)
          .backgroundColor('#AADCDCDC')
          .onClick(() => {
            let eventData: emitter.EventData = {
              data: {
                'choiceAll': this.choiceAll,
              }
            };
            this.choiceAll = !this.choiceAll;
            emitter.emit(CHOICE_ALL_EVENT, eventData);
          });
        }
        .padding(16)
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween);
      }

      Navigation(this.videoTabStack) {
        // Nothing, waiting from push
      }
      .hideToolBar(true)
      .mode(NavigationMode.Stack);

    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) });
  }
}

