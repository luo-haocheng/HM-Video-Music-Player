import { preferences } from '@kit.ArkData';

export enum SettingKey {
  SORT_MODE = 'SortMode',
  SORT_RULE = 'SortRule',
  VIEW_OPTION = 'ViewOption'
}

export enum SortModeValue {
  DATE_ADD = 'DateAdd',
  FILE_NAME = 'FileName',
  FILE_SIZE = 'FileSize',
}

export enum SortRuleValue {
  ASCENDING = 'Ascending',
  DESCENDING = 'Descending',
}

export enum ViewOptionValue {
  LIST_VIEW = 'ListView',
  GRID_VIEW = 'GridView',
}

export const DEFAULT_SETTING = new Map<SettingKey, preferences.ValueType>([
  [SettingKey.SORT_MODE, SortModeValue.DATE_ADD],
  [SettingKey.SORT_RULE, SortRuleValue.ASCENDING],
  [SettingKey.VIEW_OPTION, ViewOptionValue.LIST_VIEW],
]);