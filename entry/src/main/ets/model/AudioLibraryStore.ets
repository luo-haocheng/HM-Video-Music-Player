import { relationalStore } from '@kit.ArkData';
import { AudioInfoModel } from './AudioInfoModel';

const AUDIO_STORE_NAME = 'AudioStore.db';
const AUDIO_TABLE_NAME = 'VIDEO_IMPORTED';
const SQL_CREATE_Audio_TABLE =
  `CREATE TABLE IF NOT EXISTS ${AUDIO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT, AUDIO_PATH TEXT NOT NULL, COVER_PATH TEXT)`;

export class AudioLibraryStore {
  private store?: relationalStore.RdbStore;

  async initStore(context: Context): Promise<void> {
    const storeConfig: relationalStore.StoreConfig = {
      name: AUDIO_STORE_NAME,
      securityLevel: relationalStore.SecurityLevel.S3,
    };
    try {
      this.store = await relationalStore.getRdbStore(context, storeConfig);
    } catch (error) {
      console.error(`Failed to get RdbStore. Cause: ${JSON.stringify(error)}`);
      throw new Error(error);
    }
    let transaction: relationalStore.Transaction | undefined;
    try {
      transaction = await this.store.createTransaction();
      await transaction.execute(SQL_CREATE_Audio_TABLE);
      await transaction.commit();
      console.info(`Create audio table succeed.`);
    } catch (error) {
      console.error(`Failed to execute create table sql. Cause: ${JSON.stringify(error)}`);
      await transaction?.rollback();
      throw new Error(error);
    }
  }

  async insertAudioInfo(audioInfo: AudioInfoModel): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      NAME: audioInfo.name,
      METADATA: audioInfo.metadata,
      AUDIO_PATH: audioInfo.audioPath,
      COVER_PATH: audioInfo.coverPath,
      DATE_ADD: new Date().getTime(),
    };
    let rowId = -1;
    if (this.store !== undefined) {
      try {
        rowId = await this.store.insert(AUDIO_TABLE_NAME, valueBucket);
        console.info(`Insert ${audioInfo.name} to DB successfully`);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(valueBucket)}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return rowId;
  }

  async selectAllAudio(): Promise<AudioInfoModel[]> {
    let audioInfoList: AudioInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let audioInfo = new AudioInfoModel();
          audioInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          audioInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          audioInfo.audioPath = resultSet.getString(resultSet.getColumnIndex('AUDIO_PATH'));
          if (resultSet.isColumnNull(resultSet.getColumnIndex('METADATA'))) {
            audioInfo.metadata = null;
          } else {
            audioInfo.metadata = resultSet.getString(resultSet.getColumnIndex('METADATA'));
          }
          if (resultSet.isColumnNull(resultSet.getColumnIndex('COVER_PATH'))) {
            audioInfo.coverPath = null;
          } else {
            audioInfo.coverPath = resultSet.getString(resultSet.getColumnIndex('COVER_PATH'));
          }
          audioInfoList.push(audioInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query all audio. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return audioInfoList;
  }
}