import { relationalStore } from '@kit.ArkData';
import { AudioInfoModel } from './AudioInfoModel';
import { PlayListInfoModel } from './PlayListInfoModel';

const AUDIO_STORE_NAME = 'AudioStore.db';
const AUDIO_TABLE_NAME = 'VIDEO_IMPORTED';
const PLAYLIST_TABLE_NAME = 'PLAYLIST_CREATED';
const PLAYLIST_AUDIO_TABLE_NAME = 'PLAYLIST_AUDIO';
const SQL_CREATE_AUDIO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${AUDIO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT, ALBUM TEXT, ARTIST TEXT, AUDIO_PATH TEXT NOT NULL, COVER_PATH TEXT)`;
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
    } catch (error) {
      console.error(`Failed to execute create table sql. Cause: ${JSON.stringify(error)}`);
      await transaction?.rollback();
      throw new Error(error);
    }
  }

  async deleteAudio(audioInfo: AudioInfoModel): Promise<void> {
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        // Delete audio info in audio_table
        let predicateAudio = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicateAudio.equalTo('ID', audioInfo.id);
        await transaction.delete(predicateAudio);
        // Delete audio info in playlist_audio_table
        let predicatePlaylistAudio = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicatePlaylistAudio.equalTo('AUDIO_ID', audioInfo.id);
        await transaction.delete(predicatePlaylistAudio);
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to delete audio ${JSON.stringify(audioInfo)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
      }
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
          ALBUM: audioInfo.album,
          ARTIST: audioInfo.artist,
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
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(audioInfo)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw new Error(error);
      }
    }
    return rowId;
  }

  async insertPlaylistInfo(playlistInfo: PlayListInfoModel): Promise<number> {
    let rowId = -1;
    if (this.store !== undefined) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          NAME: playlistInfo.name,
          DATE_ADD: new Date().getTime(),
        };
        rowId = await this.store.insert(PLAYLIST_TABLE_NAME, valueBucket);
        console.info(`Create Playlist Success`);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(playlistInfo)}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
    return rowId;
  }

  async selectAllPlaylist(): Promise<PlayListInfoModel[]> {
    let resultSet: relationalStore.ResultSet | undefined;
    let playlistInfoList: PlayListInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_TABLE_NAME);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          const playlistInfo = new PlayListInfoModel();
          playlistInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          playlistInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          playlistInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          playlistInfoList.push(playlistInfo);
        }
      } catch (error) {
        console.error(`Failed to select all playlist. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return playlistInfoList;
  }

  async selectAllAudio(): Promise<AudioInfoModel[]> {
    let resultSet: relationalStore.ResultSet | undefined;
    let audioInfoList: AudioInfoModel[] = [];
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let audioInfo = new AudioInfoModel();
          audioInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          audioInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          audioInfo.audioPath = resultSet.getString(resultSet.getColumnIndex('AUDIO_PATH'));
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ALBUM'))) {
            audioInfo.album = null;
          } else {
            audioInfo.album = resultSet.getString(resultSet.getColumnIndex('ALBUM'));
          }
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ARTIST'))) {
            audioInfo.artist = null;
          } else {
            audioInfo.artist = resultSet.getString(resultSet.getColumnIndex('ARTIST'));
          }
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
      } finally {
        resultSet?.close();
      }
    }
    return audioInfoList;
  }

  async selectAudioByPlayList(playlistName: string | null): Promise<AudioInfoModel[]> {
    let audioIdList: number[] = [];
    let audioInfoList: AudioInfoModel[] = [];
    let resultSetID: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicate.equalTo('PLAYLIST_NAME', playlistName);
        resultSetID = await this.store.query(predicate);
        while (resultSetID.goToNextRow()) {
          let audioId = resultSetID.getLong(resultSetID.getColumnIndex('AUDIO_ID'));
          audioIdList.push(audioId);
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSetID?.close();
      }

      let resultSetAudio: relationalStore.ResultSet | undefined;
      try {
        for (let i = 0; i < audioIdList.length; ++i) {
          let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
          predicate.equalTo('ID', audioIdList[i]);
          resultSetAudio = await this.store.query(predicate);
          while (resultSetAudio.goToNextRow()) {
            let audioInfo = new AudioInfoModel();
            audioInfo.id = resultSetAudio.getLong(resultSetAudio.getColumnIndex('ID'));
            audioInfo.name = resultSetAudio.getString(resultSetAudio.getColumnIndex('NAME'));
            audioInfo.audioPath = resultSetAudio.getString(resultSetAudio.getColumnIndex('AUDIO_PATH'));
            if (resultSetAudio.isColumnNull(resultSetAudio.getColumnIndex('ALBUM'))) {
              audioInfo.album = null;
            } else {
              audioInfo.album = resultSetAudio.getString(resultSetAudio.getColumnIndex('ALBUM'));
            }
            if (resultSetAudio.isColumnNull(resultSetAudio.getColumnIndex('ARTIST'))) {
              audioInfo.artist = null;
            } else {
              audioInfo.artist = resultSetAudio.getString(resultSetAudio.getColumnIndex('ARTIST'));
            }
            if (resultSetAudio.isColumnNull(resultSetAudio.getColumnIndex('METADATA'))) {
              audioInfo.metadata = null;
            } else {
              audioInfo.metadata = resultSetAudio.getString(resultSetAudio.getColumnIndex('METADATA'));
            }
            if (resultSetAudio.isColumnNull(resultSetAudio.getColumnIndex('COVER_PATH'))) {
              audioInfo.coverPath = null;
            } else {
              audioInfo.coverPath = resultSetAudio.getString(resultSetAudio.getColumnIndex('COVER_PATH'));
            }
            audioInfoList.push(audioInfo);
          }
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSetAudio?.close();
      }
    }
    return audioInfoList;
  }

  async selectAudioByAlbum(album: string | null): Promise<AudioInfoModel[]> {
    let audioInfoList: AudioInfoModel[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        album ? predicate.equalTo('ALBUM', album) : predicate.isNull('ALBUM');
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let audioInfo = new AudioInfoModel();
          audioInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          audioInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          audioInfo.audioPath = resultSet.getString(resultSet.getColumnIndex('AUDIO_PATH'));
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ALBUM'))) {
            audioInfo.album = null;
          } else {
            audioInfo.album = resultSet.getString(resultSet.getColumnIndex('ALBUM'));
          }
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ARTIST'))) {
            audioInfo.artist = null;
          } else {
            audioInfo.artist = resultSet.getString(resultSet.getColumnIndex('ARTIST'));
          }
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
        console.error(`Failed to execute query audio of album: ${album} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return audioInfoList;
  }

  async selectAudioByArtist(artist: string | null): Promise<AudioInfoModel[]> {
    let audioInfoList: AudioInfoModel[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        artist ? predicate.equalTo('ARTIST', artist) : predicate.isNull('ARTIST');
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let audioInfo = new AudioInfoModel();
          audioInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          audioInfo.name = resultSet.getString(resultSet.getColumnIndex('NAME'));
          audioInfo.audioPath = resultSet.getString(resultSet.getColumnIndex('AUDIO_PATH'));
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ALBUM'))) {
            audioInfo.album = null;
          } else {
            audioInfo.album = resultSet.getString(resultSet.getColumnIndex('ALBUM'));
          }
          if (resultSet.isColumnNull(resultSet.getColumnIndex('ARTIST'))) {
            audioInfo.artist = null;
          } else {
            audioInfo.artist = resultSet.getString(resultSet.getColumnIndex('ARTIST'));
          }
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
        console.error(`Failed to execute query audio of artist: ${artist} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return audioInfoList;
  }

  async playlistAudioCount(playlistName: string | null): Promise<number> {
    let count: number = 0;
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicate.equalTo('PLAYLIST_NAME', playlistName);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          count++;
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return count;
  }
}