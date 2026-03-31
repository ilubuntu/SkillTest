import { PersistenceV2 } from '@kit.ArkUI'

@ObservedV2
class FontSettings {
  @Trace fontSize: number = 16
}

PersistenceV2.connect(FontSettings, 'fontSettings', () => new FontSettings())

export { FontSettings }