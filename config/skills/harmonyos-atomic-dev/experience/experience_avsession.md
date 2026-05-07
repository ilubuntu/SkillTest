# AVSession (音视频播控) 开发经验

## 能力概述

AVSession Kit (`@kit.AVSessionKit`) 提供音视频播控服务，支持媒体会话管理、播放状态上报、控制命令注册、投播设备选择等能力。元服务从 API 12 开始支持大部分核心 API。

**导入方式：**
```typescript
import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'
```

---

## 一、元服务 API 兼容性清单

### 可用 API (元服务 API 12+)

| API | 说明 | 元服务起始版本 |
|-----|------|---------------|
| `avSession.createAVSession(context, tag, type)` | 创建媒体会话，支持 audio / video / voice_call 类型 | API 12 |
| `session.sessionId` | 获取唯一会话标识 | API 12 |
| `session.sessionType` | 获取会话类型 | API 12 |
| `session.setAVMetadata(metadata)` | 设置媒体元数据（Promise/Callback 双形式） | API 12 |
| `session.setAVPlaybackState(state)` | 设置播放状态（Promise/Callback 双形式） | API 12 |
| `session.activate()` | 激活会话 | API 12 |
| `session.deactivate()` | 停用会话 | API 12 |
| `session.destroy()` | 销毁会话 | API 12 |
| `session.on('play' / 'pause' / 'stop')` | 基础播放控制命令 | API 12 |
| `session.on('playNext' / 'playPrevious')` | 上下首切换命令 | API 12 |
| `session.on('fastForward' / 'rewind')` | 快进快退命令 | API 12 |
| `session.on('seek')` | 进度跳转命令 | API 12 |
| `session.on('setSpeed')` | 倍速设置命令 | API 12 |
| `session.on('setLoopMode')` | 循环模式设置命令 | API 12 |
| `session.on('toggleFavorite')` | 收藏切换命令 | API 12 |
| `session.on('handleKeyEvent')` | 按键事件转发 | API 12 |
| `session.off('xxx')` | 注销控制命令（不支持的命令注销后播控中心自动置灰） | API 12 |
| `avSession.PlaybackState` | 播放状态枚举 (PLAY/PAUSE/STOP/BUFFERING 等) | API 12 |
| `avSession.LoopMode` | 循环模式枚举 (SEQUENCE/SINGLE/LIST/SHUFFLE) | API 12 |
| `avSession.AVMetadata` | 元数据接口 (title/artist/album/duration/lyric 等) | API 12 |
| `avSession.AVPlaybackState` | 播放状态接口 (state/speed/position/loopMode/isFavorite) | API 12 |
| `avSession.AVCastPickerHelper` | 投播设备选择器 | API 14 |
| `session.getAVCastController()` | 获取投播控制器 | API 12 |

### 不可用 API (编译不通过)

| API | 错误码 | 说明 |
|-----|--------|------|
| `avSession.SkipIntervals` (SECONDS_10/15/30) | 11706010 | 快进快退间隔枚举不可用 |
| `avSession.DisplayTag` (TAG_AUDIO_VIVID) | 11706010 | 媒体金标枚举不可用 |
| `AVSessionController` | — | 元服务中无法控制其他应用的媒体会话 |
| 系统级媒体控制面板 | — | 元服务无法注册通知栏媒体控制回调 |

**关键发现：** `SkipIntervals` 和 `DisplayTag` 在普通应用中可用，但在元服务中编译器直接拒绝（`can't support atomicservice application`）。元数据中的 `skipIntervals` 和 `displayTags` 字段不能使用这些枚举赋值。

---

## 二、核心调用方式和参数说明

### 1. 会话创建与激活

```typescript
// 创建会话 — 必须在 activate 之前完成所有控制命令注册和元数据设置
const session = await avSession.createAVSession(context, 'SESSION_TAG', 'audio')

// 注册控制命令（必须在 activate 前完成）
session.on('play', () => { /* 播放逻辑 */ })
session.on('pause', () => { /* 暂停逻辑 */ })

// 设置元数据
await session.setAVMetadata({ assetId: '001', title: 'Song', artist: 'Artist', duration: 240000 })

// 最后激活
await session.activate()
```

**会话类型选择：**
- `audio`: 播控中心显示"收藏/上一首/播放暂停/下一首/循环模式"
- `video`: 播控中心显示"快退/上一首/播放暂停/下一首/快进"
- `voice_call`: 通话类型，播控中心显示通话控制

### 2. AVMetadata 元数据

```typescript
const metadata: avSession.AVMetadata = {
  assetId: '001',           // 必填，应用内媒体唯一标识
  title: '歌曲名',          // 播控中心显示标题
  artist: '艺术家',
  album: '专辑',
  writer: '词作者',
  composer: '曲作者',
  duration: 240000,         // 毫秒
  mediaImage: 'url_or_pixelmap',
  subtitle: '副标题',
  description: '描述',
  lyric: '[00:25.44]歌词\r\n[00:26.44]歌词',  // LRC 格式歌词
  singleLyricText: '当前歌词行',                // 单条歌词
  previousAssetId: '000',   // 上一首 ID
  nextAssetId: '002',       // 下一首 ID
  avQueueName: '歌单名',    // 歌单名称（用于历史歌单功能）
  avQueueId: 'queue_001',   // 歌单唯一 ID
  avQueueImage: 'url',      // 歌单封面
  // skipIntervals: 不可用 (元服务不支持 SkipIntervals 枚举)
  // displayTags: 不可用 (元服务不支持 DisplayTag 枚举)
}
await session.setAVMetadata(metadata)
```

