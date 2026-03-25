import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { DEFAULT_SETTING, SettingKey } from './SettingsModel';

export class Settings {
  private SettingPreferences?: preferences.Preferences;

  async initPreference(context: Context): Promise<void> {
    try {
      let options: preferences.Options = { name: 'Settings' };
      this.SettingPreferences = await preferences.getPreferences(context, options);
    } catch (error) {
      console.error(`Failed to invoke Preferencs.getPreferences. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
  }

  async putSetting(key: SettingKey, value: preferences.ValueType) {
    if (this.SettingPreferences) {
      try {
        await this.SettingPreferences.put(key, value);
        await this.SettingPreferences.flush();
      } catch (error) {
        console.error(`Failed to put setting, key=${key}, value=${value}. Cause: ${JSON.stringify(error)}.`);
      }
    }
  }

  async getSetting(key: SettingKey): Promise<preferences.ValueType> {
    if (this.SettingPreferences) {
      try {
        let setting = await this.SettingPreferences.get(key, DEFAULT_SETTING.get(key));
        return setting;
      } catch (error) {
        console.error(`Failed to get setting, key=${key}. Cause: ${JSON.stringify(error)}.`);
      }
    }
    throw new Error('Setting preference is null');
  }
}