# 使用Picker选择媒体库资源

用户有时需要分享图片、视频等用户文件，开发者可以通过特定接口拉起系统图库，用户自行选择待分享的资源，然后最终分享出去。此接口本身无需申请权限，目前适用于界面UIAbility，使用窗口组件触发。

## 示例代码

```typescript
// 导入选择器模块(@ohos.file.photoAccessHelper)和文件管理模块(@ohos.file.fs)
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';

async function photoSelect() {
    // 创建图片-音频类型文件选择选项实例。（以图片为例）
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();

    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE; // 过滤选择媒体文件类型为IMAGE
    photoSelectOptions.maxSelectNumber = 5; // 选择媒体文件的最大数目

    // 创建图库选择器实例，调用PhotoViewPicker.select接口拉起图库界面进行文件选择。文件选择成功后，返回PhotoSelectResult结果集。
    // select返回的uri权限是只读权限，可以根据结果集中uri进行读取文件数据操作。注意不能在picker的回调里直接使用此uri进行打开文件操作，需要定义一个全局变量保存uri
    let uris: Array<string> = [];
    const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
    photoViewPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        uris = photoSelectResult.photoUris;
        console.info('photoViewPicker.select to file succeed and uris are:' + uris);
    }).catch((err: BusinessError) => {
        console.error(`Invoke photoViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
    })
}

```

## API参考

### PhotoViewMIMETypes

枚举，可选择的媒体文件类型。

| 名称 | 值 | 说明 |
|------|-----|------|
| IMAGE_TYPE | 'image/*' | 图片类型。 |
| VIDEO_TYPE | 'video/*' | 视频类型。 |
| IMAGE_VIDEO_TYPE | '*/*' | 图片和视频类型。 |
| MOVING_PHOTO_IMAGE_TYPE | 'image/movingPhoto'	| 动态照片类型。 |
