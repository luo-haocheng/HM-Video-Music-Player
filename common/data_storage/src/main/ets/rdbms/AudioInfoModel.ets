export class AudioInfoModel {
  public id: number = 0;
  public title: string = '';
  public dateAdd: number = 0;
  public favorite: number = 0;
  public audioPath: string = '';
  public album: string | null = null;
  public artist: string | null = null;
  public metadata: string | null = null;
  public coverPath: string | null = null;
  public lyricsPath: string | null = null;
}