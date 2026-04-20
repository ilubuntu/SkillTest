# ArkTS/ArkUI 代码示例参考

本文件包含 ArkTS/ArkUI 的常用代码示例，供生成 PRD 设计方案时参考。

## 1. ArkTS 声明式 UI 基础

**代码示例结构**：
- 使用 `@ComponentV2` 装饰器定义组件
- 使用 `@Local`、`@Param` 进行状态管理
- 使用 `build()` 方法构建 UI

## 2. ArkUI 容器组件

### Column（纵向布局）

```typescript
Column() {
  Text('标题')
    .fontSize(24)
    .fontWeight(FontWeight.Bold)
  Text('内容')
    .fontSize(16)
    .fontColor($r('app.color.text_secondary'))
}
.width('100%')
.padding({ top: 16, bottom: 16 })
```

### Row（横向布局）

```typescript
Row() {
  Text('左侧内容')
  Blank()
  Text('右侧内容')
}
.width('100%')
.padding(16)
```

### Stack（堆叠布局）

```typescript
Stack({ alignContent: Alignment.TopEnd }) {
  Image($r('app.media.background'))
    .width('100%')
    .height(200)
  Text('覆盖文字')
    .fontSize(18)
    .fontColor(Color.White)
}
.width('100%')
.height(200)
```

### Grid（网格布局）

```typescript
Grid() {
  ForEach(this.dataArray, (item: DataType) => {
    GridItem() {
      Text(item.title)
    }
  })
}
.columnsTemplate('1fr 1fr')
.rowsTemplate('1fr 1fr')
.columnsGap(8)
.rowsGap(8)
```

## 3. ArkUI 高级组件

### List（列表）

```typescript
List({ space: 8 }) {
  ForEach(this.items, (item: Item) => {
    ListItem() {
      Row() {
        Text(item.title)
        Blank()
        Text(item.subtitle)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
    }
  })
}
.width('100%')
.height('100%')
```

### Tabs（标签页）

```typescript
Tabs({ barPosition: BarPosition.Start }) {
  TabContent() {
    Column() {
      Text('内容1')
    }
  }
  .tabBar('标签1')

  TabContent() {
    Column() {
      Text('内容2')
    }
  }
  .tabBar('标签2')
}
.barHeight(48)
```

### Navigation（导航）

```typescript
@Builder
PageMap(name: string) {
  Column() {
    Text(name)
  }
}

Navigation(this.pageStack) {
  Column() {
    Text('首页')
  }
}
.navDestination(this.PageMap)
.title('Nav')
```

### Dialog（对话框）

```typescript
AlertDialog.show({
  title: '提示',
  message: '确定要执行此操作吗？',
  autoCancel: true,
  confirm: {
    value: '确定',
    action: () => {
      // 确定操作
    }
  },
  cancel: () => {
    // 取消操作
  }
})
```

## 4. ArkUI 样式系统

### 全局样式（@Styles）

```typescript
@Styles
function cardStyle() {
  .backgroundColor($r('app.color.white'))
  .borderRadius(12)
  .padding(16)
  .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)' })
}

// 使用
Column() {
  Text('卡片内容')
}
.cardStyle()
```

### 扩展样式（@Extend）

```typescript
@Extend(Text)
function primaryText() {
  .fontSize(16)
  .fontColor($r('app.color.primary'))
  .fontWeight(FontWeight.Medium)
}

// 使用
Text('主标题')
  .primaryText()
```

## 5. 状态管理

```typescript
@ComponentV2
struct MyComponent {
  @Local message: string = 'Hello'
  @Param title: string = ''
  @Param counter: number = 0

  build() {
    Column() {
      Text(this.title)
      Text(this.message)
      Button('点击')
        .onClick(() => {
          this.message = 'World'
        })
    }
  }
}
```

## 6. ArkUI 动效系统

### 属性动画

```typescript
@ComponentV2
struct AnimationExample {
  @Local rotateAngle: number = 0

  build() {
    Column() {
      Image($r('app.media.icon'))
        .width(50)
        .height(50)
        .rotate({ angle: this.rotateAngle })
        .animation({
          duration: 500,
          curve: Curve.EaseInOut
        })
      Button('旋转')
        .onClick(() => {
          this.rotateAngle += 90
        })
    }
  }
}
```

### 转场动画

```typescript
pageTransition() {
  PageTransitionEnter({ duration: 300 })
    .slide(SlideEffect.Right)
  PageTransitionExit({ duration: 300 })
    .slide(SlideEffect.Left)
}
```

## 7. 综合示例：商品卡片组件

```typescript
@ComponentV2
export struct ProductCard {
  @Param productName: string = ''
  @Param productPrice: string = ''
  @Local isFavorite: boolean = false

  build() {
    Column() {
      Image($r('app.media.product_default'))
        .width('100%')
        .height(120)
        .borderRadius({ topLeft: 12, topRight: 12 })

      Column() {
        Text(this.productName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(`¥${this.productPrice}`)
            .fontSize(18)
            .fontColor($r('app.color.primary'))
            .fontWeight(FontWeight.Bold)

          Blank()

          Image($r('app.media.ic_favorite'))
            .width(24)
            .height(24)
            .fillColor(this.isFavorite ? $r('app.color.favorite') : $r('app.color.text_secondary'))
            .onClick(() => {
              this.isFavorite = !this.isFavorite
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)' })
  }
}
```
