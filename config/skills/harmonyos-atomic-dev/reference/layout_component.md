# Layout Component

### Column - Vertical Layout

```typescript
Column() {
  Text('Header')
    .fontSize(24)
    .fontWeight(FontWeight.Bold)

  Text('Content goes here')
    .fontSize(16)
    .margin({ top: 12 })

  Button('Action')
    .margin({ top: 24 })
}
.width('100%')
.padding(16)
.alignItems(HorizontalAlign.Center)  // Horizontal alignment
.justifyContent(FlexAlign.SpaceBetween)  // Vertical spacing
.height('100%')
```

### Row - Horizontal Layout

```typescript
Row() {
  Image($r('app.media.avatar'))
    .width(48)
    .height(48)
    .borderRadius(24)

  Column() {
    Text('Username')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
    Text('user@example.com')
      .fontSize(14)
      .fontColor('#8E8E93')
      .margin({ top: 4 })
  }
  .margin({ left: 12 })
  .alignItems(HorizontalAlign.Start)
  .layoutWeight(1)  // Take remaining space

  Image($r('app.media.arrow_right'))
    .width(16)
    .height(16)
}
.width('100%')
.padding(16)
.backgroundColor(Color.White)
.borderRadius(12)
.onClick(() => {
  // Handle click
})
```

### Flex - Flexible Layout

```typescript
Flex({
  direction: FlexDirection.Row,
  wrap: FlexWrap.Wrap,
  justifyContent: FlexAlign.SpaceAround,
  alignItems: ItemAlign.Center
}) {
  ForEach(this.items, (item: Item) => {
    Text(item.name)
      .padding(12)
      .backgroundColor('#F0F0F0')
      .borderRadius(8)
      .margin(4)
  })
}
.width('100%')
.padding(16)
```

### Stack - Overlapping Layout

```typescript
Stack({ alignContent: Alignment.TopEnd }) {
  // Background image
  Image($r('app.media.card_bg'))
    .width('100%')
    .height(200)
    .objectFit(ImageFit.Cover)

  // Content overlay
  Column() {
    Text('Card Title')
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
    Text('Subtitle')
      .fontSize(14)
      .fontColor('#E0E0E0')
      .margin({ top: 8 })
  }
  .width('100%')
  .padding(16)
  .alignItems(HorizontalAlign.Start)

  // Badge on top right
  Text('NEW')
    .fontSize(12)
    .fontColor(Color.White)
    .backgroundColor('#FF3B30')
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .borderRadius(12)
    .margin(12)
}
.width('100%')
.height(200)
.borderRadius(12)
```

### Relative - Relative Layout

```typescript
RelativeContainer() {
  // Anchor element
  Rectangle()
    .width(100)
    .height(100)
    .fill('#007AFF')
    .id('anchor')

  // Position relative to anchor
  Rectangle()
    .width(50)
    .height(50)
    .fill('#FF3B30')
    .alignRules({
      top: { anchor: 'anchor', align: VerticalAlign.Bottom },
      left: { anchor: 'anchor', align: HorizontalAlign.End }
    })
}
.width('100%')
.height(200)
```
