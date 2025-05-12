--#region 庙会规划师
--[Description("庙会规划师-活动暂未开放")]
--TempleFairActivityNotOpen = 20220001,
--[Description("庙会规划师-请先通过上一关卡")]
--TempleFairPreStageNotPass,
--[Description("庙会规划师-关卡未开启")]
--TempleFairStageNotOpen,
--[Description("庙会规划师-关卡进行中")]
--TempleFairStageIsInProgress,
--[Description("庙会规划师-关卡找不到配置")]
--TempleFairStageConfigNotFound,
--[Description("庙会规划师-同步数据错误")]
--TempleFairSyncDataError,
--[Description("庙会规划师-结算数据错误")]
--TempleFairSettleDataError,
--#endregion

local XTempleEnumConst = {
    GRID = {
        EMPTY = 0,
        DEFAULT = 1,
    },
    ACTION = {
        NONE = 0,
        SKIP = 1, --跳过
        PUT_DOWN = 2, --放下地块
        ROTATE = 3, --旋转地块
        DRAG = 4, --移动地块
        CONFIRM = 5, --确定地块摆放
        CANCEL = 6, --取消
    },
    TIME_OF_DAY = {
        BEGIN = 0,
        MORNING = 1,
        AFTERNOON = 2,
        DUSK = 3,
        NIGHT = 4,
        END = 5,
    },
    RULE = {
        DEFAULT = 1001,
        SHAPE = 7001,
    },
    EDIT_TYPE = {
        PARAMS = 1,
        SCORE = 2,
        RULE_TYPE = 3,
        TIME = 4,
    },
    BLOCK = {
        SKIP = -1,
        RANDOM = -2,
    },
    BLOCK_GRID_AMOUNT = 6,
    MAP_SIZE = 11,
    CHAPTER = {
        SPRING = 1, -- 春节
        COUPLE = 2, -- 情人节
        LANTERN = 3, -- 元宵节
    },
    SKIP_SPEND = 1,
    OPTIONS_AMOUNT = 3,
    GRID_TYPE_EDITOR = 0x2000000,
    RULE_BLOCK_EDITOR = 0x1000000,
    RULE_TIPS_BLOCK = 0x4000000,
    LINE = {
        ROW = 0, -- 行
        COLUMN = 1, -- 列
    },
    NPC_TALK = {
        STAGE_ENTER = 1,
        SUCCESS = 2,
        REFRESH_BLOCK = 3,
        CHOOSE_BLOCK = 4,
        MOVE_BLOCK = 5,
        ROTATE_BLOCK = 6,
        CANCEL_BLOCK = 7,
        FAIL = 8,
    },
    TASK = {
        SPRING = 1001,
        COUPLE = 1002,
        LANTERN = 1003,
    },
    GRID_FUSION = {
          FUSION = 1,
          RANDOM = 2,
    },
}

return XTempleEnumConst