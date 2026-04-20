# Basic Components

```typescript
// Text
Text('Hello World')
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
  .fontColor('#333333')
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })

// Image
Image($r('app.media.icon'))
  .width(100)
  .height(100)
  .objectFit(ImageFit.Cover)
  .borderRadius(8)

// Button
Button('Click Me')
  .type(ButtonType.Capsule)
  .width(200)
  .height(48)
  .fontSize(16)
  .onClick(() => {
    console.info('Button clicked');
  })

// TextInput
TextInput({ placeholder: 'Enter text' })
  .width('100%')
  .height(48)
  .type(InputType.Normal)
  .onChange((value: string) => {
    this.inputValue = value;
  })

// TextArea
TextArea({ placeholder: 'Enter multiple lines' })
  .width('100%')
  .height(100)
  .placeholderColor('#999999')

// Toggle
Toggle({ type: ToggleType.Switch, isOn: false })
  .onChange((isOn: boolean) => {
    this.isEnabled = isOn;
  })

// CheckBox / Radio
CheckBox({ name: 'check1', group: 'group1' })
  .select(true)
  .onChange((isChecked: boolean) => {
    console.info(`Checked: ${isChecked}`);
  })

// Progress
Progress({ value: 50, total: 100, type: ProgressType.Linear })
  .width('100%')
  .color('#007AFF')

// LoadingProgress
LoadingProgress()
  .width(50)
  .height(50)
  .color('#007AFF')
```
