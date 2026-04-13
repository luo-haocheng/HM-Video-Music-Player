import { preferences } from '@kit.ArkData';

export enum SettingKey {
  AUDIO_SORT_MODE = 'AudioSortMode',
  AUDIO_SORT_RULE = 'AudioSortRule',
  VIDEO_SORT_MODE = 'VideoSortMode',
  VIDEO_SORT_RULE = 'VideoSortRule',
  PLAYLIST_SORT_MODE = 'PlaylistSortMode',
  PLAYLIST_SORT_RULE = 'PlaylistSortRule',
  VIDEO_VIEW_OPTION = 'VideoViewOption',
  AUDIO_VIEW_OPTION = 'AudioViewOption',
  AUDIO_REPEAT_MODE = 'AudioRepeatMode',
}

export enum SortModeValue {
  DATE_ADD = 'DateAdd',
  FILE_NAME = 'FileName',
  FILE_SIZE = 'FileSize',
  AUDIO_TITLE = 'AudioTitle',
  PLAYLIST_NAME = 'PlaylistName',
}

export enum SortRuleValue {
  ASCENDING = 'Ascending',
  DESCENDING = 'Descending',
}

export enum ViewOptionValue {
  LIST_VIEW = 'ListView',
  GRID_VIEW = 'GridView',
}

export enum AudioRepeatMode {
  SINGLE_REPEAT = 'SingleRepeat',
  LIST_REPEAT = 'ListRepeat',
  SHUFFLE = 'Shuffle',
}

export const DEFAULT_SETTING = new Map<SettingKey, preferences.ValueType>([
  [SettingKey.VIDEO_SORT_MODE, SortModeValue.DATE_ADD],
  [SettingKey.VIDEO_SORT_RULE, SortRuleValue.ASCENDING],
  [SettingKey.AUDIO_SORT_MODE, SortModeValue.DATE_ADD],
  [SettingKey.AUDIO_SORT_RULE, SortRuleValue.ASCENDING],
  [SettingKey.PLAYLIST_SORT_MODE, SortModeValue.DATE_ADD],
  [SettingKey.PLAYLIST_SORT_RULE, SortRuleValue.ASCENDING],
  [SettingKey.VIDEO_VIEW_OPTION, ViewOptionValue.LIST_VIEW],
  [SettingKey.AUDIO_VIEW_OPTION, ViewOptionValue.LIST_VIEW],
  [SettingKey.AUDIO_REPEAT_MODE, AudioRepeatMode.SINGLE_REPEAT],
]);