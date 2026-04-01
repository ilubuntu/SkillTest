// 修复: @ObservedV2 类中字体大小属性添加 @Trace 修饰，使用Navigation声明式导航
// 页面A：设置页面

import { FontSettings, getFontSettings } from '../model/FontSettings'
import { FontSettingPage } from './FontSettingPage'

@Entry
@Component
struct Index {
  settings: FontSettings = getFontSettings()
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack()

  build() {
    Navigation() {
      Column() {
        List() {
          ListItem() {
            Row() {
              Text('字体大小')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Text('设置')
                .fontSize(this.settings.fontSize)
                .fontColor('#007DFF')

              Text(' >')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .onClick(() => {
              this.pathStack.pushPathByName('FontSettingPage', null)
            })
          }

          ListItem() {
            Row() {
              Text('其他设置项1')
                .fontSize(16)
                .fontColor('#333333')
              Text(' >')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          }

          ListItem() {
            Row() {
              Text('其他设置项2')
                .fontSize(16)
                .fontColor('#333333')
              Text(' >')
                .fontSize(14)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')

        Column() {
          Text('预览文本')
            .fontSize(this.settings.fontSize)
            .fontColor('#333333')
            .textAlign(TextAlign.Center)
            .padding(16)

          Text(`当前字体大小: ${this.settings.fontSize}`)
            .fontSize(12)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .backgroundColor('#F7F8FA')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')
    }
    .title('设置')
    .titleMode(NavigationTitleMode.Mini)
  }
}

@Builder
function PageMap(name: string) {
  if (name === 'FontSettingPage') {
    FontSettingPageBuilder()
  }
}

@Builder
export function FontSettingPageBuilder() {
  FontSettingPage()
}
