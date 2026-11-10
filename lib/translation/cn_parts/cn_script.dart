// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_script = {
  I18n.device: '模拟器设置',
  I18n.error: '出错设置',
  I18n.optimization: '优化设置',
  I18n.serial: '模拟器 Serial',
  I18n.serialHelp: '''常见的模拟器 Serial 可以查询下方列表
填 "auto" 自动检测模拟器，多个模拟器正在运行或使用不支持自动检测的模拟器时无法使用 "auto"，必须手动填写

模拟器默认 Serial:
[MuMu模拟器12]: 127.0.0.1:16384 
[MuMu模拟器]: 127.0.0.1:7555 
[雷电模拟器](全系列通用): emulator-5554 或 127.0.0.1:5555

如果没有提及的那可能是还没有测试或者不推荐使用，可以自行尝试
如果你使用了模拟器的多开功能，它们的 Serial 将不是默认的，可以在 console.bat 中执行 `adb devices` 查询，或根据模拟器官方的教程填写''',
  I18n.handle: '句柄 Handle',
  I18n.handleHelp:
      '''填 "auto" 自动检测模拟器，多个模拟器正在运行或使用不支持自动检测的模拟器时无法使用 "auto"，必须手动填写
输入为句柄标题或者是句柄号，每次启动模拟器时句柄号会变化。清空表示不使用window的操作方式。

句柄标题 Handle:
[MuMu模拟器12]: "MuMu模拟器12"
[MuMu模拟器]: "MuMu模拟器" 
[雷电模拟器](全系列通用): "雷电模拟器"

句柄号 Handle:
某些模拟器多开时具有相同的句柄标题（说的就是MuMu），此时需要手动获取模拟器的句柄号手动设置。
获取工具请查阅文档：[模拟器支持]''',
  I18n.packageName: '游戏客户端',
  I18n.packageNameHelp: '模拟器上装有多个游戏客户端时，需要手动选择服务器',
  I18n.screenshotMethod: '模拟器截屏方案',
  I18n.screenshotMethodHelp: '''使用自动选择时，将执行一次性能测试并自动更改为最快的截图方案。一般情况下的速度: 
window_background ~= nemu_ipc >>> DroidCast_raw >  ADB_nc >> DroidCast > uiautomator2 ~= ADB
使用window_background来截图是10ms左右，对比DroidCast_raw是100ms左右（仅限作者的电脑）。但是window_background有一个致命的缺点是模拟器不可以最小化，
nemu_ipc仅限mumu12模拟器且要求版本大于3.8.13，并且需要设置模拟器的执行路径''',
  I18n.controlMethod: '模拟器控制方案',
  I18n.controlMethodHelp:
      '''速度: window_message ~= minitouch > Hermit >>> uiautomator2 ~= ADB
控制方式是模拟人类的速度，也不是越快越好 使用(window_message)会偶尔出现失效的情况''',
  I18n.emulatorinfoType: '模拟器类型',
  I18n.emulatorinfoTypeHelp: '''选择你使用的模拟器类型
            ''',
  I18n.emulatorinfoName: '模拟器名称',
  I18n.emulatorinfoNameHelp: '''示例: MuMuPlayer-12.0-0, 若不清楚请查阅文档
            ''',
  I18n.emulatorWindowMinimize: '启用模拟器窗口最小化',
  I18n.runBackgroundOnly: '启用模拟器仅后台运行',
  I18n.adbRestart: '在检测不到设备的时候尝试重启adb',
  I18n.adbRestartHelp: '',
  I18n.handleError: '启用异常处理',
  I18n.handleErrorHelp: '处理部分异常，运行出错时撤退',
  I18n.saveError: '出错时，保存 Log 和截图',
  I18n.screenshotLength: '出错时，保留最后 X 张截图',
  I18n.notifyEnable: '启用消息推送',
  I18n.notifyConfig: '消息推送配置',
  I18n.notifyConfigHelp: '输入为yaml格式，":"冒号后有一个空格，具体请翻阅文档[消息推送]',
  I18n.screenshotInterval: '放慢截图速度至 X 秒一张',
  I18n.screenshotIntervalHelp: '执行两次截图之间的最小间隔，限制在 0.1 ~ 0.3，对于高配置电脑能降低 CPU 占用',
  I18n.combatScreenshotInterval: '战斗中放慢截图速度至 X 秒一张',
  I18n.combatScreenshotIntervalHelp:
      '执行两次截图之间的最小间隔，限制在 0.1 ~ 1.0，能降低战斗时的 CPU 占用',
  I18n.taskHoardingDuration: '囤积任务 X 分钟',
  I18n.taskHoardingDurationHelp: '能在收菜期间降低操作游戏的频率,任务触发后，等待 X 分钟，再一次性执行囤积的任务',
  I18n.whenTaskQueueEmpty: '当任务队列清空后',
  I18n.whenTaskQueueEmptyHelp: '无任务时关闭游戏，能在收菜期间降低 CPU 占用',
  I18n.scheduleRule: '选择任务调度规则',
  I18n.scheduleRuleHelp: '''这里所指的调度的对象是指Pending中的，Waiting中的任务不属于。
基于过滤器(Filter)的调度：默认的选项，任务的执行顺序会根据开发时所确定的顺序来调度，一般是最优解
基于先来后到(FIFO)的调度：是会按照下次执行时间进行排序，靠前的先执行
基于优先级(Priority)的调度：高优先级先于低优先级执行，同优先级按照先来后到顺序''',
  'emulatorinfo_path': '模拟器路径',
  'emulatorinfo_path_help':
      '举例："E:\\ProgramFiles\\MuMuPlayer-12.0\\shell\\MuMuPlayer.exe"',
  'desktop': '桌面版设置',
  'enable': '启用',
  'desktop_enable_help':
      '开启此项则控制电脑上的阴阳师桌面版，窗口可以互相遮挡，但不能最小化。\n游戏用管理员启动时，OAS 也需要用管理员启动，否则会点不动。\n高分辨率屏幕需在游戏目录 bin\\onmyoji.exe 的 属性-兼容性-高DPI设置 中勾选“替代高DPI缩放行为”，否则点击位置会偏。',
  'game_path': '游戏安装目录',
  'game_path_help': '游戏安装目录（如 D:\\yys），留空自动查找。',
  'profile_dir': '档案目录',
  'profile_dir_help':
      '多开账号隔离：每个配置填一个不同目录（如 D:/yys-profiles/p1），无需手动创建，OAS 会自动准备好。\n填了之后每个实例拥有独立的游戏数据和账号。\n留空 = 和直接双击打开的游戏共享账号。',
  'window_pos': '窗口位置',
  'window_pos_help': '多开时自动把窗口移到指定位置，格式 横,竖（如 0,0 / 660,0）；留空不移动。',
  'window_title': '窗口标题',
  'window_title_help':
      '多开时用来在任务栏区分实例：OAS 绑定该客户端时会把窗口标题改成它。\n留空 = 保持客户端默认标题，改动在下次启动或认领客户端时生效。识别和点击都不依赖标题，填不填都能正常跑。',
  'launch_instance': '启动客户端实例',
  'launch_instance_help':
      '一次性按钮：点击后按上面的设置启动本配置对应的客户端，已在运行则跳过。\n它是按钮不是开关，点击后自动弹回，不会保存为开启。',
  'next_run': '下次运行',
  'priority': '优先级',
  'success_interval': '成功间隔',
  'failure_interval': '失败间隔',
  'server_update': '服务器刷新',
  'antiban_enable_help':
      '开启后启用作息约束（睡眠时间窗、累计活跃上限、强制休息），用于避免24小时不间断/深夜连续运行这类服务端可见的异常行为特征。\n注意：点击/滑动的拟人化（真实按压时长、坐标高斯化、微动、压力抖动）始终生效，不受此开关控制。',
  'auto_fill': '自动填充',
  'auto_fill_help': '开启后使用智能放入寄养式神',
  'close_emulator_limit_time': '关闭模拟器时限',
  'close_emulator_limit_time_help': '此时间内不会关闭模拟器, 防止运行间隔时间短的多个任务导致反复开关模拟器',
  'close_game_limit_time': '关闭游戏时限',
  'close_game_limit_time_help': '此时间内不会关闭游戏, 防止运行间隔时间短的多个任务导致反复开关游戏',
  'continuous_task_rest_enable': '连续任务间休息',
  'continuous_task_rest_enable_help': '开启后，脚本在未进入任务等待状态的情况下连续执行达到随机间隔时，会暂停2至20分钟后再继续调度。功能独立于低配模式。',
  'continuous_task_rest_interval': '连续任务休息间隔',
  'continuous_task_rest_interval_help': '输入两个正整数，例如60,120。每轮连续执行开始时，在该范围内均匀随机抽取一个整数分钟作为本轮休息触发间隔。',
  'daily_active_limit': '每日活跃上限',
  'daily_active_limit_help':
      '累计活跃时长达到此值后强制长休息一段（休息结束重新计）。设为 0 表示不限制。用于打破长时间不间断在线。格式：天 时:分:秒。',
  'emulator_startup_lead_time': '模拟器启动提前量',
  'emulator_startup_lead_time_help': '在开始运行任务之前提前启动模拟器的时间',
  'enable_help': '是否启用',
  'error_repeated': '多次出错关闭模拟器',
  'failure_interval_help': '任务失败后的重试间隔',
  'long_rest_duration': '长休息时长',
  'long_rest_duration_help': '触发累计活跃上限后的强制休息时长。格式：天 时:分:秒。',
  'low_spec_mode': '低配模式',
  'low_spec_mode_help':
      '默认关闭。开启后截图帧保留10秒，OCR请求超时提高到30秒并启用短期结果缓存，图像对比阈值保持不变。修改后需停止当前运行的脚本，再重新启动脚本生效。',
  'priority_help': '任务优先级，多个任务同时到期时数值越小越先执行',
  'resource_precache_enable': '资源预缓存',
  'resource_precache_enable_help':
      '默认关闭。开启后，脚本启动时会先将当前使用的OCR模型加载到OCR服务内存，预缓存完成后才开始执行任务。修改后需停止当前运行的脚本，再重新启动脚本生效。',
  'restart_when_window_exists': '窗口已存在时重启',
  'restart_when_window_exists_help':
      'Restart 任务遇到桌面客户端时，若窗口还在，是否先杀掉再重新拉起（真正的重启），而不是只重走一次登录流程。\n开启后能救回卡在坏状态的客户端，但会中断正在手玩的客户端；默认关闭。',
  'run_count': '执行次数',
  'sleep_end': '睡眠窗结束',
  'sleep_end_help': '退出睡眠时间窗、恢复运行的时刻。',
  'sleep_start': '睡眠窗开始',
  'sleep_start_help':
      '进入睡眠时间窗的时刻。此区间内停止一切操作，并按“任务队列清空后”的空闲策略关闭游戏/模拟器，到点自动唤醒。支持跨午夜（如 23:00 到次日 06:00）。',
  'success_interval_help': '任务成功后的额外等待间隔',
};