**注意事项：**
- `AVMetadata` 中没有 `mediaType` 属性
- `assetId` 为必填字段
- `lyric` 使用 LRC 格式：`[mm:ss.xx]歌词内容\r\n`
- 歌单字段 (`avQueueName`/`avQueueId`/`avQueueImage`) 用于系统播控中心历史歌单功能

### 3. AVPlaybackState 播放状态

```typescript
const state: avSession.AVPlaybackState = {
  state: avSession.PlaybackState.PLAYBACK_STATE_PLAY,
  speed: 1.0,
  position: { elapsedTime: 1000, updateTime: Date.now() },
  bufferedTime: 14000,
  loopMode: avSession.LoopMode.LOOP_MODE_SINGLE,
  isFavorite: false,
  activeItemId: 1,
}
await session.setAVPlaybackState(state)
```

**关键状态枚举：**
- `PlaybackState`: PLAY(0), PAUSE(1), STOP(2), BUFFERING(4)
- `LoopMode`: SEQUENCE(0), SINGLE(1), LIST(2), SHUFFLE(3)

### 4. 控制命令注册

```typescript
// 基础控制
session.on('play', () => { /* 响应播放 */ })
session.on('pause', () => { /* 响应暂停 */ })
session.on('stop', () => { /* 响应停止 */ })

// 曲目切换
session.on('playNext', () => { /* 下一首 */ })
session.on('playPrevious', () => { /* 上一首 */ })

// 进度控制
session.on('seek', (position: number) => { /* position 单位 ms */ })

// 速度/模式/收藏
session.on('setSpeed', (speed: number) => { /* 倍速 */ })
session.on('setLoopMode', (mode: avSession.LoopMode) => { /* 循环模式 */ })
session.on('toggleFavorite', (assetId: string) => { /* 收藏切换 */ })

// 快进快退
session.on('fastForward', (time?: number) => { /* time 为跳过毫秒数 */ })
session.on('rewind', (time?: number) => { /* time 为跳过毫秒数 */ })
```

**关键约束：**
- 控制命令必须在 `activate()` 之前注册
- 不支持的命令使用 `session.off('xxx')` 注销，播控中心自动将对应按钮置灰
- 控制命令回调中更新状态后，必须通过 `setAVPlaybackState` 同步给系统
- 系统根据应用设置的信息自行计算播放进度，只需在 state/position/speed 变化时上报

### 5. 投播设备选择

```typescript
const picker = new avSession.AVCastPickerHelper(context)
const options: avSession.AVCastPickerOptions = {
  sessionType: 'audio' as avSession.AVSessionType,
}
await picker.select(options)
```

**注意：** `select()` 不接受回调函数参数，接受 `AVCastPickerOptions` 对象，返回 `Promise<void>`。

---

## 三、编译问题与解决方案

### 问题 1: SkipIntervals / DisplayTag 编译失败

**错误信息：** `11706010 can't support atomicservice application`
**影响文件：** 所有使用 `avSession.SkipIntervals` 或 `avSession.DisplayTag` 的代码

**解决方案：** 移除 AVMetadata 中对 `skipIntervals` 和 `displayTags` 字段的赋值。快进快退的间隔时间由开发者在回调中自行硬编码控制。

### 问题 2: Record<number, T> 编译失败

**错误信息：** `arkts-no-untyped-obj-literals` / `arkts-identifiers-as-prop-names`

**原因：** ArkTS 不支持使用数字/枚举值作为对象属性名（`{ [enumValue]: 'string' }`），也不支持未明确声明类型的对象字面量。

**解决方案：** 使用 `if-else` 或 `switch` 语句替代 `Record<number, T>` 映射。

```typescript
// 错误写法
const map: Record<number, string> = { [avSession.LoopMode.LOOP_MODE_SINGLE]: '单曲' }

// 正确写法
if (mode === avSession.LoopMode.LOOP_MODE_SINGLE) {
  label = '单曲'
} else if (mode === avSession.LoopMode.LOOP_MODE_LIST) {
  label = '列表'
}
```

### 问题 3: AVCastPickerHelper.select() 回调签名错误

**错误信息：** `Type callback has no properties in common with type 'AVCastPickerOptions'`
**解决方案：** `select()` 不接受回调函数，接受 `AVCastPickerOptions` 对象，返回 `Promise<void>`

---

## 四、降级处理策略

1. **SkipIntervals 不可用：** 在 `fastForward` / `rewind` 回调中硬编码跳过时间（如 10000ms），不依赖 `skipIntervals` 元数据字段。

2. **DisplayTag 不可用：** 媒体金标（Audio Vivid）功能在元服务中无法展示，无需特殊降级处理。

3. **后台播放：** 元服务后台播放需配合 `backgroundTaskManager` 申请 `AUDIO_PLAYBACK` 长时任务，否则进入后台时音频会被系统停止。

4. **控制命令粒度：** 不支持的命令通过 `off()` 注销，系统播控中心自动置灰对应按钮。建议只注册实际支持的命令。

5. **AVSessionController 不可用：** 元服务无法控制其他应用的媒体会话，仅支持创建和管理自身的会话。
