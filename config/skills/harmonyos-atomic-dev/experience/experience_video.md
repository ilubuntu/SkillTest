# Video 组件开发经验

## 元服务 API 兼容性清单

### 可用 API

| API | 元服务版本 | 说明 |
|---|---|---|
| `Video({ src, previewUri?, currentProgressRate?, controller? })` | API 11+ | 视频播放组件 |
| `VideoController` | API 11+ | start/pause/stop/setCurrentTime/requestFullscreen/exitFullscreen |
| `VideoController.reset()` | API 12+ | 重置视频源 |
| `.muted(bool)` / `.autoPlay(bool)` / `.controls(bool)` / `.loop(bool)` | API 11+ | 播放控制 |
| `.objectFit(ImageFit)` | API 11+ | 默认 Cover，不支持 MATRIX |
| `.enableAnalyzer(bool)` | API 12+ | AI 分析 |
| `PlaybackSpeed` 标准 5 种 (0.75x~2x) | API 11+ | 倍速播放 |
| `SeekMode` 枚举 (PreviousKeyframe/NextKeyframe/ClosestKeyframe/Accurate) | API 11+ | 跳转模式 |
| `onStart/onPause/onFinish/onError/onPrepared/onUpdate/onFullscreenChange` | API 11+ | 播放事件 |
| `onStop` | API 12+ | 停止回调 |

### 不可用 API

| API | 所需版本 | 说明 |
|---|---|---|
| `PlaybackSpeed` 新增 5 种 (0.5x/1.5x/3x/0.25x/0.125x) | API 22+ | 高级倍速 |
| `enableShortcutKey` | API 15+ | 键盘快捷键 |
| `PosterOptions.showFirstFrame` | API 18+ | 预览首帧 |
| `PosterOptions.contentTransitionEffect` | API 21+ | 内容过渡效果 |
| `expandSafeArea` | — | 视频内容区域不会扩展 |

## 核心调用方式

```typescript
Video({
  src: 'https://example.com/video.mp4',
  previewUri: '',
  currentProgressRate: PlaybackSpeed.Speed_Forward_1_00_X,
  controller: this.controller
}).autoPlay(false).controls(true).objectFit(ImageFit.Cover)
  .onPrepared((event) => { /* event.duration */ })
  .onStart(() => { /* 播放开始 */ })
```

## 降级策略

| 不可用 API | 降级方案 |
|---|---|
| 高级倍速 (API 22+) | 使用标准 5 种倍速 |
| enableShortcutKey (API 15+) | PC/平板场景下暂不支持 |
| PosterOptions (API 18+/21+) | 使用 previewUri 设置预览图 |
