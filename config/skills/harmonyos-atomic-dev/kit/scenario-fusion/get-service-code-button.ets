import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 使用服务授权动态码需要申请权限：https://developer.huawei.com/consumer/cn/doc/atomic-guides/push-as-timeline#section592010820304
@ComponentV2
export struct GetServiceCodeButton {

  build() {
    Row() {
      Column() {
        // 声明FunctionalButton。
        FunctionalButton({
          params: {
            // OpenType.REQUEST_SUBSCRIBE_MESSAGE表示该按钮用于获取授权码。
            openType: functionalButtonComponentManager.OpenType.REQUEST_SUBSCRIBE_MESSAGE,
            label: '服务动态授权码',
            // 在获取服务动态授权码时，名为subSceneId的参数是必填项。
            subSceneId: '',
            // 调整按钮样式。
            styleOption: {
              styleConfig: new functionalButtonComponentManager.ButtonConfig()
                .fontSize(20)
            },
          },
          // 当OpenType为REQUEST_SUBSCRIBE_MESSAGE时，回调必须为onRequestSubscribeMessage。
          controller: new functionalButtonComponentManager.FunctionalButtonController()
            .onRequestSubscribeMessage((err, data) => {
              if (err) {
                // 错误日志处理。
                hilog.error(0x0000, "testTag", "error: %{public}d %{public}s", err.code, err.message);
                return;
              }
              // 成功日志处理。
              hilog.info(0x0000, "testTag", "succeeded in requesting subscribe message");
              // 处理服务代码。
              let code = data.code;
            })
        })
      }.width('100%')
      .padding({ left: 16, right: 16 })
    }.height('100%')
  }
}