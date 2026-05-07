/**
 * appgallery-review — 应用内评论 (In-App Review)
 * @ohos.appgallery / @kit.StoreKit 的 ReviewManager
 * 元服务API: 支持应用内弹窗邀请用户评分和评论
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct AppgalleryReview {
  @Local reviewStatus: string = '点击按钮发起应用内评论'
  @Local isLoading: boolean = false
  @Local eventLog: string[] = []

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('应用内评论 (In-App Review)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('ReviewManager.launchReview() 拉起应用内评分评论弹窗')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 状态卡片
        Column({ space: 8 }) {
          Text('状态:')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.isLoading ? '处理中...' : this.reviewStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.reviewStatus.includes('成功') ? '#00B578' :
              (this.reviewStatus.includes('失败') || this.reviewStatus.includes('错误') ? '#E84026' : '#333333'))
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // 操作按钮
        Text('操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Button('发起应用内评论')
          .width('85%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.launchReview()
          })

        // 评论流程说明
        Column({ space: 6 }) {
          Text('应用内评论流程:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('1. 创建 ReviewManager 实例')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. 调用 launchReview() 拉起系统评论弹窗')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. 用户在弹窗中完成评分和评论')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. 评论提交后系统自动关闭弹窗')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 使用建议
        Column({ space: 6 }) {
          Text('使用建议:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('- 在用户体验良好的时机弹出（如完成任务后）')
            .fontSize(12)
            .fontColor('#666666')
          Text('- 不要频繁弹出，避免打扰用户')
            .fontSize(12)
            .fontColor('#666666')
          Text('- 系统会根据用户行为决定是否展示评论弹窗')
            .fontSize(12)
            .fontColor('#666666')
          Text('- 评论内容由用户自主填写，开发者无法预填')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // 事件日志
        Text('事件日志')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        if (this.eventLog.length === 0) {
          Text('暂无事件记录')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
        } else {
          ForEach(this.eventLog, (item: string, index: number) => {
            Text(item)
              .fontSize(12)
              .fontColor('#333333')
              .width('90%')
              .padding(8)
              .backgroundColor('#F9F9F9')
              .borderRadius(6)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }, (item: string, index: number) => `${index}`)
        }

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { review } from "@kit.StoreKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 创建 ReviewManager')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('const reviewManager = review.createReviewManager(this.context)')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 拉起应用内评论弹窗')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('await reviewManager.launchReview()')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
          Text('元服务API: 支持应用内评论，需在 AppGallery Connect 配置')
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

  /**
   * 发起应用内评论
   */
  private launchReview(): void {
    this.isLoading = true
    this.reviewStatus = '正在拉起评论弹窗...'
    try {
      // review 模块在原子化服务中不可用
      this.isLoading = false
      this.reviewStatus = '原子化服务不支持应用内评论 (review)'
      this.addLog('原子化服务不支持 review 模块')
    } catch (error) {
      this.isLoading = false
      const err = error as BusinessError
      this.reviewStatus = `评论异常: [${err.code}] ${err.message}`
      this.addLog(`异常: [${err.code}] ${err.message}`)
    }
  }

  private addLog(msg: string): void {
    const time = new Date().toLocaleTimeString()
    this.eventLog = [`[${time}] ${msg}`, ...this.eventLog].slice(0, 15)
  }
}
