/**
 * subpackaging-bundle-info — 分包信息查询
 * @ohos.bundle.bundleManager — 查询当前应用的 Bundle/Module 信息
 * 元服务API: getBundleInfoForSelf 不需要权限
 */
import bundleManager from '@ohos.bundle.bundleManager'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct SubpackagingBundleInfo {
  @Local resultText: string = '点击按钮查询分包/Bundle 信息'
  @Local bundleName: string = '--'
  @Local versionName: string = '--'
  @Local entryModuleName: string = '--'
  @Local appInfo: string = '--'
  @Local reqPermissions: string = '--'
  @Local moduleInfo: string = '--'
  @Local installTime: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('分包信息查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('bundleManager.getBundleInfoForSelf() / getBundleInfo()')
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
            Text('包名: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.bundleName)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('版本: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.versionName)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('入口模块: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.entryModuleName)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('安装时间: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.installTime)
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

        // 详细信息
        Column({ space: 8 }) {
          Text('Module 信息')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.moduleInfo)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .maxLines(8)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 权限信息
        Column({ space: 8 }) {
          Text('申请权限')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(this.reqPermissions)
            .fontSize(12)
            .fontColor('#333333')
            .width('100%')
            .maxLines(8)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Row({ space: 12 }) {
          Button('查询默认信息')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQueryDefault())
          Button('查询完整信息')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doQueryFull())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('查询权限信息')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doQueryPermissions())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. getBundleInfoForSelf() 不需要任何权限即可调用')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. 分包（Subpackaging）是构建期配置，运行时通过 bundleManager 查询分包结果')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. GET_BUNDLE_INFO_DEFAULT 返回基本信息，GET_BUNDLE_INFO_WITH_APPLICATION 返回完整信息')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. 元服务中仅能查询自身应用信息，不能查询其他应用')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
        }
        .width('90%')
        .backgroundColor('#FFF3CD')
        .borderRadius(8)
        .padding(12)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import bundleManager from "@ohos.bundle.bundleManager"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 查询自身 Bundle 信息（无需权限）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let bundleInfo = await bundleManager.getBundleInfoForSelf(')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text(')')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 包含权限信息')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_PERMISSIONS')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: getBundleInfoForSelf 无需权限')
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

  private doQueryDefault(): void {
    try {
      bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
        .then((data: bundleManager.BundleInfo) => {
          this.bundleName = data.name
          this.versionName = `v${data.versionName} (${data.versionCode})`
          this.entryModuleName = data.appInfo?.label || '--'
          this.installTime = data.installTime ? new Date(data.installTime).toLocaleString() : '--'
          this.resultText = '查询成功 (DEFAULT)'
        })
        .catch((err: BusinessError) => {
          this.resultText = `查询失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }

  private doQueryFull(): void {
    try {
      bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .then((data: bundleManager.BundleInfo) => {
          this.bundleName = data.name
          this.versionName = `v${data.versionName} (${data.versionCode})`
          this.entryModuleName = data.appInfo?.label || '--'
          this.installTime = data.installTime ? new Date(data.installTime).toLocaleString() : '--'
          if (data.appInfo) {
            this.appInfo = `label: ${data.appInfo.label}\nicon: ${data.appInfo.icon}`
          }
          const modules = data.hapModulesInfo
          if (modules && modules.length > 0) {
            this.moduleInfo = modules.map((m: bundleManager.HapModuleInfo) =>
              `${m.name} (type: ${m.type}, distro: ${m.name})`
            ).join('\n')
          }
          this.resultText = '查询成功 (WITH_APPLICATION)'
        })
        .catch((err: BusinessError) => {
          this.resultText = `查询失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }

  private doQueryPermissions(): void {
    try {
      bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION)
        .then((data: bundleManager.BundleInfo) => {
          this.bundleName = data.name
          this.versionName = `v${data.versionName} (${data.versionCode})`
          const perms = data.reqPermissionDetails
          if (perms && perms.length > 0) {
            this.reqPermissions = perms.map((p: bundleManager.ReqPermissionDetail) => p.name).join('\n')
          } else {
            this.reqPermissions = '未申请任何权限'
          }
          this.resultText = '权限信息查询成功'
        })
        .catch((err: BusinessError) => {
          this.resultText = `查询失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }
}
