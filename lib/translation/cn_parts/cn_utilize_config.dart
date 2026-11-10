// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_utilize_config = {
  'utilize_config': '结界蹭卡配置',
  'utilize_rule': '寄养规则',
  'utilize_rule_help': '挑选结界卡的规则，使用默认default即可，具体规则看文档[任务列表]，不可以选auto,已经弃置了。',
  'select_friend_list': '选择同区还是跨区好友',
  'select_friend_list_help': '''由于该死的游戏制作水准，无论任何方式都不可以稳定的对结界卡进行排序，需要从头到尾遍历一遍。
且切换好友列表时候会丢失原先选定的好友卡，为此同时选择两个好友列表的最优解是会花费更多的时间，不打算支持''',
  'shikigami_class': '寄养式神类型',
  'shikigami_class_help': '选择的式神类别（寄养默认选择N卡，且不建议选别的）',
  'shikigami_order': '选中第几个式神寄养',
  'shikigami_order_help': '从左开始选第几个式神',
  'guild_ap_enable': '顺路收取寮补给',
  'guild_ap_enable_help': '必选项',
  'guild_assets_enable': '顺路收取寮资金',
  'guild_assets_enable_help': '必选项',
  'box_ap_enable': '顺路收取体力盒子',
  'box_ap_enable_help': '必选项',
  'box_exp_enable': '顺路收取经验盒子',
  'box_exp_enable_help': '必选项',
  'box_exp_waste': '从盒子提取经验时浪费一部分',
  'box_exp_waste_help':
      '某些时候寄养上存在满级的式神，收取经验盒子时会有提示，对于挂机玩家这点经验微不足道。如果不使能这一选项，将跳过收取经验盒子',
  'harvest_guild_max_times': '收取寮卡上限次数',
  'harvest_guild_max_times_help': '多次尝试收取, 防止寮资金/体力/抽奖/...有遗漏没做',
  'lazy_mode': '怠惰模式',
  'lazy_mode_help':
      '开启后每次任务按权重随机进入怠惰模式；命中时不比较奖励数值，优先选择当前可见的五星及以上目标卡，否则选择首个符合策略的四星卡。',
  'lazy_mode_weight': '怠惰模式收益权重',
  'lazy_mode_weight_help': '取值范围0-1，默认1；0表示永不触发，1表示每次触发。',
  'min_fish_value': '斗鱼最低收益',
  'min_fish_value_help': '只蹭体力收益不低于此值的斗鱼卡（5星118-134，6星134-151），0为不限制',
  'min_run_interval': '最短运行间隔',
  'min_run_interval_help':
      '防风控：两次蹭卡运行之间的最小间隔，避免蹭卡过于频繁被服务端标记。设为 0（默认）保持原逻辑（按结界卡剩余时间安排下次）。格式：天 时:分:秒。',
  'min_taiko_value': '太鼓最低收益',
  'min_taiko_value_help': '只蹭勾玉收益不低于此值的太鼓卡（5星59-67，6星67-76），0为不限制',
  'utilize_enable': '启用挂卡',
  'utilize_enable_help': '关闭则不会蹭卡, 但是其他操作会执行(例如收取寮奖励等)',
  'utilize_harvest': '自动收取',
  'utilize_harvest_help': '关闭则不领取, 可以屯奖励',
  'search_switch': '探查御魂分组',
};
