import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'PreferencesUtils';

/**
 * 用户首选项工具类
 * 基于 HarmonyOS 最新 API，提供轻量级 Key-Value 持久化存储能力
 * 支持同步与异步两种调用方式
 */
export class PreferencesUtils {
  private static instances: Map<string, preferences.Preferences> = new Map();
  private static context: common.UIAbilityContext | null = null;

  /**
   * 初始化，建议在 EntryAbility.onCreate 中调用
   */
  static init(context: common.UIAbilityContext): void {
    PreferencesUtils.context = context;
  }

  private static getContext(): common.UIAbilityContext {
    if (!PreferencesUtils.context) {
      throw new Error('PreferencesUtils 未初始化，请先调用 init(context)');
    }
    return PreferencesUtils.context;
  }

  // ==================== 实例获取 ====================

  /**
   * 异步获取 Preferences 实例
   */
  static async getPreferences(name: string): Promise<preferences.Preferences> {
    const cached = PreferencesUtils.instances.get(name);
    if (cached) {
      return cached;
    }
    const context = PreferencesUtils.getContext();
    const options: preferences.Options = { name };
    const prefs = await preferences.getPreferences(context, options);
    PreferencesUtils.instances.set(name, prefs);
    return prefs;
  }

  /**
   * 同步获取 Preferences 实例（API 10+）
   */
  static getPreferencesSync(name: string): preferences.Preferences {
    const cached = PreferencesUtils.instances.get(name);
    if (cached) {
      return cached;
    }
    const context = PreferencesUtils.getContext();
    const options: preferences.Options = { name };
    const prefs = preferences.getPreferencesSync(context, options);
    PreferencesUtils.instances.set(name, prefs);
    return prefs;
  }

  // ==================== 写入数据 ====================

  /**
   * 异步写入数据
   */
  static async put(name: string, key: string, value: preferences.ValueType): Promise<void> {
    const prefs = await PreferencesUtils.getPreferences(name);
    await prefs.put(key, value);
    await prefs.flush();
  }

  /**
   * 同步写入数据（API 10+）
   */
  static putSync(name: string, key: string, value: preferences.ValueType): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.putSync(key, value);
    prefs.flushSync();
  }

  // ==================== 读取数据 ====================

  /**
   * 异步读取数据
   */
  static async get(name: string, key: string, defValue: preferences.ValueType): Promise<preferences.ValueType> {
    const prefs = await PreferencesUtils.getPreferences(name);
    return prefs.get(key, defValue);
  }

  /**
   * 同步读取数据（API 10+）
   */
  static getSync(name: string, key: string, defValue: preferences.ValueType): preferences.ValueType {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    return prefs.getSync(key, defValue);
  }

  /**
   * 异步获取所有键值对
   */
  static async getAll(name: string): Promise<Object> {
    const prefs = await PreferencesUtils.getPreferences(name);
    return prefs.getAll();
  }

  /**
   * 同步获取所有键值对（API 10+）
   */
  static getAllSync(name: string): Object {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    return prefs.getAllSync();
  }

  // ==================== 删除数据 ====================

  /**
   * 异步删除指定 key
   */
  static async delete(name: string, key: string): Promise<void> {
    const prefs = await PreferencesUtils.getPreferences(name);
    await prefs.delete(key);
    await prefs.flush();
  }

  /**
   * 同步删除指定 key（API 10+）
   */
  static deleteSync(name: string, key: string): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.deleteSync(key);
    prefs.flushSync();
  }

  // ==================== 检查 key ====================

  /**
   * 异步检查 key 是否存在
   */
  static async has(name: string, key: string): Promise<boolean> {
    const prefs = await PreferencesUtils.getPreferences(name);
    return prefs.has(key);
  }

  /**
   * 同步检查 key 是否存在（API 10+）
   */
  static hasSync(name: string, key: string): boolean {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    return prefs.hasSync(key);
  }

  // ==================== 清空数据 ====================

  /**
   * 异步清空所有数据
   */
  static async clear(name: string): Promise<void> {
    const prefs = await PreferencesUtils.getPreferences(name);
    await prefs.clear();
    await prefs.flush();
  }

  /**
   * 同步清空所有数据（API 10+）
   */
  static clearSync(name: string): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.clearSync();
    prefs.flushSync();
  }

  // ==================== 持久化 ====================

  /**
   * 异步刷盘（仅在 XML 存储模式下需要调用）
   */
  static async flush(name: string): Promise<void> {
    const prefs = await PreferencesUtils.getPreferences(name);
    await prefs.flush();
  }

  /**
   * 同步刷盘（API 14+，仅在 XML 存储模式下需要调用）
   */
  static flushSync(name: string): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.flushSync();
  }

  // ==================== 数据变更监听 ====================

  /**
   * 订阅数据变更（flush 后触发）
   */
  static onChange(name: string, callback: (key: string) => void): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.on('change', callback);
  }

  /**
   * 精确订阅指定 key 的数据变更（API 12+）
   */
  static onDataChange(
    name: string,
    keys: Array<string>,
    callback: (data: Record<string, preferences.ValueType>) => void
  ): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.on('dataChange', keys, callback);
  }

  /**
   * 取消订阅数据变更
   */
  static offChange(name: string, callback?: (key: string) => void): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.off('change', callback);
  }

  /**
   * 取消精确订阅数据变更（API 12+）
   */
  static offDataChange(
    name: string,
    keys: Array<string>,
    callback?: (data: Record<string, preferences.ValueType>) => void
  ): void {
    const prefs = PreferencesUtils.getPreferencesSync(name);
    prefs.off('dataChange', keys, callback);
  }

  // ==================== 实例管理 ====================

  /**
   * 从缓存移除实例（不再使用该实例时调用）
   */
  static removePreferencesFromCache(name: string): void {
    const context = PreferencesUtils.getContext();
    preferences.removePreferencesFromCacheSync(context, name);
    PreferencesUtils.instances.delete(name);
  }

  /**
   * 删除 Preferences 持久化文件及缓存
   */
  static async deletePreferences(name: string): Promise<void> {
    const context = PreferencesUtils.getContext();
    const options: preferences.Options = { name };
    await preferences.deletePreferences(context, options);
    PreferencesUtils.instances.delete(name);
  }
}
