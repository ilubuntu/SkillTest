# HarmonyOS 文件管理能力开发实践

## 概述

本文档总结了 HarmonyOS `@kit.CoreFileKit` 文件管理模块在原子化服务 (atomicService) 场景下的开发经验，涵盖文件读写、目录管理、信息查询、文本操作、文件选择器、流操作等子场景，重点记录了 API 兼容性问题和降级策略。

---

## 文件能力矩阵

### @ohos.file.fs (文件管理)

| API | 功能 | atomicService 支持 | API 版本 | 备注 |
|-----|------|--------------------|----------|------|
| `fs.stat / statSync` | 获取文件属性 | 支持 | 11+ | 返回 Stat 对象 |
| `fs.access / accessSync` | 检查文件是否存在 | 支持 | 11+ | 返回 boolean |
| `fs.open / openSync` | 打开文件 | 支持 | 11+ | 返回 File 对象 |
| `fs.close / closeSync` | 关闭文件 | 支持 | 11+ | |
| `fs.read / readSync` | 读取文件 | 支持 | 11+ | 需 ArrayBuffer |
| `fs.write / writeSync` | 写入文件 | 支持 | 11+ | 支持 string/ArrayBuffer |
| `fs.readText / readTextSync` | 读取文本文件 | 支持 | 11+ | 一次性读取全部 |
| `fs.readLines / readLinesSync` | 逐行读取 | 支持 | 11+ | 返回 string[] |
| `fs.mkdir / mkdirSync` | 创建目录 | 支持 | 11+ | 递归创建需 recursive 参数 |
| `fs.rmdir / rmdirSync` | 删除目录 | 支持 | 11+ | 仅删除空目录 |
| `fs.unlink / unlinkSync` | 删除文件 | 支持 | 11+ | |
| `fs.rename / renameSync` | 重命名文件/目录 | 支持 | 11+ | |
| `fs.truncate / truncateSync` | 截断文件 | 支持 | 11+ | |
| `fs.listFile / listFileSync` | 列出目录文件 | 支持 | 11+ | 返回 string[] |
| `fs.lstat / lstatSync` | 获取链接属性 | 支持 | 11+ | |
| `fs.fsync / fsyncSync` | 同步到磁盘 | 支持 | 11+ | |
| `fs.fdatasync / fdatasyncSync` | 同步数据 | 支持 | 11+ | |
| `fs.lseek` | 设置文件偏移 | 支持 | 11+ | |
| `fs.mkdtemp / mkdtempSync` | 创建临时目录 | 支持 | 11+ | |
| `fs.utimes` | 修改文件时间 | 支持 | 11+ | |
| `fs.dup` | 复制文件描述符 | 支持 | 10+ | |
| `fs.copyFile / copyFileSync` | 复制文件 | **不支持** | — | 标准应用可用 |
| `fs.copyDir / copyDirSync` | 复制目录 | **不支持** | — | 标准应用可用 |
| `fs.copy` | 拷贝（URI） | **不支持** | 11+ | 标准应用可用 |
| `fs.moveFile / moveFileSync` | 移动文件 | **不支持** | — | 标准应用可用 |
| `fs.moveDir / moveDirSync` | 移动目录 | **不支持** | — | 标准应用可用 |
| `fs.createStream / createStreamSync` | 创建文件流 | 支持 | **20+** | 元服务从 API 20 起支持 |
| `fs.fdopenStream / fdopenStreamSync` | 从 fd 打开流 | 支持 | **20+** | 元服务从 API 20 起支持 |
| `fs.createReadStream` | 创建读流 | 支持 | **20+** | 元服务从 API 20 起支持 |
| `fs.createWriteStream` | 创建写流 | 支持 | **20+** | 元服务从 API 20 起支持 |
| `fs.createWatcher` | 文件监听 | **不支持** | — | |
| `fs.createRandomAccessFile` | 随机访问文件 | **不支持** | — | |
| `fs.symlink / symlinkSync` | 创建符号链接 | **不支持** | — | |
| `fs.connectDfs / disconnectDfs` | 分布式文件系统 | **不支持** | — | |
| `fs.setxattr / getxattr` | 扩展属性 | **不支持** | — | |

### @ohos.file.picker (文件选择器)

| API | 功能 | atomicService 支持 | API 版本 |
|-----|------|--------------------|----------|
| `DocumentViewPicker` | 文档选择器 | 支持 | 12+ |
| `DocumentViewPicker.select()` | 选择文件 | 支持 | 12+ |
| `DocumentViewPicker.save()` | 保存文件 | 支持 | 12+ |
| `AudioViewPicker` | 音频选择器 | 支持 | 12+ |

### @ohos.file.hash (文件哈希)

| API | 功能 | atomicService 支持 | API 版本 |
|-----|------|--------------------|----------|
| `hash.hash()` | 计算文件哈希 | 支持 | 11+ |
| `hash.createHash()` | 创建哈希流 | **不支持** | — |

### 其他文件模块

| 模块 | atomicService 支持 | 说明 |
|------|--------------------|------|
| `@ohos.file.statvfs` | **不支持** | 无元服务API标记 |
| `@ohos.file.securityLabel` | **不支持** | 无元服务API标记 |
| `@ohos.file.environment` | **不支持** | 仅 2in1 设备 |
| `@ohos.file.fileuri` | 支持 (15+) | FileUri 构造 + 属性访问 |

