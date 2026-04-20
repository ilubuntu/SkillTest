import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct CreateBarCodeExample {
  @State pixelMap: image.PixelMap | undefined = undefined;

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Button('generateBarcode example').onClick(() => {
        // 以QR码为例，码图生成参数
        this.pixelMap = undefined;
        let content: string = 'huawei';
        let options: generateBarcode.CreateOptions = {
          scanType: scanCore.ScanType.QR_CODE,
          height: 400,
          width: 400
        };
        try {
          // 码图生成接口，成功返回PixelMap格式图片
          generateBarcode.createBarcode(content, options).then((pixelMap: image.PixelMap) => {
            this.pixelMap = pixelMap;
          }).catch((error: BusinessError) => {
            hilog.error(0x0001, '[generateBarcode]',
              `Failed to get pixelMap by promise with options. Code: ${error.code}, message: ${error.message}`);
          })
        } catch (error) {
          hilog.error(0x0001, '[generateBarcode]',
            `Failed to createBarcode by promise with options. Code: ${error.code}, message: ${error.message}`);
        }

      })
      // 获取生成码图后显示
      if (this.pixelMap) {
        Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
      }
    }
  }
}