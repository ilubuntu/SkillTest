// 引入包名
import connection from '@ohos.net.connection';
import { BusinessError } from '@kit.BasicServicesKit';

let netSpecifier: connection.NetSpecifier = {
  netCapabilities: {
    // 假设当前默认网络是Wi-Fi，需要创建蜂窝网络连接，可指定网络类型为蜂窝网
    bearerTypes: [connection.NetBearType.BEARER_CELLULAR],
    // 指定网络能力为Internet
    networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET]
  },
};

// 指定超时时间为10s(默认值为0)
let timeout = 10 * 1000;

// 创建NetConnection对象
let conn = connection.createNetConnection(netSpecifier, timeout);

// 订阅指定网络状态变化的通知
conn.register((err: BusinessError, data: void) => {
  console.log(JSON.stringify(err));
});

// 订阅事件，如果当前指定网络可用，通过on_netAvailable通知用户
conn.on('netAvailable', ((data: connection.NetHandle) => {
  console.log("net is available, netId is " + data.netId);
}));

// 订阅事件，如果当前指定网络不可用，通过on_netUnavailable通知用户
conn.on('netUnavailable', ((data: void) => {
  console.log("net is unavailable, data is " + JSON.stringify(data));
}));

// 当不使用该网络时，可以调用该对象的unregister()方法，取消订阅
conn.unregister((err: BusinessError, data: void) => {
});