---

## 场景 1：文件读写（可用）

### 核心调用方式

```typescript
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'

// 获取沙箱路径
const context = getContext(this) as common.Context
const filePath = `${context.filesDir}/demo.txt`

// 写入
const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
const writeLen = fs.writeSync(file.fd, 'Hello HarmonyOS')
fs.closeSync(file.fd)

// 读取
const readFile = fs.openSync(filePath, fs.OpenMode.READ_ONLY)
const buf = new ArrayBuffer(4096)
const readLen = fs.readSync(readFile.fd, buf)
// 需用 util.TextDecoder 解码 ArrayBuffer
const decoder = util.TextDecoder.create('utf-8')
const text = decoder.decodeToString(new Uint8Array(buf, 0, readLen))
fs.closeSync(readFile.fd)
```

### 注意事项

- `fs.readSync` 返回字节数，需手动用 `util.TextDecoder` 解码
- `fs.OpenMode.TRUNC` 打开时截断文件（覆盖写入）
- `fs.OpenMode.APPEND` 追加模式打开
- 写入 string 类型时，`fs.writeSync` 返回写入的字节数（UTF-8 编码）

---

## 场景 2：目录管理（可用）

### 核心调用方式

```typescript
// 创建目录
fs.mkdirSync(`${context.filesDir}/my-dir`)

// 列出文件
const files: string[] = fs.listFileSync(context.filesDir)

// 删除目录（仅空目录）
fs.rmdirSync(`${context.filesDir}/my-dir`)
```

### 注意事项

- `rmdirSync` 只能删除空目录，需先遍历删除子文件
- `listFileSync` 返回文件名数组（不含路径前缀）
- 递归创建目录可用 `fs.mkdirSync(path, { recursive: true })`（API 11+）

---

## 场景 3：文件信息查询（可用）

### 核心调用方式

```typescript
// 获取文件属性
const stat = fs.statSync(filePath)
// stat.size / stat.mode / stat.mtime / stat.atime / stat.ctime
// stat.isFile() / stat.isDirectory()

// 检查文件是否存在
const exists = fs.accessSync(filePath)  // boolean
```

### 注意事项

- `stat.mtime` 返回 Unix 时间戳（秒），需 `new Date(mtime * 1000)` 转换
- `accessSync` 默认只检查文件是否存在，可传 `mode` 参数校验读写权限
- `lstatSync` 用于获取符号链接本身的属性（不跟随链接）

---

## 场景 4：文本文件操作（可用）

### 核心调用方式

```typescript
// 一次性读取整个文本文件
const content = fs.readTextSync(filePath, { encoding: 'utf-8' })

// 写入文本（通过 openSync + writeSync）
const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
fs.writeSync(file.fd, 'Text content')
fs.closeSync(file.fd)
```

### 注意事项

- `readTextSync` 适合小文件，大文件建议分块读取
- encoding 参数仅支持 `'utf-8'`
- 无 `writeTextSync` 便捷方法，需通过 `openSync + writeSync` 实现

---

## 场景 5：文件选择器（可用，API 12+）

### 核心调用方式

```typescript
import { picker } from '@kit.CoreFileKit'

// 选择文件
const docPicker = new picker.DocumentViewPicker(context)
const selectOption = new picker.DocumentSelectOptions()
const uris: Array<string> = await docPicker.select(selectOption)

// 保存文件
const saveOption = new picker.DocumentSaveOptions()
saveOption.newFileNames = ['output.txt']
const saveUris: Array<string> = await docPicker.save(saveOption)
```

### 注意事项

- 元服务从 API 12 起支持 DocumentViewPicker 和 AudioViewPicker
- `select()` 和 `save()` 都是异步方法，返回 URI 数组
- 通过 URI 可进一步使用 `fs` 模块读写文件内容
- 用户取消选择时会抛出异常，需 catch 处理

---

## 场景 6：文件流操作（可用，API 20+）

### 核心调用方式

```typescript
// 写流
const ws = fs.createStreamSync(filePath, 'w+')
ws.writeSync('Stream data')
ws.closeSync()

// 读流
const rs = fs.createStreamSync(filePath, 'r')
const buf = new ArrayBuffer(4096)
const len = rs.readSync(buf)
rs.closeSync()
```

### 注意事项

- 元服务从 API 20 起支持流操作（标准应用从 API 9/12 起支持）
- 当前项目 SDK 版本为 API 22，可正常使用
- `createStreamSync` 第二个参数为模式字符串：`'r'`/`'w'`/`'w+'`/`'a'`/`'a+'` 等
- `Stream.readSync` 同样返回 ArrayBuffer，需 TextDecoder 解码

## 关键经验总结

1. **API 版本差异大**: 文件模块 API 版本跨度大（9→22），元服务支持版本普遍晚于标准应用
2. **copy/move 完全不可用**: 元服务中无文件复制/移动 API，必须手动实现
3. **流操作可用但版本高**: `createStream` 系列需要 API 20+，项目 SDK 22 可满足
4. **picker 是最佳选择入口**: 文件选择器让用户选择/保存文件，是元服务与用户文件交互的主要方式
5. **沙箱路径是关键**: 所有文件操作基于应用沙箱路径，通过 `context.filesDir` 获取
6. **TextDecoder 必不可少**: `fs.readSync` 返回 ArrayBuffer，文本场景必须配合 `util.TextDecoder` 使用
