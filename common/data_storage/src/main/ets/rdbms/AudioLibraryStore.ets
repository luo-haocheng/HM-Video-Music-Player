import { relationalStore } from '@kit.ArkData';
import { AudioInfoModel } from './AudioInfoModel';
import { PlayListInfoModel } from './PlayListInfoModel';

const AUDIO_STORE_NAME = 'AudioStore.db';
const AUDIO_TABLE_NAME = 'VIDEO_IMPORTED';
const PLAYLIST_TABLE_NAME = 'PLAYLIST_CREATED';
const PLAYLIST_AUDIO_TABLE_NAME = 'PLAYLIST_AUDIO';
const SQL_CREATE_AUDIO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${AUDIO_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, TITLE TEXT NOT NULL, DATE_ADD INTEGER NOT NULL, METADATA TEXT, ALBUM TEXT, ARTIST TEXT, AUDIO_PATH TEXT NOT NULL UNIQUE, COVER_PATH TEXT, LYRICS_PATH TEXT, FAVORITE INTEGER NOT NULL)`;
const SQL_CREATE_PLAYLIST_TABLE =
  `CREATE TABLE IF NOT EXISTS ${PLAYLIST_TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT NOT NULL UNIQUE, DATE_ADD INTEGER NOT NULL)`;
const SQL_CREATE_PLAYLIST_AUDIO_TABLE =
  `CREATE TABLE IF NOT EXISTS ${PLAYLIST_AUDIO_TABLE_NAME} (PLAYLIST_NAME TEXT NOT NULL, AUDIO_ID INTEGER NOT NULL, PRIMARY KEY(PLAYLIST_NAME, AUDIO_ID))`;

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
      throw Error(error);
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
      throw Error(error);
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
        // Transaction commit
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to delete audio ${JSON.stringify(audioInfo)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw Error(error);
      }
    }
  }

  async deletePlaylist(playlistInfo: PlayListInfoModel): Promise<void> {
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        // Delete playlist in playlist_table
        let predicatePlaylist = new relationalStore.RdbPredicates(PLAYLIST_TABLE_NAME);
        predicatePlaylist.equalTo('NAME', playlistInfo.name);
        await transaction.delete(predicatePlaylist);
        // Delete playlist in playlist_audio_table
        let predicatePlaylistAudio = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicatePlaylistAudio.equalTo('PLAYLIST_NAME', playlistInfo.name);
        await transaction.delete(predicatePlaylistAudio);
        // Transaction commit
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to delete playlist ${JSON.stringify(playlistInfo)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw Error(error);
      }
    }
  }

  async deleteAudioFromPlaylist(audioInfo: AudioInfoModel, playlistName: string | null): Promise<number> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicate
          .equalTo('AUDIO_ID', audioInfo.id)
          .and()
          .equalTo('PLAYLIST_NAME', playlistName);
        const delNum = await this.store.delete(predicate);
        return delNum;
      } catch (error) {
        console.error(`Failed to delete ${audioInfo.id}, ${playlistName}. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
    return 0;
  }

  async updateAudioFavorite(audioInfo: AudioInfoModel, isFavorite: boolean): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          FAVORITE: isFavorite ? 1 : 0,
        };
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} favorite. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async updateAudioTitle(audioInfo: AudioInfoModel, title: string): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          TITLE: title,
        };
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} title. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async updateAudioAlbum(audioInfo: AudioInfoModel, album: string | null): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          ALBUM: album,
        };
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} album. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async updateAudioArtist(audioInfo: AudioInfoModel, artist: string | null): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          ARTIST: artist,
        };
        await this.store.update(valueBucket, predicate);
        console.info(`Update Artist to artist Success.`);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} artist . Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async updateAudioAlbumCover(audioInfo: AudioInfoModel, coverPath: string | null): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          COVER_PATH: coverPath,
        };
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} favorite. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async updateAudioLyrics(audioInfo: AudioInfoModel, lyricsPath: string): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('ID', audioInfo.id);
        const valueBucket: relationalStore.ValuesBucket = {
          LYRICS_PATH: lyricsPath,
        };
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to update ${JSON.stringify(audioInfo)} favorite. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
  }

  async insertAudioInfo(audioInfo: AudioInfoModel): Promise<number> {
    let rowId = -1;
    if (this.store !== undefined) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          TITLE: audioInfo.title,
          ALBUM: audioInfo.album,
          ARTIST: audioInfo.artist,
          DATE_ADD: audioInfo.dateAdd,
          METADATA: audioInfo.metadata,
          FAVORITE: audioInfo.favorite,
          AUDIO_PATH: audioInfo.audioPath,
          COVER_PATH: audioInfo.coverPath,
          LYRICS_PATH: audioInfo.lyricsPath,
        };
        rowId = await this.store.insert(AUDIO_TABLE_NAME, valueBucket);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(audioInfo)}. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
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
          DATE_ADD: playlistInfo.dateAdd,
        };
        rowId = await this.store.insert(PLAYLIST_TABLE_NAME, valueBucket);
      } catch (error) {
        console.error(`Failed to insert ${JSON.stringify(playlistInfo)}. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      }
    }
    return rowId;
  }

  async insertAudio2Playlist(audioInfo: AudioInfoModel, playlistInfo: PlayListInfoModel): Promise<boolean> {
    if (this.store !== undefined) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          PLAYLIST_NAME: playlistInfo.name,
          AUDIO_ID: audioInfo.id,
        };
        await this.store.insert(PLAYLIST_AUDIO_TABLE_NAME, valueBucket);
        return true;
      } catch (error) {
        console.error(`Failed to insert ${audioInfo.id} to ${playlistInfo.name}. Cause: ${JSON.stringify(error)}`);
        return false;
      }
    }
    return false;
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
        throw Error(error);
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
          const audioInfo = this.fetchAudioInfoFromResult(resultSet);
          audioInfoList.push(audioInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query all audio. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return audioInfoList;
  }

  async selectFavoriteAudio(): Promise<AudioInfoModel[]> {
    let audioInfoList: AudioInfoModel[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(AUDIO_TABLE_NAME);
        predicate.equalTo('FAVORITE', 1);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          const audioInfo = this.fetchAudioInfoFromResult(resultSet);
          audioInfoList.push(audioInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query favorite audio. Cause: ${JSON.stringify(error)}`);
        throw Error(error);
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
        throw Error(error);
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
            const audioInfo = this.fetchAudioInfoFromResult(resultSetAudio);
            audioInfoList.push(audioInfo);
          }
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw Error(error);
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
          const audioInfo = this.fetchAudioInfoFromResult(resultSet);
          audioInfoList.push(audioInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query audio of album: ${album} . Cause: ${JSON.stringify(error)}`);
        throw Error(error);
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
          const audioInfo = this.fetchAudioInfoFromResult(resultSet);
          audioInfoList.push(audioInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query audio of artist: ${artist} . Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return audioInfoList;
  }

  async selectPlaylistAudioList(playlistName: string | null): Promise<number[]> {
    const audioIDList: number[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(PLAYLIST_AUDIO_TABLE_NAME);
        predicate.equalTo('PLAYLIST_NAME', playlistName);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          const audioID = resultSet.getLong(resultSet.getColumnIndex('AUDIO_ID'));
          audioIDList.push(audioID);
        }
      } catch (error) {
        console.error(`Failed to execute query audio id of playlist: ${playlistName} . Cause: ${JSON.stringify(error)}`);
        throw Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return audioIDList;
  }

  private fetchAudioInfoFromResult(resultSet: relationalStore.ResultSet): AudioInfoModel {
    const audioInfo = new AudioInfoModel();
    try {
      audioInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
      audioInfo.title = resultSet.getString(resultSet.getColumnIndex('TITLE'));
      audioInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
      audioInfo.favorite = resultSet.getLong(resultSet.getColumnIndex('FAVORITE'));
      audioInfo.audioPath = resultSet.getString(resultSet.getColumnIndex('AUDIO_PATH'));
      if (!resultSet.isColumnNull(resultSet.getColumnIndex('ALBUM'))) {
        audioInfo.album = resultSet.getString(resultSet.getColumnIndex('ALBUM'));
      }
      if (!resultSet.isColumnNull(resultSet.getColumnIndex('ARTIST'))) {
        audioInfo.artist = resultSet.getString(resultSet.getColumnIndex('ARTIST'));
      }
      if (!resultSet.isColumnNull(resultSet.getColumnIndex('METADATA'))) {
        audioInfo.metadata = resultSet.getString(resultSet.getColumnIndex('METADATA'));
      }
      if (!resultSet.isColumnNull(resultSet.getColumnIndex('COVER_PATH'))) {
        audioInfo.coverPath = resultSet.getString(resultSet.getColumnIndex('COVER_PATH'));
      }
      if (!resultSet.isColumnNull(resultSet.getColumnIndex('LYRICS_PATH'))) {
        audioInfo.lyricsPath = resultSet.getString(resultSet.getColumnIndex('LYRICS_PATH'));
      }
    } catch (error) {
      console.error(`Failed to fetch audio info from resultSet`);
      throw Error(error);
    }
    return audioInfo;
  }
}