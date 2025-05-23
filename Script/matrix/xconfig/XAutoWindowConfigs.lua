XAutoWindowConfigs = XAutoWindowConfigs or {}

XAutoWindowConfigs.AutoType = {
    EachTime  = 1,     -- 每次登陆弹出
    EachDay   = 2,     -- 每天登陆弹出
    EachWeek  = 3,     -- 每周登陆弹出
    EachMonth = 4,     -- 每月登陆弹出
    Period    = 5,     -- 周期内弹出
}

XAutoWindowConfigs.AutoFunctionType = {
    AutoWindowView  = 1,     -- 自动弹出公告
    Sign            = 2,     -- 签到
    FirstRecharge   = 3,     -- 首充
    Card            = 4,     -- 月卡
    Regression      = 5,     -- 回归活动(特殊处理类型)
    NewRegression   = 6,     -- 新回归活动(特殊处理类型)
    WeekChallenge   = 7,     -- 周挑战(特殊处理类型)
    SummerSignIn   = 8,      -- 夏日签到
    NoticeActivity = 9,      -- 原公告内的活动
    Regression3rd  = 10,     -- 回归活动3期
    SClassConstructNovice  = 11,  -- 新手S礼包
    WeekCard       = 12,     -- 周卡
}

XAutoWindowConfigs.AutoWindowSkinType = {
    None = 0,       -- 未知
    BarSkin = 1,    -- 条幅
    BigSkin = 2,    -- 大图
    SpineSkin = 3,  -- Spine动画
}

local TABLE_AUTO_WINDOW_VIEW       = "Client/AutoWindow/AutoWindowView.tab"
local TABLE_AUTO_WINDOW_CONTROLLER = "Client/AutoWindow/AutoWindowController.tab"

local AutoWindowViewConfig = {}         -- 自动弹窗公告配置表
local AutoWindowControllerConfig = {}   -- 自动弹窗控制配置表

function XAutoWindowConfigs.Init()
    AutoWindowViewConfig = XTableManager.ReadByIntKey(TABLE_AUTO_WINDOW_VIEW, XTable.XTableAutoWindowView, "Id")
    AutoWindowControllerConfig = XTableManager.ReadByIntKey(TABLE_AUTO_WINDOW_CONTROLLER, XTable.XTableAutoWindowController, "Id")
end

function XAutoWindowConfigs.GetAutoWindowConfig(id)
    local t = AutoWindowViewConfig[id]
    if not t then
        XLog.ErrorTableDataNotFound("XAutoWindowConfigs.GetAutoWindowConfig", "配置表项", TABLE_AUTO_WINDOW_VIEW, "id", tostring(id))
        return nil
    end

    return t
end

function XAutoWindowConfigs.GetAutoWindowSkinType(id)
    local t = XAutoWindowConfigs.GetAutoWindowConfig(id)
    if t then
        return t.Type
    end

    return 0
end

function XAutoWindowConfigs.GetAutoWindowControllerConfig()
    return AutoWindowControllerConfig
end