import { FolderInfoModel } from '../model/FolderInfoModel';

@Observed
export class FolderItemViewModel {
  @Track folderName: string = '';
  @Track dateAdd: string = '';
  public folderInfo: FolderInfoModel = new FolderInfoModel();

  async updateFolderItem(folderInfo: FolderInfoModel): Promise<void> {
    this.folderInfo = folderInfo;
    let folderPath = folderInfo.path;
    let prevSlashIdx = folderPath.lastIndexOf('/', folderPath.length - 2);
    this.folderName = folderPath.slice(prevSlashIdx + 1, folderPath.length - 1);
    this.dateAdd = new Date(folderInfo.dateAdd).toISOString().slice(0, 10);
  }
}