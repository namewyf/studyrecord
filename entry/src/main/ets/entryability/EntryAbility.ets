import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { StorageService } from '../services/StorageService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // Initialize StorageService
    StorageService.getInstance().init(this.context).then(() => {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'StorageService initialized successfully');
    }).catch((error: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize StorageService: %{public}s', error.message);
    });
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