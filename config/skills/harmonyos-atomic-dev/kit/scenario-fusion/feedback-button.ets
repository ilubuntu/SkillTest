import { FunctionalButton, functionalButtonComponentManager } from "@kit.ScenarioFusionKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

@ComponentV2
export struct FeedBackButton {

  build() {
    Row() {
      Column() {
        // 声明FunctionalButton。
        FunctionalButton({
          params: {
            // OpenType.FEEDBACK表示该按钮用于拉起反馈页面。
            openType: functionalButtonComponentManager.OpenType.FEEDBACK,
            label: '反馈与投诉',
            // 调整按钮样式。
            styleOption: {
              styleConfig: new functionalButtonComponentManager.ButtonConfig()
                .fontSize(20)
            },
          },
          // 当OpenType设置为FEEDBACK时，回调函数必须是onFeedback。
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onFeedback((err) => {
              if (err) {
                // 错误日志处理。
                hilog.error(0x0000, "testTag", "error: %{public}d %{public}s", err.code, err.message);
                return;
              }
              // 成功日志处理。
              hilog.info(0x0000, "testTag", "succeeded in pulling up the feedback page");
            })
        })
      }.width('100%')
    }.height('100%')
  }
}