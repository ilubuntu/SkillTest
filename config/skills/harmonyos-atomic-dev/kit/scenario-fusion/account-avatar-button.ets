import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@ComponentV2
export struct AccountAvatarButtonExample {
  @Local url: ResourceStr = $r('app.media.icon');

  build() {
    Column() {
      // 构建FunctionalButton组件实例。
      FunctionalButton({
        params: {
          // OpenType.CHOOSE_AVATAR表示该按钮用于选择头像。
          openType: functionalButtonComponentManager.OpenType.CHOOSE_AVATAR,
          label: '',
          // 调整按钮样式。
          styleOption: {
            styleConfig: new functionalButtonComponentManager.ButtonConfig()
              .type(ButtonType.Normal)
              .backgroundImage(this.url)
              .backgroundImageSize(ImageSize.Cover)
              .width(80)
              .height(80)
              .backgroundColor('#E5E5E5')
          },
        },
        // 当OpenType设置为CHOOSE_AVATAR时，回调函数必须是onChooseAvatar。
        controller: new functionalButtonComponentManager.FunctionalButtonController().onChooseAvatar((err, data) => {
          if (err) {
            // 错误日志处理。
            hilog.error(0x0000, "testTag", "error: %{public}d %{public}s", err.code, err.message);
            return;
          }
          // 成功日志处理。
          hilog.info(0x0000, "testTag", "succeeded in choosing avatar");
          this.url = data.avatarUri!;
        })
      })
    }
    .padding({ top: 200 })
    .height('100%')
    .width('100%')
  }
}