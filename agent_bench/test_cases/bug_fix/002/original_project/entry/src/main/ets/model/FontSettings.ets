import { PersistenceV2 } from '@kit.ArkUI'

@ObservedV2
class FontSettings {
  fontSize: number = 16
}

const FONT_SETTINGS_KEY: string = 'fontSettings'

function getFontSettings(): FontSettings {
  return PersistenceV2.connect(FontSettings, FONT_SETTINGS_KEY, () => new FontSettings()) ?? new FontSettings()
}

export { FontSettings, FONT_SETTINGS_KEY, getFontSettings }
