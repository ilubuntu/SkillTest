/**
 * radio-event — Radio 事件处理
 * 展示 Radio 组件的 onChange 事件回调处理
 * 元服务兼容性：onChange 回调 元服务 API 11+ 可用
 */
@ComponentV2
export struct RadioEvent {
  @Local selectedMode: string = '未选择'
  @Local eventLog: string = '点击 Radio 触发 onChange 事件'
  @Local eventCount: number = 0

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('Radio 事件处理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 结果展示区
        Column() {
          Text(`当前选择: ${this.selectedMode}`)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // 统计区
        Column() {
          Text(`事件触发次数: ${this.eventCount}`)
            .fontSize(14)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(8)
        }
        .width('90%')
        .backgroundColor('#E3F2FD')
        .borderRadius(8)

        // 主题选择场景
        Column() {
          Text('场景: 主题色选择')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Radio({ value: 'light', group: 'themeSelect' })
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = '浅色主题 (Light)'
                      this.eventLog = `onChange(true) → 切换到浅色主题，第 ${this.eventCount} 次事件`
                    } else {
                      this.eventLog = `onChange(false) → Light 取消选中，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('浅色')
                .fontSize(12)
            }

            Column({ space: 4 }) {
              Radio({ value: 'dark', group: 'themeSelect' })
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = '深色主题 (Dark)'
                      this.eventLog = `onChange(true) → 切换到深色主题，第 ${this.eventCount} 次事件`
                    } else {
                      this.eventLog = `onChange(false) → Dark 取消选中，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('深色')
                .fontSize(12)
            }

            Column({ space: 4 }) {
              Radio({ value: 'auto', group: 'themeSelect' })
                .height(50)
                .width(50)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = '跟随系统 (Auto)'
                      this.eventLog = `onChange(true) → 切换到跟随系统，第 ${this.eventCount} 次事件`
                    } else {
                      this.eventLog = `onChange(false) → Auto 取消选中，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('自动')
                .fontSize(12)
            }
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 语言选择场景
        Column() {
          Text('场景: 语言偏好设置')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Column({ space: 12 }) {
            Row({ space: 12 }) {
              Radio({ value: 'zh', group: 'langSelect' })
                .height(40)
                .width(40)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = '中文'
                      this.eventLog = `语言切换 → 中文，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('中文 (简体)')
                .fontSize(14)
            }

            Row({ space: 12 }) {
              Radio({ value: 'en', group: 'langSelect' })
                .height(40)
                .width(40)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = 'English'
                      this.eventLog = `语言切换 → English，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('English')
                .fontSize(14)
            }

            Row({ space: 12 }) {
              Radio({ value: 'ja', group: 'langSelect' })
                .height(40)
                .width(40)
                .onChange((isChecked: boolean) => {
                  try {
                    this.eventCount++
                    if (isChecked) {
                      this.selectedMode = '日本語'
                      this.eventLog = `语言切换 → 日本語，第 ${this.eventCount} 次事件`
                    }
                  } catch (err) {
                    this.eventLog = `错误: ${(err as BusinessError).message}`
                  }
                })
              Text('日本語')
                .fontSize(14)
            }
          }
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })

        // 重置按钮
        Button('重置计数器')
          .width('90%')
          .height(40)
          .backgroundColor('#FF9800')
          .onClick(() => {
            this.eventCount = 0
            this.selectedMode = '未选择'
            this.eventLog = '计数器已重置'
          })

        // 事件日志区
        Column() {
          Text(this.eventLog)
            .fontSize(12)
            .fontColor('#666666')
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .backgroundColor('#F0F0F0')
        .borderRadius(8)

        // API 说明区
        Column() {
          Text('API 说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 8 })
          Text('onChange(callback: (isChecked: boolean) => void)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('isChecked=true: 从未选中变为选中')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('isChecked=false: 从选中变为未选中')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
            .width('100%')
          Text('注意: 同组 Radio 切换时，旧选中项先触发 false，新选中项触发 true')
            .fontSize(12)
            .fontColor('#FF6B6B')
            .fontFamily('monospace')
            .width('100%')
            .margin({ top: 4 })
          Text('元服务兼容: onChange API 11+ 可用')
            .fontSize(12)
            .fontColor('#4CAF50')
            .width('100%')
            .margin({ top: 4 })
        }
        .width('90%')
        .backgroundColor('#FFF9E6')
        .borderRadius(8)
        .padding(12)
        .margin({ top: 8, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
