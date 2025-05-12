local XTeam =  require("XEntity/XTeam/XTeam")
local XTwoSideTowerActivity = require("XModule/XTwoSideTower/XEntity/XTwoSideTowerActivity")
--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local TableKey = {
    TwoSideTowerActivity = { CacheType = XConfigUtil.CacheType.Normal },
    TwoSideTowerChapter = { CacheType = XConfigUtil.CacheType.Normal },
    TwoSideTowerFeature = {},
    TwoSideTowerPoint = {},
    TwoSideTowerStage = {},
    TwoSideTowerClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key"
    },
}

---@class XTwoSideTowerModel : XModel
---@field ActivityData XTwoSideTowerActivity
local XTwoSideTowerModel = XClass(XModel, "XTwoSideTowerModel")
function XTwoSideTowerModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("Fuben/TwoSideTower", TableKey)
    
    -- 关卡战斗结果 是否第一次通关
    self.FirstCleared = false
    -- 编队信息
    ---@type XTeam
    self.TwoSideTowerTeam = nil
end

function XTwoSideTowerModel:ClearPrivate()
    --这里执行内部数据清理
end

function XTwoSideTowerModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.FirstCleared = false
    self.TwoSideTowerTeam = nil
end

--region 服务端信息更新和获取

-- 刷新活动数据
function XTwoSideTowerModel:NotifyTwoSideTowerActivityData(data)
    if not data or not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    if not self.ActivityData then
        self.ActivityData = XTwoSideTowerActivity.New()
    end
    self.ActivityData:NotifyTwoSideTowerActivityData(data)
end

-- 刷新章节数据
function XTwoSideTowerModel:NotifyTwoSideTowerChapterData(data)
    if self.ActivityData then
        self.ActivityData:AddChapterInfo(data)
    end
end

-- 获取当前活动Id
function XTwoSideTowerModel:GetCurActivityId()
    if self.ActivityData then
        return self.ActivityData:GetActivityId()
    end
    return 0
end

-- 获取章节最大分数
function XTwoSideTowerModel:GetMaxChapterScore(chapterId)
    if self.ActivityData then
        return self.ActivityData:GetMaxChapterScore(chapterId)
    end
    return 0
end

-- 获取章节上一次分数
function XTwoSideTowerModel:GetLastChapterScore(chapterId)
    if self.ActivityData then
        return self.ActivityData:GetLastChapterScore(chapterId)
    end
    return 0
end

-- 检查章节是否通关
function XTwoSideTowerModel:CheckChapterCleared(chapterId)
    if self.ActivityData then
        return self.ActivityData:CheckChapterCleared(chapterId)
    end
    return false
end

-- 检查关卡是否通关
function XTwoSideTowerModel:CheckPassedByStageId(stageId)
    if self.ActivityData then
        return self.ActivityData:CheckPassedByStageId(stageId)
    end
    return false
end

--endregion

--region 活动表相关

---@return XTableTwoSideTowerActivity
function XTwoSideTowerModel:GetActivityConfig()
    local activityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerActivity, activityId)
end

-- 获取活动时间id
function XTwoSideTowerModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

--endregion

--region 章节表相关

---@return XTableTwoSideTowerChapter
function XTwoSideTowerModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerChapter, chapterId)
end

--endregion

--region Feature表相关

---@return XTableTwoSideTowerFeature
function XTwoSideTowerModel:GetFeatureConfig(featureId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerFeature, featureId)
end

--endregion

--region Point表相关

---@return XTableTwoSideTowerPoint
function XTwoSideTowerModel:GetPointConfig(pointId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerPoint, pointId)
end

--endregion

--region Stage表相关

---@return XTableTwoSideTowerStage
function XTwoSideTowerModel:GetStageConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerStage, stageId)
end

--endregion

--region 客户端配置表相关

function XTwoSideTowerModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TwoSideTowerClientConfig, key)
    if not config then
        return ""
    end
    return config.Params and config.Params[index] or ""
end

--endregion

--region 编队信息

function XTwoSideTowerModel:GetCookieKeyTeam()
    local activityId = self:GetCurActivityId()
    return string.format("TwoSideTowerTeam_%s_%s", XPlayer.Id, activityId)
end

function XTwoSideTowerModel:GetTeam()
    if not self.TwoSideTowerTeam then
        self.TwoSideTowerTeam = XTeam.New(self:GetCookieKeyTeam())
    end
    return self.TwoSideTowerTeam
end

--endregion

--region 红点相关

-- 检查是否有可领取的任务红点
function XTwoSideTowerModel:CheckTaskAchievedRedPoint(taskGroupIds)
    local taskList = {}
    for _, groupId in pairs(taskGroupIds) do
        local tasks = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, false)
        taskList = XTool.MergeArray(taskList, tasks)
    end
    if XTool.IsTableEmpty(taskList) then
        return false
    end
    for _, task in pairs(taskList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(task.Id) then
            return true
        end
    end
    return false
end

-- 检查是否有新章节开启红点
function XTwoSideTowerModel:CheckNewChapterOpenRedPoint(chapterIds)
    if XTool.IsTableEmpty(chapterIds) then
        return false
    end
    for _, chapterId in pairs(chapterIds) do
        if not self:GetChapterIsClick(chapterId) and self:CheckChapterIsOpen(chapterId) then
            return true
        end
    end
    return false
end

-- 检查章节是否开启
function XTwoSideTowerModel:CheckChapterIsOpen(chapterId)
    local chapterCfg = self:GetChapterConfig(chapterId)
    if not chapterCfg then
        return false
    end
    local inTime = XFunctionManager.CheckInTimeByTimeId(chapterCfg.TimeId)
    if not inTime then
        return false
    end
    local unlockChapterIds = chapterCfg.UnlockChapterIds or {}
    for _, id in pairs(unlockChapterIds) do
        if not self:CheckChapterCleared(id) then
            return false
        end
    end
    return true
end

--endregion

--region 本地数据相关

-- 章节特性总览key
function XTwoSideTowerModel:GetChapterOverviewSaveKey(chapterId)
    local activityId = self:GetCurActivityId()
    return string.format("TwoSideTowerChapterOverviewKey_%s_%s_%s", XPlayer.Id, activityId, chapterId)
end

-- 章节点击key
function XTwoSideTowerModel:GetChapterIsClickKey(chapterId)
    local activityId = self:GetCurActivityId()
    return string.format("TwoSideTowerChapterIsClickKey_%s_%s_%s", XPlayer.Id, activityId, chapterId)
end

function XTwoSideTowerModel:GetChapterIsClick(chapterId)
    local key = self:GetChapterIsClickKey(chapterId)
    return XSaveTool.GetData(key) or false
end

-- 关卡进入战斗提示Key
function XTwoSideTowerModel:GetBattleDialogHintCookieKey()
    local activityId = self:GetCurActivityId()
    return string.format("TwoSideTowerBattleDialogHintKey_%s_%s", XPlayer.Id, activityId)
end

--endregion


return XTwoSideTowerModel
