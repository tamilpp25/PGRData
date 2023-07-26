-- 新手任务（二期）配置管理类
local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs
XNewbieTaskConfigs = XNewbieTaskConfigs or {}

XNewbieEventType = {
    FIRST_ENTER = 101, --每日首进
    NOT_FIRST_ENTER = 102, --非每日首进
    REWARD = 120, --有未领取奖励
    REWARD_TAB = 10004, --领取完毕某个页签所有奖励
    CLICK = 10001, --点击
    CLICK_UNLOCK_TAB = 10002, -- 点击未解锁页签
    REWARD_PROGRESS = 10003, --点击阶段奖励页签
    IDLE = 1, --闲置
}

local SHARE_NEWBIE_TASK_GROUP_PATH = "Share/Task/NewbieTaskGroup.tab"
local CLIENT_SAILIKA_ANIM_PATH = "Client/Ui/SailikaAnim.tab"

local TableSailikaAnim
local TableNewbieTaskGroup

local TableAnimConditionIdIndex = {}
local TableRegisterDayIndex = {}

function XNewbieTaskConfigs.Init()
    TableSailikaAnim = XTableManager.ReadByIntKey(CLIENT_SAILIKA_ANIM_PATH, XTable.XTableSailikaAnim, "Id")
    TableNewbieTaskGroup = XTableManager.ReadByIntKey(SHARE_NEWBIE_TASK_GROUP_PATH, XTable.XTableNewbieTaskGroup, "Id")

    TableAnimConditionIdIndex = {}
    for _, config in pairs(TableSailikaAnim) do
        if not TableAnimConditionIdIndex[config.ConditionId] then
            TableAnimConditionIdIndex[config.ConditionId] = {}
        end
        tableInsert(TableAnimConditionIdIndex[config.ConditionId], config)
    end

    TableRegisterDayIndex = {}
    for _, config in pairs(TableNewbieTaskGroup) do
        TableRegisterDayIndex[config.RegisterDay] = config
    end
end

--region 新手任务组相关
    
function XNewbieTaskConfigs.GetNewbieTaskGroupConfig()
    if not TableNewbieTaskGroup then
        return nil
    end
    return TableNewbieTaskGroup
end

function XNewbieTaskConfigs.GetNewbieTaskIdByDay(day)
    local config = TableRegisterDayIndex[day]
    if not config then
        XLog.ErrorTableDataNotFound("GetNewbieTaskIdByDay", "tab", SHARE_NEWBIE_TASK_GROUP_PATH, "day", tostring(day))
        return nil
    end
    return config.TaskId or {}
end

--endregion

--region Spine动画相关

-- 获取表数据
function XNewbieTaskConfigs.GetAnimConfig()
    if not TableSailikaAnim then
        return nil
    end
    
    return TableSailikaAnim
end

-- 获取数据通过id
function XNewbieTaskConfigs.GetAnimConfigById(id)
    local config = TableSailikaAnim[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetAnimConfigById", "tab", CLIENT_SAILIKA_ANIM_PATH, "id", tostring(id))
        return nil
    end
    return config
end

-- 获取被动事件
function XNewbieTaskConfigs.GetPassiveAnimConfig()
    if not TableSailikaAnim then
        return nil
    end
    
    local configs = {}
    for _, v in pairs(TableSailikaAnim) do
        if v.ConditionId < 10000 and v.ConditionId >= 100 then --被动事件少于10000 大于=100
            tableInsert(configs, v)
        end
    end
    
    return configs
end

-- 获取conditionId所有的事件
function XNewbieTaskConfigs.GetAnimConfigByConditionId(conditionId)
    local all = {}

    if TableAnimConditionIdIndex then
        local configs = TableAnimConditionIdIndex[conditionId]
        if configs then
            for _, v in ipairs(configs) do
                tableInsert(all, v)
            end
        end
    end
    
    return all
end

-- 根据操作获取表数据
function XNewbieTaskConfigs.GetAnimConfigByFeedback(conditionId, param)
    if not TableSailikaAnim then
        return nil
    end
    
    local configs = XNewbieTaskConfigs.GetAnimConfigByConditionId(conditionId)

    if not configs or #configs <= 0 then
        return nil
    end

    if not param or param < 0 then
        return configs
    end

    local fitterCfg = {}

    if conditionId == XNewbieEventType.CLICK then
        for _, var in ipairs(configs) do
            if var.ConditionParam < 0 or var.ConditionParam == param then
                table.insert(fitterCfg, var)
            end
        end
    end

    return fitterCfg
end

--endregion