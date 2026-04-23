# Push Kit 推送开发指南

Push Kit（推送服务）是华为为 HarmonyOS 应用提供的消息推送能力，支持通过华为Push通道将消息下发至用户设备。元服务（Atomic Service）可以通过 Push Kit 订阅服务通知，实现精准的用户触达。

元服务调用serviceNotification.requestSubscribeNotification()方法发起消息订阅，实现消息推送，示例如下


```ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { serviceNotification } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
const DOMAIN = 0x0000;
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    try {
      // entityIds请替换为待订阅的模板ID
      const entityIds = ['entityId1'];
      serviceNotification.requestSubscribeNotification(this.context, entityIds, (err, data) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'Failed to request subscribe notification: %{public}d %{public}s', err.code,
            err.message);
        } else {
          hilog.info(0x0000, 'testTag', 'Succeeded in requesting subscribe notification: %{public}s',
            JSON.stringify(data.entityResult));
        }
      });
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'testTag', 'Failed to request subscribe notification: %{public}d %{public}s', e.code,
        e.message);
    }
  }
}
```


```ts
import { UIAbility } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { serviceNotification } from '@kit.PushKit';
 
export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the page. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  async requestSubscribeNotification() {
    try {
      // entityIds请替换为待订阅的模板ID
      let entityIds: string[] = ['entityId1'];
      let type: serviceNotification.SubscribeNotificationType =
        serviceNotification.SubscribeNotificationType.SUBSCRIBE_WITH_HUAWEI_ID;
      const res: serviceNotification.RequestResult =
        await serviceNotification.requestSubscribeNotification(this.context, entityIds, type);
      hilog.info(0x0000, 'testTag', 'Succeeded in requesting serviceNotification: %{public}s',
        JSON.stringify(res.entityResult));
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'testTag', 'Failed to request serviceNotification: %{public}d %{public}s', e.code, e.message);
    }
  }
 
  async onForeground(): Promise<void> {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
    try {
      // 请确保加载页面完成，可以获取UIAbilityContext后调用方法
      await this.requestSubscribeNotification();
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(0x0000, 'testTag', 'Request subscribe notification failed: %{public}d %{public}s', e.code, e.message);
    }
  }
}
```


错误示例，请不要接入pushService：
```ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { pushService } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class EntryAbility extends UIAbility {

  private initPushService(): void {
    try {
      pushService.getToken().then((token: string) => {
        hilog.info(DOMAIN, TAG, 'Push token obtained successfully');
        // Send push token to backend server for push notification registration
        // Push template ID: 1AA3E7B89E028500
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Failed to get push token: %{public}s', JSON.stringify(error));
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Push service init failed');
    }
  }
}
```



**注意事项：**

- 不要引入@ohos.pushservice，请使用@kit.PushKit，来引入push kit
- 接入push能力一定需要发起消息订阅，请帮助用户完成消息能力订阅，具体推送功能由用户来进行实现，可以留作TODO项
- 请不要使用pushService来实现推送功能，这些API在鸿蒙元服务中不可用。

**参数说明：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `entityIds` | `string[]` | 消息模板ID数组，单次最多3个，从AppGallery Connect服务通知中领取 |
| `type` | `SubscribeNotificationType` | 订阅类型，元服务固定为 `SUBSCRIBE_WITH_HUAWEI_ID` |
