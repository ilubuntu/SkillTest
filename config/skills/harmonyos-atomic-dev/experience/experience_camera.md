# Camera Kit 元服务开发经验

## 一、元服务 API 兼容性清单

### 可用 API

| API | 模块 | 说明 | 元服务支持版本 |
|-----|------|------|---------------|
| `cameraPicker.pick()` | `@kit.CameraKit` | 拉起系统相机拍照/录制 | API 12+ |
| `PickerMediaType.PHOTO` | `@kit.CameraKit` | 拍照模式 | API 12+ |
| `PickerMediaType.VIDEO` | `@kit.CameraKit` | 视频录制模式 | API 12+ |
| `PickerProfile.cameraPosition` | `@kit.CameraKit` | 选择前置/后置相机 | API 12+ |
| `PickerProfile.saveUri` | `@kit.CameraKit` | 自定义保存路径（沙箱文件URI） | API 12+ |
| `PickerProfile.videoDuration` | `@kit.CameraKit` | 录制时长限制（秒，0为不限） | API 12+ |
| `PickerResult.resultCode` | `@kit.CameraKit` | 结果码（0成功，-1失败） | API 12+ |
| `PickerResult.resultUri` | `@kit.CameraKit` | 媒体文件URI | API 12+ |
| `PickerResult.mediaType` | `@kit.CameraKit` | 返回的媒体类型（photo/video） | API 12+ |

## 二、核心调用方式

### 1. 基础拍照/录制

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
    // result.resultCode === 0 → 成功，result.resultUri → 文件路径
    console.info("the pick pickerResult is:" + JSON.stringify(pickerResult));
  } catch (error) {
    let err = error as BusinessError;
    console.error(`the pick call failed. error code: ${err.code}`);
  }
}

```

### 2. 自定义保存路径（saveUri）

```typescript
import { fileIo, fileUri } from '@kit.CoreFileKit'

let pathDir = context.filesDir
let filePath = `${pathDir}/photo_${Date.now()}.tmp`
fileIo.createRandomAccessFileSync(filePath, fileIo.OpenMode.CREATE)
let uri = fileUri.getUriFromPath(filePath)

let pickerProfile: cameraPicker.PickerProfile = {
  cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
  saveUri: uri
}
```

**saveUri 行为要点：**
- saveUri 为空 → resultUri 为公共媒体路径（默认存入媒体库）
- saveUri 有写权限 → resultUri 与 saveUri 相同（保存到沙箱）
- saveUri 无写权限 → 无法获取 resultUri
- 沙箱文件必须提前创建（`fileIo.createRandomAccessFileSync`），否则写入失败
- 传入 saveUri 相当于给系统相机授权该文件的读写权限

## 三、关键注意事项

1. **调用时机**：必须在 UIAbility 界面中调用，否则无法启动 cameraPicker
2. **无需权限**：CameraPicker 不需要申请相机权限（用户主动确认拍摄）
