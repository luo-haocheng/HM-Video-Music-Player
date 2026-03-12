import { relationalStore } from '@kit.ArkData';
import { FolderInfoModel } from './FolderInfoModel';
import { VideoInfoModel } from './VideoInfoModel';

const STORE_NAME = 'VideoStore.db';
const VIDEO_TABLE_NAME = 'VIDEO_IMPORTED';
const FOLDER_TABLE_NAME = 'FOLDER_CREATED';
const SQL_CREATE_VIDEO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${VIDEO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT NOT NULL, VIDEO_PATH TEXT NOT NULL, THUMBNAIL_PATH TEXT NOT NULL, FOLDER TEXT NOT NULL)`;
const SQL_CREATE_FOLDER_TABLE =
  `CREATE TABLE IF NOT EXISTS ${FOLDER_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, PATH TEXT NOT NULL UNIQUE, PARENT TEXT NOT NULL, DATE_ADD INTEGER NOT NULL)`;

export class VideoLibraryStore {
  private store?: relationalStore.RdbStore;

  async initStore(context: Context): Promise<void> {
    const storeConfig: relationalStore.StoreConfig = {
      name: STORE_NAME,
      securityLevel: relationalStore.SecurityLevel.S3,
    };
    try {
      this.store = await relationalStore.getRdbStore(context, storeConfig);
    } catch (error) {
      console.error(`Failed to get RdbStore. Casuse: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    let transaction: relationalStore.Transaction | undefined;
    try {
      transaction = await this.store.createTransaction();
      await transaction.execute(SQL_CREATE_FOLDER_TABLE);
      await transaction.execute(SQL_CREATE_VIDEO_TABLE);
      await transaction.commit();
    } catch (error) {
      console.error(`Failed to execute create table sql. Cause: ${JSON.stringify(error)}`);
      await transaction?.rollback();
      throw new Error(error);
    }
  }

  async insertVideoInfo(videoInfo: VideoInfoModel): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      NAME: videoInfo.name,
      FOLDER: videoInfo.folder,
      METADATA: videoInfo.metadata,
      VIDEO_PATH: videoInfo.videoPath,
      THUMBNAIL_PATH: videoInfo.thumbnailPath,
      DATE_ADD: new Date().getTime(),
    };
    let rowId = -1;
    if (this.store !== undefined) {
      try {
        rowId = await this.store.insert(VIDEO_TABLE_NAME, valueBucket);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(valueBucket)}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return rowId;
  }

  async insertFolderInfo(folderInfo: FolderInfoModel): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      PATH: folderInfo.path,
      PARENT: folderInfo.parent,
      DATE_ADD: new Date().getTime(),
    };
    let rowId = -1;
    if (this.store !== undefined) {
      try {
        rowId = await this.store.insert(FOLDER_TABLE_NAME, valueBucket);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(valueBucket)}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return rowId;
  }

  async selectVideoById(rowId: number): Promise<VideoInfoModel> {
    let videoInfo = new VideoInfoModel();
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('ID', rowId);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          videoInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          videoInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          videoInfo.folder = resultSet.getString(resultSet.getColumnIndex('FOLDER'));
          videoInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          videoInfo.metadata = resultSet.getString(resultSet.getColumnIndex('METADATA'));
          videoInfo.videoPath = resultSet.getString(resultSet.getColumnIndex('VIDEO_PATH'));
          videoInfo.thumbnailPath = resultSet.getString(resultSet.getColumnIndex('THUMBNAIL_PATH'));
        }
      } catch (error) {
        console.error(`Failed to query video by id=${rowId}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return videoInfo;
  }

  async selectFolderById(rowId: number): Promise<FolderInfoModel> {
    let folderInfo = new FolderInfoModel();
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
        predicate.equalTo('ID', rowId);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          folderInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          folderInfo.path = resultSet.getString(resultSet.getColumnIndex('PATH'));
          folderInfo.parent = resultSet.getString(resultSet.getColumnIndex('PARENT'));
          folderInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
        }
      } catch (error) {
        console.error(`Failed to query folder by id=${rowId}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return folderInfo;
  }

  async selectVideoByFolder(folder: string): Promise<VideoInfoModel[]> {
    let videoInfoList: VideoInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('FOLDER', folder);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let videoInfo = new VideoInfoModel();
          videoInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          videoInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          videoInfo.folder = resultSet.getString(resultSet.getColumnIndex('FOLDER'));
          videoInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          videoInfo.metadata = resultSet.getString(resultSet.getColumnIndex('METADATA'));
          videoInfo.videoPath = resultSet.getString(resultSet.getColumnIndex('VIDEO_PATH'));
          videoInfo.thumbnailPath = resultSet.getString(resultSet.getColumnIndex('THUMBNAIL_PATH'));
          videoInfoList.push(videoInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query video by folder=${folder}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return videoInfoList;
  }

  async selectFolderByFolder(folder: string): Promise<FolderInfoModel[]> {
    let folderInfoList: FolderInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
        predicate.equalTo('PARENT', folder);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let videoInfo = new FolderInfoModel();
          videoInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          videoInfo.path = resultSet.getString(resultSet.getColumnIndex('PATH'));
          videoInfo.parent = resultSet.getString(resultSet.getColumnIndex('PARENT'));
          videoInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          folderInfoList.push(videoInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query folder by folder=${folder}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return folderInfoList;
  }
}
;