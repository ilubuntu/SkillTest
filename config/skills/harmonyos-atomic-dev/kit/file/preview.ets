import { filePreview } from '@kit.PreviewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
export function previewFile(context: common.UIAbilityContext, uri: string) {
  filePreview.canPreview(context, uri).then((result) => {    // 传入支持的文件类型且文件存在时会返回true
    console.info(`Succeeded in obtaining the result of whether it can be previewed. result = ${result}`);
  }).catch((err: BusinessError) => {
    console.error(`Failed to obtain the result of whether it can be previewed, err.code = ${err.code}, err.message = ${err.message}`);
  });

  let displayInfo: filePreview.DisplayInfo = {
    x: 100,
    y: 100,
    width: 800,
    height: 800
  };
  let fileInfo: filePreview.PreviewInfo = {
    title: '1.txt',
    uri: 'file://docs/storage/Users/currentUser/Documents/1.txt',
    mimeType: 'text/plain'
  };
  filePreview.openPreview(context, fileInfo, displayInfo).then(() => {
    console.info('Succeeded in opening preview');
  }).catch((err: BusinessError) => {
    console.error(`Failed to open preview, err.code = ${err.code}, err.message = ${err.message}`);
  });
}