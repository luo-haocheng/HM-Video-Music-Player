import { bundleManager, Context, WantAgent, wantAgent } from '@kit.AbilityKit';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';

export class ContinuousTaskManager {
  static async startContinuousTask(context: Context): Promise<void> {
    const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags);
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: bundleInfo.name,
          abilityName: 'EntryAbility'
        }
      ],
      requestCode: 0,
      actionType: wantAgent.OperationType.START_ABILITY,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    let wantAgentObj: WantAgent | undefined;
    try {
      wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      console.error(`Failed to invoke wantAgent.getWantAgent. Cause: ${JSON.stringify(error)}`);
      return;
    }
    try {
      let list: Array<string> = ['audioPlayback'];
      await backgroundTaskManager.startBackgroundRunning(context, list, wantAgentObj);
      console.info(`Start continuous task successfully`);
    } catch (error) {
      console.error(`Failed to invoke startBackgroundRunning. Cuase: ${JSON.stringify(error)}`);
      return;
    }
  }

  static async stopContinuousTask(context: Context): Promise<void> {
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
      console.info(`Stop continuous task successfully`);
    } catch (error) {
      console.error(`Failed to invoke stopBackgroundRunning. Cuase: ${JSON.stringify(error)}`);
    }
  }

  static async hasContinuousTasks(context: Context): Promise<boolean> {
    try {
      const result = await backgroundTaskManager.getAllContinuousTasks(context);
      return result.length > 0;
    } catch (error) {
      console.error(`Failed to invoke getAllContinuousTask. Cause: ${JSON.stringify(error)}`);
    }
    return false;
  }
}