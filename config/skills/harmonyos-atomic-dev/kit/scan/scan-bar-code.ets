import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@ComponentV2
export struct ScanBarCodeExample {
  build() {
    Column() {
      Row() {
        Button("Promise with options")
          .backgroundColor('#0D9FFB')
          .fontSize(20)
          .fontColor($r('sys.color.comp_background_list_card'))
          .fontWeight(FontWeight.Normal)
          .align(Alignment.Center)
          .type(ButtonType.Capsule)
          .width('90%')
          .height(40)
          .margin({ top: 5, bottom: 5 })
          .onClick(() => {
            // 定义扫码参数options
            let options: scanBarcode.ScanOptions = {
              scanTypes: [scanCore.ScanType.ALL],
              enableMultiMode: true,
              enableAlbum: true
            };
            scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options).then((result: scanBarcode.ScanResult) => {
              hilog.info(0x0001, '[Scan CPSample]', `Succeeded in getting scanResult by promise with options, result is ${JSON.stringify(result)}`);
            }).catch((error: BusinessError) => {
              hilog.error(0x0001, '[Scan CPSample]', `Failed to get scanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
            });
          })
      }
    }
  }
}