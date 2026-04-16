import { FolderInfoModel } from 'data_storage/src/main/ets/rdbms/FolderInfoModel';

@Observed
export class FolderItemViewModel {
  @Track isChoice: boolean = false;
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