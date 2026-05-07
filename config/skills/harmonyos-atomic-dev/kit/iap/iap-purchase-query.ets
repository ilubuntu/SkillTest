/**
 * iap-purchase-query — 应用内支付查询与购买
 * @ohos.iap 模块的 queryProducts / createPurchase
 * 元服务API: 用于数字商品支付，支持消耗型、非消耗型、订阅型
 */
import { common } from '@kit.AbilityKit'
import { iap } from '@kit.IAPKit'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct IapPurchaseQuery {
  @Local iapStatus: string = '点击按钮操作'
  @Local productList: string = '暂未查询'
  @Local purchaseResult: string = '--'
  @Local environmentStatus: string = '--'
  @Local selectedType: string = 'consumable'
  @Local isLoading: boolean = false

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('IAP 商品查询与购买')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('iap.queryProducts() / iap.createPurchase()')
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
        .width('90%')

        // 状态卡片
        Column({ space: 8 }) {
          Text('状态:')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.isLoading ? '处理中...' : this.iapStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.iapStatus.includes('成功') ? '#00B578' :
              (this.iapStatus.includes('失败') || this.iapStatus.includes('错误') ? '#E84026' : '#333333'))
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

        Row({ space: 12 }) {
          Button('查询环境')
            .layoutWeight(1)
            .backgroundColor('#00B578')
            .borderRadius(8)
            .enabled(!this.isLoading)
            .onClick(() => {
              this.queryEnvironment()
            })
          Button('查询商品')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .borderRadius(8)
            .enabled(!this.isLoading)
            .onClick(() => {
              this.queryProducts()
            })
        }
        .width('90%')

        Button('发起购买')
          .width('85%')
          .backgroundColor('#FF6B00')
          .borderRadius(8)
          .enabled(!this.isLoading)
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

        // 购买结果
        if (this.purchaseResult !== '--') {
          Text('购买结果:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Text(this.purchaseResult)
            .fontSize(12)
            .fontColor('#333333')
            .width('90%')
            .padding(10)
            .backgroundColor('#E3F2FD')
            .borderRadius(8)
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 环境状态
        if (this.environmentStatus !== '--') {
          Text('环境状态:')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 16, top: 8 })

          Text(this.environmentStatus)
            .fontSize(12)
            .fontColor('#333333')
            .width('90%')
            .padding(10)
            .backgroundColor('#FFF8E1')
            .borderRadius(8)
        }

        // IAP 流程说明
        Column({ space: 6 }) {
          Text('IAP 查询与购买流程:')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
          Text('1. queryEnvironmentStatus — 检查 IAP 环境是否可用')
            .fontSize(12)
            .fontColor('#666666')
          Text('2. queryProducts — 根据商品 ID 和类型查询商品详情')
            .fontSize(12)
            .fontColor('#666666')
          Text('3. createPurchase — 拉起收银台发起购买')
            .fontSize(12)
            .fontColor('#666666')
          Text('4. 服务端验证 purchaseData（生产环境必须）')
            .fontSize(12)
            .fontColor('#666666')
          Text('5. finishPurchase — 确认发货（消耗型商品必须调用）')
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
          Text('import iap from "@ohos.iap"')
            .fontSize(12)
            .fontColor('#007DFF')
            .fontFamily('monospace')
          Text('// 查询商品')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('let products = await iap.queryProducts({')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  productIds: ["com.example.product1"]')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('// 发起购买')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('await iap.createPurchase({')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('  productId: "com.example.product1"')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('})')
            .fontSize(12)
            .fontColor('#666666')
            .fontFamily('monospace')
          Text('')
          Text('商品类型: CONSUMABLE(0) / NONCONSUMABLE(1) / AUTORENEWABLE(2)')
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
    this.isLoading = true
    this.iapStatus = '正在查询环境状态...'
    try {
      iap.queryEnvironmentStatus(this.context).then(() => {
        this.isLoading = false
        this.iapStatus = 'IAP 环境正常'
        this.environmentStatus = 'IAP 环境状态正常，可以进行商品查询和购买操作'
      }).catch((err: BusinessError) => {
        this.isLoading = false
        this.iapStatus = `环境异常: [${err.code}] ${err.message}`
        this.environmentStatus = `异常: ${err.message}`
      })
    } catch (error) {
      this.isLoading = false
      const err = error as BusinessError
      this.iapStatus = `查询异常: [${err.code}] ${err.message}`
    }
  }

  /**
   * 查询商品信息
   */
  private queryProducts(): void {
    this.isLoading = true
    this.iapStatus = '正在查询商品...'
    try {
      const productType = this.getProductType()
      // 测试商品 ID，正式环境替换为实际商品 ID
      const productIds: string[] = ['com.example.product1']
      const parameter: iap.QueryProductsParameter = {
        productType: productType,
        productIds: productIds
      }
      iap.queryProducts(this.context, parameter).then((data: iap.Product[]) => {
        this.isLoading = false
        if (data && data.length > 0) {
          const product = data[0]
          this.productList = `ID: ${product.id}\n名称: ${product.name}\n描述: ${product.description}\n价格: ${product.localPrice} (${product.currency})\n类型: ${product.type}`
          this.iapStatus = `查询成功，共 ${data.length} 个商品`
        } else {
          this.productList = '未查询到商品（请检查商品 ID 是否在 AppGallery Connect 中配置）'
          this.iapStatus = '商品列表为空'
        }
      }).catch((err: BusinessError) => {
        this.isLoading = false
        this.iapStatus = `查询失败: [${err.code}] ${err.message}`
        this.productList = '查询失败'
      })
    } catch (error) {
      this.isLoading = false
      const err = error as BusinessError
      this.iapStatus = `查询异常: [${err.code}] ${err.message}`
    }
  }

  /**
   * 发起购买
   */
  private createPurchase(): void {
    this.isLoading = true
    this.iapStatus = '正在拉起收银台...'
    try {
      const productType = this.getProductType()
      const parameter: iap.PurchaseParameter = {
        productId: 'com.example.product1',
        productType: productType,
        developerPayload: 'test_developer_payload'
      }
      iap.createPurchase(this.context, parameter).then((data: iap.CreatePurchaseResult) => {
        this.isLoading = false
        this.iapStatus = '购买成功'
        this.purchaseResult = data.purchaseData ?? '购买数据为空'
        // 实际开发中需:
        // 1. 将 purchaseData 发送到服务端验证
        // 2. 验证通过后调用 finishPurchase 确认发货
      }).catch((err: BusinessError) => {
        this.isLoading = false
        if (err.code === 1001860000) {
          this.iapStatus = '用户取消购买'
        } else if (err.code === 1001860051) {
          this.iapStatus = '用户已拥有该商品'
        } else {
          this.iapStatus = `购买失败: [${err.code}] ${err.message}`
        }
      })
    } catch (error) {
      this.isLoading = false
      const err = error as BusinessError
      this.iapStatus = `购买异常: [${err.code}] ${err.message}`
    }
  }
}
