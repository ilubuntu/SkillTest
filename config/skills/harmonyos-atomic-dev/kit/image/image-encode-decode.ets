import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';

// 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
export function decodeImage(context: common.UIAbilityContext, filename: string) {
  const filePath: string = context.cacheDir + filename;
  const imageSource : image.ImageSource = image.createImageSource(filePath);

  imageSource.getImageInfo(0, (error : BusinessError, imageInfo : image.ImageInfo) => {
    if(error) {
      console.error('getImageInfo failed.');
    } else {
      console.log('getImageInfo succeeded.');
    }
  })

  let decodingOptions : image.DecodingOptions = {
    editable: true,
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
  }
  imageSource.createPixelMap(decodingOptions).then((pixelMap : image.PixelMap) => {
    console.log("Succeeded in creating PixelMap")
  }).catch((err : BusinessError) => {
    console.error("Failed to create PixelMap")
  });
}

export function encodeImage(context: common.UIAbilityContext, filename: string) {
  const imagePackerApi = image.createImagePacker();
  let packOpts : image.PackingOption = { format:"image/jpeg", quality:98 };
  const filePath: string = context.cacheDir + filename;
  const pixelMap : image.ImageSource = image.createImageSource(filePath);

  imagePackerApi.packToData(pixelMap, packOpts).then( (data : ArrayBuffer) => {
    // data 为打包获取到的文件流，写入文件保存即可得到一张图片
  }).catch((error : BusinessError) => {
    console.error('Failed to pack the image. And the error is: ' + error);
  })
}