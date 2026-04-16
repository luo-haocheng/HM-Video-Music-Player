import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';
import { VideoInfoModel } from 'data_storage';
import { VideoListViewModel } from '../viewmodel/VideoListViewModel';

const INVALID_VALUES = '/\\:*?"<>|';

@CustomDialog
export struct RenameDialog {
  @Link videoListVM: VideoListViewModel;
  @State invalidName: boolean = false;
  public controller: CustomDialogController;
  public info?: VideoInfoModel | FolderInfoModel;
  private newName?: string = '';

  build() {
    Column() {
      Row() {
        Text('重命名')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.Center);

      TextInput({ placeholder: '重命名' })
        .id('renameTextInput')
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
            this.getUIContext().getFocusController().requestFocus('renameTextInput');
          } catch (error) {
            console.error(`Failed to request focus for renameTextInput. Cause: ${JSON.stringify(error)}`);
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
          this.newName = value;
        });

      Row() {
        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('取消')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('45%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.controller.close();
        });

        Divider()
          .height(24)
          .vertical(true)
          .strokeWidth(1)
          .color('#DCDCDC');

        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text('确认')
            .fontSize(14)
            .fontColor('#FF007DFF');
        }
        .padding(8)
        .width('45%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.controller.close();
          if (this.newName !== undefined) {
            if (this.info instanceof VideoInfoModel) {
              this.videoListVM.renameVideo(this.newName, this.info as VideoInfoModel);
            } else {
              this.videoListVM.renameFolder(this.newName, this.info as FolderInfoModel);
            }
          }
        });
      }
      .width('100%')
      .margin({ top: 12 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .padding(16);
  }
}