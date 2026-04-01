@Observed
export class PlayListItemViewModelArray extends Array<PlayListItemViewModel> {
}

@Observed
export class PlayListItemViewModel {
  @Track playListName: string | null = null;
  @Track playListCount: number = 0;
}