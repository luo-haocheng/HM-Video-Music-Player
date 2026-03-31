import { relationalStore } from '@kit.ArkData';
import { AudioInfoModel } from './AudioInfoModel';

const AUDIO_STORE_NAME = 'AudioStore.db';
const AUDIO_TABLE_NAME = 'VIDEO_IMPORTED';
const PLAYLIST_TABLE_NAME = 'PLAYLIST_CREATED';
const PLAYLIST_AUDIO_TABLE_NAME = 'PLAYLIST_AUDIO';
const SQL_CREATE_AUDIO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${AUDIO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT, AUDIO_PATH TEXT NOT NULL, COVER_PATH TEXT)`;
const SQL_CREATE_PLAYLIST_TABLE =
  `CREATE TABLE IF NOT EXISTS ${PLAYLIST_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL UNIQUE, DATE_ADD INTEGER NOT NULL)`;
const SQL_CREATE_PLAYLIST_AUDIO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${PLAYLIST_AUDIO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, PLAYLIST_NAME TEXT NOT NULL, AUDIO_ID INTEGER)`;

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
      await transaction.execute(SQL_CREATE_AUDIO_TABLE);
      await transaction.execute(SQL_CREATE_PLAYLIST_TABLE);
      await transaction.execute(SQL_CREATE_PLAYLIST_AUDIO_TABLE);
      await transaction.commit();
      console.info(`Create audio table succeed.`);
    } catch (error) {
      console.error(`Failed to execute create table sql. Cause: ${JSON.stringify(error)}`);
      await transaction?.rollback();
      throw new Error(error);
    }
  }

  async insertAudioInfo(audioInfo: AudioInfoModel): Promise<number> {
    let rowId = -1;
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        const valueBucket1: relationalStore.ValuesBucket = {
          NAME: audioInfo.name,
          METADATA: audioInfo.metadata,
          AUDIO_PATH: audioInfo.audioPath,
          COVER_PATH: audioInfo.coverPath,
          DATE_ADD: new Date().getTime(),
        };
        rowId = await transaction.insert(AUDIO_TABLE_NAME, valueBucket1);
        const valueBucket2: relationalStore.ValuesBucket = {
          PLAYLIST_NAME: '*',
          AUDIO_ID: rowId,
        };
        await transaction.insert(PLAYLIST_AUDIO_TABLE_NAME, valueBucket2);
        await transaction.commit();
        console.info(`Insert ${audioInfo.name} to DB successfully`);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(audioInfo)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
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

  async selectAudioByPlayList(playlistName: string): Promise<AudioInfoModel[]> {
    let audioIdList: number[] = [];
    let audioInfoList: AudioInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicate.equalTo('PLAYLIST_NAME', playlistName);
        let resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let audioId = resultSet.getLong(resultSet.getColumnIndex('AUDIO_ID'));
          audioIdList.push(audioId);
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }

      try {
        for (let i = 0; i < audioIdList.length; ++i) {
          let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
          predicate.equalTo('ID', audioIdList[i]);
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
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return audioInfoList;
  }
}