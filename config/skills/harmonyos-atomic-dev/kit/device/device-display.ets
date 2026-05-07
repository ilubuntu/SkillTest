/**
 * device-display — 屏幕显示信息查询场景
 * @ohos.display 模块 — 屏幕宽度、高度、密度、方向等
 * 元服务API: 需申请 ohos.permission.GET_DISPLAY_INFO（部分接口）
 */
import display from '@ohos.display'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct DeviceDisplay {
  @Local resultText: string = '点击按钮查询屏幕信息'
  @Local screenWidth: string = '--'
  @Local screenHeight: string = '--'
  @Local physicalWidth: string = '--'
  @Local physicalHeight: string = '--'
  @Local densityDPI: string = '--'
  @Local densityPixels: string = '--'
  @Local scaledDensity: string = '--'
  @Local orientation: string = '--'
  @Local refreshRate: string = '--'
  @Local screenDensity: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('屏幕显示信息')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('display.getDefaultDisplaySync() / getDefaultDisplay() / getAllDisplays()')
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
            Text('屏幕宽度(vp): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.screenWidth)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('屏幕高度(vp): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.screenHeight)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('物理宽度(px): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.physicalWidth)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('物理高度(px): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.physicalHeight)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('DPI: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.densityDPI)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('密度(densityPixels): ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.densityPixels)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('缩放密度: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.scaledDensity)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('屏幕方向: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.orientation)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('刷新率: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.refreshRate)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('屏幕密度等级: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.screenDensity)
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

        // 操作按钮
        Row({ space: 12 }) {
          Button('同步查询')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQuerySync())
          Button('异步查询')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doQueryAsync())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('查询所有屏幕')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doQueryAllDisplays())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. getDefaultDisplaySync() 为同步方法，直接返回结果')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. getDefaultDisplay() 为异步方法，支持 callback 和 Promise')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. width/height 单位为 vp，需乘以 density 转为 px')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. orientation 值: 0(竖屏)、1(横屏)、2(反向竖屏)、3(反向横屏)')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('5. 建议用于UI自适应布局、多屏幕适配等场景')
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
          Text('import display from "@ohos.display"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 同步获取默认屏幕（推荐）')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let d = display.getDefaultDisplaySync()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.width          // 屏幕宽度(vp)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.height         // 屏幕高度(vp)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.densityDPI     // DPI')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.densityPixels  // 密度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.orientation    // 屏幕方向')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('d.refreshRate    // 刷新率')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('// 异步获取')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('display.getDefaultDisplay(callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 获取所有屏幕')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('display.getAllDisplays(callback)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: getDefaultDisplaySync / getDefaultDisplay 可用')
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

  private parseOrientation(orientation: number): string {
    const orientMap: Record<number, string> = {
      0: '竖屏 (0)',
      1: '横屏 (1)',
      2: '反向竖屏 (2)',
      3: '反向横屏 (3)',
    }
    return orientMap[orientation] || `未知 (${orientation})`
  }

  private parseScreenDensity(density: number): string {
    const densityMap: Record<number, string> = {
      0: 'SDPI (0)',
      1: 'MDPI (120)',
      2: 'HDPI (160)',
      3: 'XHDPI (240)',
      4: 'XXHDPI (320)',
      5: 'XXXHDPI (480)',
      6: 'NONE (6)',
    }
    return densityMap[density] || `自定义 (${density})`
  }

  private fillDisplayInfo(d: display.Display): void {
    this.screenWidth = `${d.width}`
    this.screenHeight = `${d.height}`
    this.physicalWidth = `${Math.round(d.width * d.densityPixels)}`
    this.physicalHeight = `${Math.round(d.height * d.densityPixels)}`
    this.densityDPI = `${d.densityDPI}`
    this.densityPixels = `${d.densityPixels}`
    this.scaledDensity = `${d.scaledDensity}`
    this.orientation = this.parseOrientation(d.orientation)
    this.refreshRate = `${d.refreshRate} Hz`
    this.screenDensity = this.parseScreenDensity(d.densityDPI)
  }

  private doQuerySync(): void {
    try {
      const d: display.Display = display.getDefaultDisplaySync()
      this.fillDisplayInfo(d)
      this.resultText = '同步查询成功'
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `同步查询失败: [${err.code}] ${err.message}`
    }
  }

  private doQueryAsync(): void {
    // getDefaultDisplay 在原子化服务中不支持，使用同步方法替代
    this.doQuerySync()
  }

  private doQueryAllDisplays(): void {
    try {
      display.getAllDisplays((err: BusinessError, data: display.Display[]) => {
        if (!err && data && data.length > 0) {
          const primary: display.Display = data[0]
          this.fillDisplayInfo(primary)
          const names: string = data.map((d: display.Display) => d.name || d.id.toString()).join(', ')
          this.resultText = `查询成功，共 ${data.length} 个屏幕: ${names}`
        } else {
          this.resultText = `查询所有屏幕失败: [${err?.code}] ${err?.message}`
        }
      })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }
}
