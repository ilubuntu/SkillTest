# @ohos.multimedia.cameraPicker (相机选择器)

本模块提供相机拍照与录制的能力。本模块无需相机权限。应用可选择媒体类型实现拍照和录制的功能。调用此类接口时，应用必须在界面UIAbility中调用，否则无法启动cameraPicker应用。

## 示例代码

```typescript
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
async function camearaPick(context: Context) {
  try {
    let pickerProfile: cameraPicker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
    };
    let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(context,
      [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO], pickerProfile);
    console.info("the pick pickerResult is:" + JSON.stringify(pickerResult));
  } catch (error) {
    let err = error as BusinessError;
    console.error(`the pick call failed. error code: ${err.code}`);
  }
}
```

## API参数

### PickerMediaType 枚举

枚举，相机选择器的媒体类型。

| 名称 | 值 | 说明 |
|------|-----|------|
| PHOTO | 'photo' | 拍照模式。 |
| VIDEO | 'video' | 录制模式。 |

### PickerProfile 类

相机选择器的配置信息。

| 名称 | 类型 | 只读 | 可选 | 说明 |
|------|------|------|------|------|
| cameraPosition | camera.CameraPosition | 否 | 否 | 相机的位置。 |
| saveUri | string | 否 | 是 | 保存配置信息的uri。当前saveUri参数为可选参数，若未配置该参数，则拍摄的照片和视频会默认存入媒体库中；若不想将照片和视频存入媒体库中，请自行配置应用沙箱内的文件资源路径，如自行传入资源路径时请确保该文件存在且具备写入权限，否则会保存失败。 |
| videoDuration | number | 否 | 是 | 录制的最大时长（单位：秒）。默认为0，不设置最大录制时长。 |

### PickerResult 类

相机选择器的处理结果。

| 名称 | 类型 | 只读 | 可选 | 说明 |
|------|------|------|------|------|
| resultCode | number | 否 | 否 | 处理的结果，成功返回0，失败返回-1。 |
| resultUri | string | 否 | 否 | 返回的uri地址。若saveUri为空，resultUri为公共媒体路径。若saveUri不为空且具备写权限，resultUri与saveUri相同。若saveUri不为空且不具备写权限，则无法获取到resultUri。 |
| mediaType | PickerMediaType | 否 | 否 | 返回的媒体类型。 |