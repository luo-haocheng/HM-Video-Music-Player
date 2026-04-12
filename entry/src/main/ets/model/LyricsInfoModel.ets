export class LyricsInfo {
  startMs: number = 0;
  text: string = '';

  updateLyrics(info: string): boolean {
    try {
      const timeFlag = info.match(/\[\d\d:\d\d\.\d\d\]/);
      if (timeFlag === null || timeFlag.length <= 0) {
        return false;
      }
      this.startMs = this.updateStartMs(timeFlag[0]);
      this.text = this.updateText(info);
      return true;
    } catch (error) {
      console.error(`Invalid lyrics: ${info}`);
      return false;
    }
  }

  private updateStartMs(timeFlag: string): number {
    const timeStr = timeFlag.slice(1, timeFlag.length - 1);
    const colonIdx = timeStr.indexOf(':');
    const dotIdx = timeStr.indexOf('.');
    if (colonIdx === -1 || dotIdx === -1) {
      throw Error(`Invalid time flag: ${timeFlag}`);
    }
    const minutes = parseInt(timeStr.slice(0, colonIdx));
    const seconds = parseInt(timeStr.slice(colonIdx + 1, dotIdx));
    const milliseconds = parseInt(timeStr.slice(dotIdx + 1));
    return milliseconds + seconds * 1000 + minutes * 60 * 1000;
  }

  private updateText(info: string): string {
    const text = info.replace(/\[\d\d:\d\d\.\d\d\]/, '');
    return text;
  }
}