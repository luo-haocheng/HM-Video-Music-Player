import { relationalStore } from '@kit.ArkData';
import VideoInfoModel from './VideoInfoModel';

const STORE_NAME = 'VideoStore.db';
const TABLE_NAME = 'VIDEO_IMPORTED';
const SQL_CREATE_TABLE =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT NOT NULL, VIDEO_PATH TEXT NOT NULL, THUMBNAIL_PATH TEXT NOT NULL)`;
const SQL_SELECT_ALL = `SELECT * FROM ${TABLE_NAME}`;

export default class VideoLibraryStore {
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
    try {
      await this.store.executeSql(SQL_CREATE_TABLE);
    } catch (error) {
      console.error(`Failed to execute create table sql ${SQL_CREATE_TABLE}. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
  }

  async insertVideoInfo(name: string, metadata: string, videoPath: string, thumbnailPath: string): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      NAME: name,
      METADATA: metadata,
      VIDEO_PATH: videoPath,
      THUMBNAIL_PATH: thumbnailPath,
      DATE_ADD: new Date().getTime(),
    };
    if (this.store !== undefined) {
      try {
        let result = await this.store.insert(TABLE_NAME, valueBucket);
        return result;
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(valueBucket)}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return -1;
  }

  async selectVideoById(rowId: number): Promise<VideoInfoModel> {
    let videoInfo = new VideoInfoModel();
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(TABLE_NAME);
        predicate.equalTo('ID', rowId);
        let resultSet =
          await this.store.query(predicate, ['ID', 'NAME', 'DATE_ADD', 'METADATA', 'VIDEO_PATH', 'THUMBNAIL_PATH']);
        while (resultSet.goToNextRow()) {
          videoInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          videoInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
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

  async selectAllVideoInfo(): Promise<VideoInfoModel[]> {
    let videoInfoList: VideoInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let resultSet = await this.store.querySql(SQL_SELECT_ALL);
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          const name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          const dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          const metadata = resultSet.getString(resultSet.getColumnIndex('METADATA'));
          const videoPath = resultSet.getString(resultSet.getColumnIndex('VIDEO_PATH'));
          const thumbnailPath = resultSet.getString(resultSet.getColumnIndex('THUMBNAIL_PATH'));
          videoInfoList.push({
            id: id,
            name: name,
            dateAdd: dateAdd,
            metadata: metadata,
            videoPath: videoPath,
            thumbnailPath: thumbnailPath
          });
        }
      } catch (error) {
        console.error(`Failed to execute query sql ${SQL_SELECT_ALL}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return videoInfoList;
  }
};