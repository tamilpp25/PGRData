local XDoubleTowerPluginDb = require("XEntity/XDoubleTowers/XDoubleTowerPluginDb")
local XDoubleTowerTeamDb = require("XEntity/XDoubleTowers/XDoubleTowerTeamDb")

---@class XDoubleTowersInfo@通行证基础信息
local XDoubleTowersInfo = XClass(nil, "XDoubleTowersInfo")

function XDoubleTowersInfo:Ctor()
    self._ActivityId = XDoubleTowersConfigs.GetDefaultActivityId()

    self._CacheCoin = 0

    self._CacheCoinLastTime = 0

    self._SpecialStageWinCount = 0

    ---@type DoubleTowerStageDb[]
    self._StageDbDict = {}

    self._PluginDbs = {}
    self._TeamDb = XDoubleTowerTeamDb.New()

    self._JustPassedStage = false
end

---@param data XDoubleTowerDb
function XDoubleTowersInfo:UpdateData(data)
    if XTool.IsNumberValid(data.ActivityId) then
        self._ActivityId = data.ActivityId
    end
    self:SetCacheCoin(data.CacheCoin)
    self._CacheCoinLastTime = data.CacheCoinLastTime or 0
    -- self._ChapterDbList = data.ChapterDbList--这个好像没什么用
    self._SpecialStageWinCount = data.SpecialStageWinCount or 0

    -- list -> dictionary
    self._StageDbDict = {}
    if data.StageDbList then
        for i = 1, #data.StageDbList do
            local stageDb = data.StageDbList[i]
            self._StageDbDict[stageDb.Id] = stageDb
        end
    end

    for _, pluginDb in ipairs(data.PluginDbs) do
        self:UpdatePluginDb(pluginDb)
    end

    self._TeamDb:UpdateData(data.TeamDb)
end

function XDoubleTowersInfo:UpdatePluginDb(pluginDb)
    local pluginDbTemp = self._PluginDbs[pluginDb.Id]
    if not pluginDbTemp then
        pluginDbTemp = XDoubleTowerPluginDb.New()
        self._PluginDbs[pluginDb.Id] = pluginDbTemp
    end
    pluginDbTemp:UpdateData(pluginDb)
end

--重置插件
function XDoubleTowersInfo:ResetPlugin(pluginId, level)
    local pluginDb = self:GetPluginDb(pluginId)
    if XTool.IsTableEmpty(pluginDb) then
        return
    end
    if level == 0 then
        self._PluginDbs[pluginId] = nil
    else
        pluginDb:SetLevel(level)
    end
end

--获得插件的等级Id
function XDoubleTowersInfo:GetPluginLevelId(pluginId)
    local pluginDb = self:GetPluginDb(pluginId)
    if XTool.IsTableEmpty(pluginDb) then
        return 0
    end
    local level = pluginDb:GetLevel()
    return XDoubleTowersConfigs.GetPluginLevelId(pluginId, level)
end

--==============================
---@desc 未解锁时获取数据用于UI显示
--==============================
function XDoubleTowersInfo:GetPluginLevelDefaultId(pluginId)
    local pluginDb = self:GetPluginDb(pluginId)
    local level
    if XTool.IsTableEmpty(pluginDb) then
        level = 1
    else
        level = pluginDb:GetLevel()
    end
    return XDoubleTowersConfigs.GetPluginLevelId(pluginId, level)
end

--获得插件下一级的等级Id
function XDoubleTowersInfo:GetPluginNextLevelId(pluginId)
    local pluginDb = self:GetPluginDb(pluginId)
    if XTool.IsTableEmpty(pluginDb) then
        return 0
    end

    local curLevel = pluginDb:GetLevel()
    local levelIdList = XDoubleTowersConfigs.GetPluginLevelIdList(pluginId)
    for _, levelId in ipairs(levelIdList) do
        local level = XDoubleTowersConfigs.GetPluginLevel(levelId)
        if level > curLevel then
            return levelId
        end
    end
    return 0
end

function XDoubleTowersInfo:GetActivityId()
    return self._ActivityId
end

---@return number@上次收菜时间
function XDoubleTowersInfo:GetLastGatherTime()
    return self._CacheCoinLastTime
end

function XDoubleTowersInfo:SetLastGatherTime(value)
    self._CacheCoinLastTime = value
end

---@return boolean@是否通关
function XDoubleTowersInfo:IsStagePassed(stageId)
    if not self._StageDbDict then
        return false
    end
    local stageDb = self._StageDbDict[stageId]
    if not stageDb then
        return false
    end
    return stageDb.WinCount > 0
end

---@return number@ 特殊关卡的通关次数
function XDoubleTowersInfo:GetSpecialStageWinCount()
    return self._SpecialStageWinCount
end

function XDoubleTowersInfo:SetCacheCoin(amount)
    self._CacheCoin = amount or 0
end

function XDoubleTowersInfo:IncreaseWinCount(stageId)
    local stageDb = self._StageDbDict[stageId]
    if stageDb then
        stageDb.WinCount = stageDb.WinCount + 1
    else
        self._StageDbDict[stageId] = {
            Id = stageId,
            WinCount = 1
        }
    end
    if XDataCenter.DoubleTowersManager.IsSpecialStage(stageId) then
        self._SpecialStageWinCount = self._SpecialStageWinCount + 1
    end
end

function XDoubleTowersInfo:GetCacheCoin()
    return self._CacheCoin
end

function XDoubleTowersInfo:GetTeamDb()
    return self._TeamDb
end

function XDoubleTowersInfo:GetPluginDb(pluginId)
    return self._PluginDbs[pluginId] or {}
end

function XDoubleTowersInfo:GetPluginList()
    local list = {}
    for pluginId, _ in pairs(self._PluginDbs) do
        if XTool.IsNumberValid(pluginId) then
            table.insert(list, pluginId)
        end
    end
    return list
end

function XDoubleTowersInfo:GetPluginListByType(pluginType)
    local list = XDoubleTowersConfigs.GetDoubleTowerPluginIdList(pluginType) or {}
    local tempList = {}
    for id, _ in pairs(self._PluginDbs) do
        local valid = XTool.IsNumberValid(id) and table.contains(list, id)
        if valid then
            table.insert(tempList, id)
        end
    end
    return tempList
end

function XDoubleTowersInfo:SetJustPassedStage(stageId)
    self._JustPassedStage = stageId
end

function XDoubleTowersInfo:GetJustPassedStage()
    local stageId = self._JustPassedStage
    self._JustPassedStage = false
    return stageId
end

return XDoubleTowersInfo

---@alias XDoubleTowerDb {ActivityId:number,TeamDb:DoubleTowerTeamDb,ChapterDbList:DoubleTowerChapterDb[],CacheCoinLastTime:number,CacheCoin:number,PluginDbs:DoubleTowerPluginDb[],StageDbList:DoubleTowerStageDb[],SepcialStageWinCount:number}
---@alias DoubleTowerStageDb {Id:number,WinCount:number}
---@alias DoubleTowerTeamDb {RoleId:number,RoleBasePluginLevelId:number,RolePluginList:number[],GuardId:number,GuardPluginList:number[],GuardBasePluginLevelId:number}
---@alias DoubleTowerChapterDb {Id:number,WinCount:number}
---@alias DoubleTowerPluginDb {Id:number,Level:number}
---@alias XDoubleTowerRankPlayer {}
---@alias XDoubleTowerRank {}
---@alias SyncDoubleTowerRank {Rank:XDoubleTowerRank}
---@alias NotifyDoubleTowerChange {ActivityDb:XDoubleTowerDb}
