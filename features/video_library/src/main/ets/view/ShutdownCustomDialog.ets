import { VideoPlayerViewModel } from '../viewmodel/VideoPlayerViewModel';
import { ShutdownOption } from './ShutdownDialog';

@CustomDialog
export struct ShutdownCustomDialog {
  @Link videoPlayerVM: VideoPlayerViewModel;
  private controller: CustomDialogController;
  private result?: TimePickerResult;

  build() {
    Column({ space: 12 }) {
      Row() {
        Button('取消')
          .padding(0)
          .fontSize(14)
          .fontColor(Color.Gray)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.videoPlayerVM.shutdownOption = ShutdownOption.None;
            this.videoPlayerVM.clearShutdownDate();
            this.controller.close();
          });

        Button('确认')
          .padding(0)
          .fontSize(14)
          .fontColor('#FF007DFF')
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (!this.result || (this.result.hour === 0 && this.result.minute === 0)) {
              this.videoPlayerVM.shutdownOption = ShutdownOption.None;
              this.videoPlayerVM.clearShutdownDate();
              this.controller.close();
              return;
            }
            this.videoPlayerVM.setShutdownDate(this.result.hour, this.result.minute);
            this.controller.close();
          });
      }
      .width('100%')
      .layoutWeight(0)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween);

      Row({ space: 12 }) {
        Text('小时')
          .fontSize(14)
          .fontColor('#FF007DFF')
          .fontWeight(FontWeight.Medium);

        TimePicker({
          selected: new Date(0, 0, 0, 0, 0, 0),
          format: TimePickerFormat.HOUR_MINUTE,
        })
          .width('50%')
          .height('100%')
          .loop(false)
          .useMilitaryTime(true)
          .dateTimeOptions({ hour: 'numeric', minute: 'numeric' })
          .onEnterSelectedArea((result: TimePickerResult) => {
            this.result = result;
          });

        Text('分钟')
          .fontSize(14)
          .fontColor('#FF007DFF')
          .fontWeight(FontWeight.Medium);
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center);
    }
    .padding({
      top: 8,
      left: 16,
      right: 16,
      bottom: 8,
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}