/**
 * window-info-query — 窗口信息查询
 * @ohos.window — 查询当前窗口属性（尺寸、状态栏、导航栏等）
 * 元服务API: getLastWindow 可获取当前子窗口
 */
import window from '@ohos.window'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct WindowInfoQuery {
  @Local resultText: string = '点击按钮查询窗口信息'
  @Local windowRect: string = '--'
  @Local windowType: string = '--'
  @Local isFullScreen: string = '--'
  @Local isTransparent: string = '--'
  @Local statusBarInfo: string = '--'
  @Local navBarInfo: string = '--'
  @Local windowDensity: string = '--'
  @Local isTouchableFlag: string = '--'
  @Local windowBrightness: string = '--'

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('窗口信息查询')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('window.getLastWindow() / getWindowProperties() / setWindowLayoutFullScreen()')
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
            Text('窗口位置/尺寸: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.windowRect)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('窗口类型: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.windowType)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('全屏模式: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isFullScreen)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('透明: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isTransparent)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('可触摸: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.isTouchableFlag)
              .fontSize(12)
              .layoutWeight(1)
          }
          .width('100%')
          Row() {
            Text('屏幕密度: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.windowDensity)
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

        // 状态栏/导航栏信息
        Column({ space: 8 }) {
          Text('系统栏信息')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row() {
            Text('状态栏: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.statusBarInfo)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row() {
            Text('导航栏: ')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.navBarInfo)
              .fontSize(12)
              .layoutWeight(1)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
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
          Button('查询窗口属性')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .onClick(() => this.doQueryWindowInfo())
          Button('查询系统栏')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .onClick(() => this.doQuerySystemBar())
        }
        .width('90%')

        Row({ space: 12 }) {
          Button('切换全屏')
            .layoutWeight(1)
            .backgroundColor('#FF9800')
            .borderRadius(8)
            .onClick(() => this.doToggleFullScreen())
          Button('设置亮度')
            .layoutWeight(1)
            .backgroundColor('#9C27B0')
            .borderRadius(8)
            .onClick(() => this.doSetBrightness())
        }
        .width('90%')

        // 提示信息
        Column() {
          Text('注意事项')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 4 })
          Text('1. 元服务运行在子窗口中，使用 getLastWindow() 获取当前窗口')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('2. getWindowProperties() 可获取窗口尺寸、类型、密度等属性')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('3. setWindowLayoutFullScreen() 可控制全屏/非全屏布局')
            .fontSize(12)
            .fontColor('#996600')
            .width('100%')
          Text('4. setWindowBrightness() 可调节窗口亮度（0~1）')
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
          Text('import window from "@ohos.window"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 获取当前窗口')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let win = await window.getLastWindow(getContext(this))')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 获取窗口属性')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let props = win.getWindowProperties()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 获取系统栏避让区域')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let avoidArea = win.getAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 设置全屏布局')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('win.setWindowLayoutFullScreen(true)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 设置窗口亮度')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('win.setWindowBrightness(0.8)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
            .fontSize(8)
          Text('元服务API: getLastWindow 可获取当前子窗口实例')
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

  private parseWindowType(type: number): string {
    const typeMap: Record<number, string> = {
      0: 'TYPE_APP',
      1: 'TYPE_MAIN',
      3: 'TYPE_FLOAT',
      4: 'TYPE_DIALOG',
      8: 'TYPE_SYSTEM_ALERT',
    }
    return typeMap[type] || `未知(${type})`
  }

  private doQueryWindowInfo(): void {
    try {
      window.getLastWindow(getContext(this))
        .then((win: window.Window) => {
          const props = win.getWindowProperties()
          const rect = props.windowRect
          this.windowRect = `left=${rect.left}, top=${rect.top}, width=${rect.width}, height=${rect.height}`
          this.windowType = this.parseWindowType(props.type)
          this.isFullScreen = props.isFullScreen ? '是' : '否'
          this.isTransparent = props.isTransparent ? '是' : '否'
          this.isTouchableFlag = props.touchable ? '是' : '否'
          this.windowDensity = `${props.windowRect.width > 0 ? '已获取' : '未知'} (density 属性不可用)`
          this.resultText = '窗口属性查询成功'
        })
        .catch((err: BusinessError) => {
          this.resultText = `查询失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `查询异常: [${err.code}] ${err.message}`
    }
  }

  private doQuerySystemBar(): void {
    // getAvoidArea 在原子化服务中不支持
    this.statusBarInfo = '原子化服务不支持 getAvoidArea'
    this.navBarInfo = '原子化服务不支持 getAvoidArea'
    this.resultText = '系统栏信息不可用 (原子化服务限制)'
  }

  private doToggleFullScreen(): void {
    try {
      window.getLastWindow(getContext(this))
        .then((win: window.Window) => {
          const props = win.getWindowProperties()
          const targetFullScreen = !props.isFullScreen
          win.setWindowLayoutFullScreen(targetFullScreen)
            .then(() => {
              this.isFullScreen = targetFullScreen ? '是' : '否'
              this.resultText = `已切换为${targetFullScreen ? '全屏' : '非全屏'}布局`
            })
            .catch((err: BusinessError) => {
              this.resultText = `切换失败: [${err.code}] ${err.message}`
            })
        })
        .catch((err: BusinessError) => {
          this.resultText = `获取窗口失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `操作异常: [${err.code}] ${err.message}`
    }
  }

  private doSetBrightness(): void {
    try {
      window.getLastWindow(getContext(this))
        .then((win: window.Window) => {
          const newBrightness = 0.8
          win.setWindowBrightness(newBrightness)
            .then(() => {
              this.windowBrightness = `${newBrightness}`
              this.resultText = `亮度已设置为 ${newBrightness}`
            })
            .catch((err: BusinessError) => {
              this.resultText = `设置亮度失败: [${err.code}] ${err.message}`
            })
        })
        .catch((err: BusinessError) => {
          this.resultText = `获取窗口失败: [${err.code}] ${err.message}`
        })
    } catch (error) {
      const err = error as BusinessError
      this.resultText = `操作异常: [${err.code}] ${err.message}`
    }
  }
}
