import { FunctionalButton, functionalButtonComponentManager } from "@kit.ScenarioFusionKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

@ComponentV2
export struct ShareButtonExample {

  build() {
    Row() {
      Column() {
        // 声明FunctionalButton。
        FunctionalButton({
          params: {
            // OpenType.SHARE 表示该按钮用于调出分享页面。
            openType: functionalButtonComponentManager.OpenType.SHARE,
            label: '元服务分享',
            shareParam: {
              previewUri: '',
              description: ''
            },
            // 调整按钮样式。
            styleOption: {
              styleConfig: new functionalButtonComponentManager.ButtonConfig()
                .fontSize(20)
            },
          },
          // 当OpenType设置为SHARE时，回调函数必须是onShare。
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onShare((err) => {
              if (err) {
                // 错误日志处理。
                hilog.error(0x0000, "testTag", "error: %{public}d %{public}s", err.code, err.message);
                return;
              }
              // 成功日志处理。
              hilog.info(0x0000, "testTag", "succeeded in pulling up the sharing page");
            })
        })
      }.width('100%')
    }.height('100%')
  }
}