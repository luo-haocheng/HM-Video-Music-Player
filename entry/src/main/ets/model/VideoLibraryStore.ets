import { relationalStore } from '@kit.ArkData';
import { FolderInfoModel } from './FolderInfoModel';
import { VideoInfoModel } from './VideoInfoModel';

const VIDEO_STORE_NAME = 'VideoStore.db';
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
      name: VIDEO_STORE_NAME,
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

  async moveVideo(videoInfo: VideoInfoModel, moveFolder: string): Promise<void> {
    if (this.store !== undefined) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          FOLDER: moveFolder,
        };
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('ID', videoInfo.id);
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to move video id=${videoInfo.id} to ${moveFolder}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
  }

  async moveFolder(updateVideos: VideoInfoModel[], updateFolders: FolderInfoModel[]): Promise<void> {
    // traverse folder
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        // Update sub videos folder
        for (let i = 0; i < updateVideos.length; ++i) {
          const valueBucketFolder: relationalStore.ValuesBucket = {
            FOLDER: updateVideos[i].folder,
          };
          let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
          predicate.equalTo('ID', updateVideos[i].id);
          await transaction.update(valueBucketFolder, predicate);
        }
        // Update sub folders parent
        for (let i = 0; i < updateFolders.length; ++i) {
          const valueBucketParent: relationalStore.ValuesBucket = {
            PARENT: updateFolders[i].parent,
            PATH: updateFolders[i].path,
          };
          let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
          predicate.equalTo('ID', updateFolders[i].id);
          await transaction.update(valueBucketParent, predicate);
        }
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to move folder. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw new Error(error);
      }
    }
  }

  async renameVideo(videoInfo: VideoInfoModel, newName: string): Promise<void> {
    if (this.store !== undefined) {
      try {
        const valueBucket: relationalStore.ValuesBucket = {
          NAME: newName,
        };
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('ID', videoInfo.id);
        await this.store.update(valueBucket, predicate);
      } catch (error) {
        console.error(`Failed to rename video id=${videoInfo.id}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
  }

  async renameFolder(updateVideos: VideoInfoModel[], updateFolders: FolderInfoModel[]): Promise<void> {
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        // Update sub videos folder
        for (let i = 0; i < updateVideos.length; ++i) {
          const valueBucketFolder: relationalStore.ValuesBucket = {
            FOLDER: updateVideos[i].folder,
          };
          let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
          predicate.equalTo('ID', updateVideos[i].id);
          await transaction.update(valueBucketFolder, predicate);
        }
        // Update sub folders parent
        for (let i = 0; i < updateFolders.length; ++i) {
          const valueBucketParent: relationalStore.ValuesBucket = {
            PARENT: updateFolders[i].parent,
            PATH: updateFolders[i].path,
          };
          let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
          predicate.equalTo('ID', updateFolders[i].id);
          await transaction.update(valueBucketParent, predicate);
        }
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to rename folder. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw new Error(error);
      }
    }
  }

  async deleteVideoById(rowId: number): Promise<void> {
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('ID', rowId);
        await this.store.delete(predicate);
      } catch (error) {
        console.error(`Failed to delete video by id=${rowId}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      }
    }
  }

  async deleteFolderAndVideo(subFolders: FolderInfoModel[], subVideos: VideoInfoModel[]): Promise<void> {
    if (this.store !== undefined) {
      let transaction: relationalStore.Transaction | undefined;
      try {
        transaction = await this.store.createTransaction();
        for (let i = 0; i < subFolders.length; ++i) {
          let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
          predicate.equalTo('ID', subFolders[i].id);
          await transaction.delete(predicate);
        }
        for (let i = 0; i < subVideos.length; ++i) {
          let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
          predicate.equalTo('ID', subVideos[i].id);
          await transaction.delete(predicate);
        }
        await transaction.commit();
      } catch (error) {
        console.error(`Failed to delete ${JSON.stringify(subFolders)} and ${JSON.stringify(subVideos)}. Cause: ${JSON.stringify(error)}`);
        await transaction?.rollback();
        throw new Error(error);
      }
    }
  }

  async selectVideoById(rowId: number): Promise<VideoInfoModel> {
    let videoInfo = new VideoInfoModel();
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('ID', rowId);
        resultSet = await this.store.query(predicate);
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
      } finally {
        resultSet?.close();
      }
    }
    return videoInfo;
  }

  async selectFolderById(rowId: number): Promise<FolderInfoModel> {
    let folderInfo = new FolderInfoModel();
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
        predicate.equalTo('ID', rowId);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          folderInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          folderInfo.path = resultSet.getString(resultSet.getColumnIndex('PATH'));
          folderInfo.parent = resultSet.getString(resultSet.getColumnIndex('PARENT'));
          folderInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
        }
      } catch (error) {
        console.error(`Failed to query folder by id=${rowId}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return folderInfo;
  }

  async selectVideoByFolder(folder: string): Promise<VideoInfoModel[]> {
    let videoInfoList: VideoInfoModel[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(VIDEO_TABLE_NAME);
        predicate.equalTo('FOLDER', folder);
        resultSet = await this.store.query(predicate);
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
      } finally {
        resultSet?.close();
      }
    }
    return videoInfoList;
  }

  async selectFolderByFolder(folder: string): Promise<FolderInfoModel[]> {
    let folderInfoList: FolderInfoModel[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    if (this.store !== undefined) {
      try {
        let predicate = new relationalStore.RdbPredicates(FOLDER_TABLE_NAME);
        predicate.equalTo('PARENT', folder);
        resultSet = await this.store.query(predicate);
        while (resultSet.goToNextRow()) {
          let folderInfo = new FolderInfoModel();
          folderInfo.id = resultSet.getLong(resultSet.getColumnIndex('ID'));
          folderInfo.path = resultSet.getString(resultSet.getColumnIndex('PATH'));
          folderInfo.parent = resultSet.getString(resultSet.getColumnIndex('PARENT'));
          folderInfo.dateAdd = resultSet.getLong(resultSet.getColumnIndex('DATE_ADD'));
          folderInfoList.push(folderInfo);
        }
      } catch (error) {
        console.error(`Failed to execute query folder by folder=${folder}. Cause: ${JSON.stringify(error)}`);
        throw new Error(error);
      } finally {
        resultSet?.close();
      }
    }
    return folderInfoList;
  }
}