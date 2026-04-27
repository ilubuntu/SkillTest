/**
 * iap-purchase — 应用内支付（数字商品）
 * 元服务场景：iap.createPurchase / queryProducts / finishPurchase
 * 用于数字商品支付（消耗型、非消耗型、订阅型）
 * 实物商品请使用 Payment Kit（paymentService 模块）
 */
import { common } from '@kit.AbilityKit'
import { iap } from '@kit.IAPKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct IapPurchase {
  @Local iapStatus: string = '点击按钮操作'
  @Local productList: string = '暂未查询'
  @Local purchaseResult: string = '--'
  @Local selectedType: string = 'consumable'

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('应用内支付 (IAP)')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('iap.createPurchase 拉起收银台，用于数字商品')
          .fontSize(13)
          .fontColor('#666666')
          .width('90%')
          .textAlign(TextAlign.Center)

        // 商品类型选择
        Text('商品类型')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Row({ space: 8 }) {
          Button('消耗型')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.selectedType === 'consumable' ? '#007DFF' : '#999999')
            .borderRadius(6)
            .onClick(() => { this.selectedType = 'consumable' })

          Button('非消耗型')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.selectedType === 'nonconsumable' ? '#007DFF' : '#999999')
            .borderRadius(6)
            .onClick(() => { this.selectedType = 'nonconsumable' })

          Button('订阅型')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.selectedType === 'subscription' ? '#007DFF' : '#999999')
            .borderRadius(6)
            .onClick(() => { this.selectedType = 'subscription' })
        }

        // 状态卡片
        Column({ space: 8 }) {
          Text('状态:')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.iapStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
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

        Button('查询环境状态')
          .width('85%')
          .backgroundColor('#00B578')
          .borderRadius(8)
          .onClick(() => {
            this.queryEnvironment()
          })

        Button('查询商品信息')
          .width('85%')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.queryProducts()
          })

        Button('发起购买')
          .width('85%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .onClick(() => {
            this.createPurchase()
          })

        // 商品信息展示
        if (this.productList !== '暂未查询') {
          Text('商品信息:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Text(this.productList)
            .fontSize(12)
            .fontColor('#333333')
            .width('90%')
            .padding(10)
            .backgroundColor('#E8F5E9')
            .borderRadius(8)
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // IAP 流程说明
        Column({ space: 6 }) {
          Text('IAP 支付流程:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('1. queryEnvironmentStatus — 检查环境')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. queryProducts — 查询商品信息')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. createPurchase — 拉起收银台发起购买')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. 服务端验证 purchaseData')
            .fontSize(12)
            .fontColor('#666666')
          Text('5. finishPurchase — 确认发货（消耗型必须）')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('90%')
        .padding(12)
        .backgroundColor('#FFF8F0')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)

        // API 说明
        Text('API 说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 16, top: 8 })

        Column({ space: 4 }) {
          Text('import { iap } from "@kit.IAPKit"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('iap.queryEnvironmentStatus(context)')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('iap.queryProducts(context, { productType, productIds })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('iap.createPurchase(context, { productId, productType })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('iap.finishPurchase(context, { productType, purchaseToken, purchaseOrderId })')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('')
          Text('商品类型: CONSUMABLE(0) / NONCONSUMABLE(1) / AUTORENEWABLE(2) / NONRENEWABLE(3)')
            .fontSize(11)
            .fontColor('#666666')
          Text('')
          Text('关键错误码:')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
          Text('1001860000: 用户取消 | 1001860001: 系统内部错误')
            .fontSize(11)
            .fontColor('#666666')
          Text('1001860050: 未登录华为账号 | 1001860051: 已拥有该商品')
            .fontSize(11)
            .fontColor('#666666')
          Text('1001860054: 地区不支持 IAP')
            .fontSize(11)
            .fontColor('#666666')
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
   * 获取当前选中的商品类型
   */
  private getProductType(): iap.ProductType {
    switch (this.selectedType) {
      case 'consumable':
        return iap.ProductType.CONSUMABLE
      case 'nonconsumable':
        return iap.ProductType.NONCONSUMABLE
      case 'subscription':
        return iap.ProductType.AUTORENEWABLE
      default:
        return iap.ProductType.CONSUMABLE
    }
  }

  /**
   * 查询 IAP 环境状态
   */
  private queryEnvironment(): void {
    this.iapStatus = '正在查询环境状态...'
    iap.queryEnvironmentStatus(this.context).then(() => {
      this.iapStatus = 'IAP 环境正常'
    }).catch((err: BusinessError) => {
      this.iapStatus = `环境异常: [${err.code}] ${err.message}`
    })
  }

  /**
   * 查询商品信息
   */
  private queryProducts(): void {
    this.iapStatus = '正在查询商品...'
    const productType = this.getProductType()
    // 测试商品 ID，正式环境替换为实际商品 ID
    const productIds: string[] = ['testConsumeProduct01']
    const parameter: iap.QueryProductsParameter = {
      productType: productType,
      productIds: productIds
    }
    iap.queryProducts(this.context, parameter).then((data: iap.Product[]) => {
      if (data && data.length > 0) {
        const product = data[0]
        this.productList = `ID: ${product.id}\n名称: ${product.name}\n描述: ${product.description}\n价格: ${product.localPrice} (${product.currency})\n类型: ${product.type}`
        this.iapStatus = `查询到 ${data.length} 个商品`
      } else {
        this.productList = '未查询到商品'
        this.iapStatus = '商品列表为空'
      }
    }).catch((err: BusinessError) => {
      this.iapStatus = `查询失败: [${err.code}] ${err.message}`
      this.productList = '查询失败'
    })
  }

  /**
   * 发起购买
   */
  private createPurchase(): void {
    this.iapStatus = '正在拉起收银台...'
    const productType = this.getProductType()
    const parameter: iap.PurchaseParameter = {
      productId: 'testConsumeProduct01',
      productType: productType,
      developerPayload: 'test_developer_payload'
    }
    iap.createPurchase(this.context, parameter).then((data: iap.CreatePurchaseResult) => {
      this.iapStatus = '购买成功'
      this.purchaseResult = data.purchaseData ?? '购买数据为空'
      // 实际开发中需:
      // 1. 将 purchaseData 发送到服务端验证
      // 2. 验证通过后调用 finishPurchase 确认发货
    }).catch((err: BusinessError) => {
      if (err.code === 1001860000) {
        this.iapStatus = '用户取消购买'
      } else if (err.code === 1001860051) {
        this.iapStatus = '用户已拥有该商品'
      } else {
        this.iapStatus = `购买失败: [${err.code}] ${err.message}`
      }
    })
  }
}
