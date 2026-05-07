/**
 * device-version — 设备版本检测场景
 * @ohos.deviceInfo 模块 — OS版本解析（通过 osFullName 字符串解析）
 * 元服务API: brand(API 11+) / productModel(API 11+) / osFullName(API 11+) / sdkApiVersion(API 14+)
 * 注意: majorVersion/seniorVersion/featureVersion/buildVersion/ODID/distributionOS* 在元服务中不可用
 */
import deviceInfo from '@ohos.deviceInfo'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct DeviceVersion {
  @Local resultText: string = '点击按钮查询版本信息'
  @Local osFullName: string = '--'
  @Local versionParsed: string = '--'
  @Local sdkApiVersion: string = '--'
  @Local brand: string = '--'
  @Local model: string = '--'
  @Local versionCompareResult: string = '--'
  @Local targetVersion: string = '5.0.0.1'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('设备版本检测')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('deviceInfo.osFullName(解析版本号) / sdkApiVersion / brand / productModel')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 结果展示
        Column({ space: 8 }) {
          Text('查询结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.resultText)
            .fontSize(13)
            .fontColor(this.resultText.includes('成功') ? '#00B578' :
              (this.resultText.includes('失败') || this.resultText.includes('错误') ? '#E84026' : '#333333'))
            .width('100%')
          Row() {
            Text('品牌: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.brand)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('型号: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.model)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('系统版本: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.osFullName)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('版本解析: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.versionParsed)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('SDK版本: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.sdkApiVersion)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 版本比较区域
        Column({ space: 8 }) {
          Text('版本比较工具 (基于 osFullName 解析)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 8 }) {
            Text('目标版本:')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ text: this.targetVersion, placeholder: '如 5.0.0.1' })
              .fontSize(12)
              .layoutWeight(1)
              .height(36)
              .onChange((value: string) => {
                this.targetVersion = value
              })
          }
          .width('100%')
          Text(this.versionCompareResult)
            .fontSize(12)
            .fontColor(this.versionCompareResult.includes('不低于') ? '#00B578' : '#E84026')
            .width('100%')
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('查询版本信息')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQueryVersion())
          Button('版本比较')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doCompareVersion())
        }
        .width('90%')

        // 不支持的API警告
        Column() {
          Text('元服务不支持的字段')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B00')
            .width('100%')
            .margin({ bottom: 4 })
          Text('以下 deviceInfo 字段在元服务中不可用（编译错误 11706010）:')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
            .margin({ bottom: 4 })
          Text('- majorVersion / seniorVersion / featureVersion / buildVersion')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('  替代: 从 osFullName 字符串手动解析版本号')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('- osReleaseType (Canary/Beta/Release)')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('  替代: 从 osFullName 末尾括号内容判断')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('- ODID (开发者匿名设备标识符)')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('  替代: 应用级 UUID 存储到首选项')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
          Text('- distributionOSName / distributionOSVersion / distributionOSApiVersion')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('  替代: 使用 osFullName 和 sdkApiVersion')
            .fontSize(12)
            .fontColor('#00B578')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务中仅 osFullName / brand / productModel / sdkApiVersion 可用')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 版本号需从 osFullName 字符串中解析，如 "HarmonyOS-5.0.0.1(Canary1)"')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. sdkApiVersion 从 API 14 开始支持元服务')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 建议用于特性检测、兼容性判断、SDK版本适配等场景')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import deviceInfo from "@ohos.deviceInfo"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 元服务可用字段 (同步API，无需权限)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.osFullName     // "HarmonyOS-5.0.0.1(Canary1)"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.brand          // "HUAWEI" (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.productModel   // "NOH-AN00" (API 11+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.sdkApiVersion  // 12 (API 14+)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('deviceInfo.deviceType     // "phone"/"tablet"/"2in1"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 版本号解析方法 (替代不可用的 majorVersion 等)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// osFullName格式: "HarmonyOS-x.x.x.x(Type)"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const ver = osFullName.split("-")[1]?.split("(")[0]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// ver = "5.0.0.1" => [5, 0, 0, 1]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务可用: osFullName(11+) / brand(11+) / productModel(11+) / deviceType / sdkApiVersion(14+)')
            .fontSize(12)
            .fontColor('#00B578')
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private parseVersionString(osFullName: string): number[] {
    // osFullName format: "HarmonyOS-5.0.0.1(Canary1)" or "OpenHarmony-5.0.0.1"
    const parts: string[] = osFullName.split('-')
    if (parts.length < 2) {
      return [0, 0, 0, 0]
    }
    const versionPart: string = parts[1].split('(')[0].trim()
    return versionPart.split('.').map((v: string) => parseInt(v) || 0)
  }

  private doQueryVersion(): void {
    try {
      this.brand = deviceInfo.brand || '--'
      this.model = deviceInfo.productModel || '--'
      this.osFullName = deviceInfo.osFullName || '--'
      this.sdkApiVersion = `${deviceInfo.sdkApiVersion ?? '--'}`

      const versions: number[] = this.parseVersionString(deviceInfo.osFullName || '')
      this.versionParsed =
        `Major=${versions[0]}, Senior=${versions[1]}, Feature=${versions[2]}, Build=${versions[3]} (从osFullName解析)`

      this.resultText = '版本信息查询成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询失败: [${err.code}] ${err.message}`
    }
  }

  private doCompareVersion(): void {
    try {
      const currentVersions: number[] = this.parseVersionString(deviceInfo.osFullName || '')
      const currentStr: string = currentVersions.join('.')
      const parts: number[] = this.targetVersion.split('.').map((v: string) => parseInt(v) || 0)

      let comparison: string = ''
      let isGreaterOrEqual: boolean = true
      for (let i = 0; i < 4; i++) {
        const target: number = parts[i] ?? 0
        const current: number = currentVersions[i] ?? 0
        if (current > target) {
          comparison = `当前版本 (${currentStr}) > 目标版本 (${this.targetVersion})`
          break
        } else if (current < target) {
          comparison = `当前版本 (${currentStr}) < 目标版本 (${this.targetVersion})`
          isGreaterOrEqual = false
          break
        }
      }
      if (!comparison) {
        comparison = `当前版本 (${currentStr}) = 目标版本 (${this.targetVersion})`
      }

      this.versionCompareResult =
        `${comparison}\n${isGreaterOrEqual ? '当前版本不低于目标版本' : '当前版本低于目标版本'}`
    } catch (error) {
      const err = error as BusinessError
      this.versionCompareResult = `比较失败: [${err.code}] ${err.message}`
    }
  }
}
