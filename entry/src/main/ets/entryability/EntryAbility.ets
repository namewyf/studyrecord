import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { StorageService } from '../services/StorageService';
import { MigrationService } from '../services/MigrationService';
import { DefaultData } from '../services/DefaultData';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // Initialize StorageService and perform data migration
    this.initializeApp();
  }

  async initializeApp(): Promise<void> {
    try {
      // 1. 初始化存储服务
      await StorageService.getInstance().init(this.context);
      hilog.info(DOMAIN, 'testTag', 'StorageService initialized successfully');

      // 2. 执行数据迁移
      await MigrationService.checkAndMigrate(this.context);
      hilog.info(DOMAIN, 'testTag', 'Data migration completed');

      // 3. 检查是否是首次安装（没有任何打卡本）
      const notebooks = await StorageService.getInstance().loadNotebooks();
      if (notebooks.length === 0) {
        hilog.info(DOMAIN, 'testTag', 'First time installation, creating default notebooks');
        const defaultNotebooks = DefaultData.createDefaultNotebooks();
        await StorageService.getInstance().saveNotebooks(defaultNotebooks);
        hilog.info(DOMAIN, 'testTag', 'Default notebooks created');
      }

      hilog.info(DOMAIN, 'testTag', 'App initialization completed');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize app: %{public}s',
        error instanceof Error ? error.message : 'Unknown error');
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Get main window and configure it
    windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(err));
        return;
      }

      // Set window to full screen layout (extend to status bar and navigation bar)
      windowClass.setWindowLayoutFullScreen(true, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to set layout full screen. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting layout full screen.');
      });

      // Set window background color to black
      windowClass.setWindowBackgroundColor('#000000');

      // Set status bar content color to light (white icons/text)
      const systemBarProperties: window.SystemBarProperties = {
        statusBarColor: '#000000',
        navigationBarColor: '#000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarContentColor: '#FFFFFF'
      };
      windowClass.setWindowSystemBarProperties(systemBarProperties, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to set system bar properties. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting system bar properties.');
      });
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}