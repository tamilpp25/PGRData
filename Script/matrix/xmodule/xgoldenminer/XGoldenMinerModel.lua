---@class XGoldenMinerModel : XModel
local XGoldenMinerModel = XClass(XModel, "XGoldenMinerModel")

local TableKey = {
    --- System 活动总控
    GoldenMinerActivity = { CacheType = XConfigUtil.CacheType.Normal },
    --- Game Buff
    GoldenMinerBuff = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "BuffId", },
    --- Game 角色
    GoldenMinerCharacter = { },
    --- Game 关卡隐藏任务
    GoldenMinerHideTask = { CacheType = XConfigUtil.CacheType.Normal },
    --- Game 玩法道具
    GoldenMinerItem = { },
    --- Game 地图(大部分字段由编辑器生成)
    GoldenMinerMap = { Identifier = "MapId", },
    --- Game 关卡
    GoldenMinerStage = { Identifier = "StageId", },
    --- Game 配件
    GoldenMinerUpgrade = { },
    --- Game 海克斯
    GoldenMinerHex = { },

    --- 客户端参数配置
    GoldenMinerClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    --- Game 表情图标配置
    GoldenMinerFace = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 钩爪类型配置
    GoldenMinerFalculaType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type", },
    --- Game QTE组配置
    GoldenMinerQTELevelGroup = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 奖励箱配置
    GoldenMinerRedEnvelopeRandPool = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 剩余时间换算分数配置
    GoldenMinerScore = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 抓取物配置c
    GoldenMinerStone = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 抓取物类型配置
    GoldenMinerStoneType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type", },
    --- Game 插件升级客户端配置
    GoldenMinerUpgradeLocal = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 隐藏任务类型5画图检查配置
    GoldenMinerHideTaskMapDrawGroup = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- Game 辅助物
    GoldenMinerPartner = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "Type", },
    --- System 活动任务
    GoldenMinerTask = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    --- Game 飞船涂装
    GoldenMinerShipShell = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XGoldenMinerModel:OnInit()
    local XGoldenMinerDataDb = require("XModule/XGoldenMiner/Data/Server/XGoldenMinerDataDb")
    ---@type XGoldenMinerDataDb
    self._MineDb = XGoldenMinerDataDb.New(self)
    
    local XGoldenMinerRankData = require("XModule/XGoldenMiner/Data/Rank/XGoldenMinerRankDb")
    ---@type XGoldenMinerRankDb
    self._RankDb = XGoldenMinerRankData.New()
    
    self._ConfigUtil:InitConfigByTableKey("GoldenMiner", TableKey)
    self._IsCheckAutoInGameTips = true
    self._ShopGridLockCount = nil
    --- Debug初始化添加的buff
    self.DebugInitBuffList = nil
    ---@type UnityEngine.Vector2
    self._RectSize = Vector2.zero
end

function XGoldenMinerModel:ClearPrivate()
    --这里执行内部数据清理
end

function XGoldenMinerModel:ResetAll()
    --这里执行重登数据清理
end

--region Data - Cache
function XGoldenMinerModel:GetRectSize()
    return self._RectSize
end

function XGoldenMinerModel:SetRectSize(value)
    ---@type UnityEngine.Vector2
    self._RectSize = value
end

function XGoldenMinerModel:_GetCacheKey(key)
    return "XGoldenMiner_" .. XPlayer.Id .. "_" .. self:GetCurActivityId() .. "_" .. key
end

function XGoldenMinerModel:GetCacheData(key)
    return XSaveTool.GetData(self:_GetCacheKey(key))
end

function XGoldenMinerModel:SetCacheData(key, value)
    XSaveTool.SaveData(self:_GetCacheKey(key), value)
end

function XGoldenMinerModel:GetIsCheckAutoInGameTips()
    return self._IsCheckAutoInGameTips
end

function XGoldenMinerModel:SetIsCheckAutoInGameTips(value)
    self._IsCheckAutoInGameTips = value
end
--endregion

--region Data - MineDb
function XGoldenMinerModel:GetMineDb()
    return self._MineDb
end
--endregion

--region Data - RankData
function XGoldenMinerModel:GetRankDb()
    return self._RankDb
end
--endregion

--region Data - Activity
function XGoldenMinerModel:GetCurActivityId()
    local result = 0
    result = self._MineDb:GetActivityId()
    return result
end

function XGoldenMinerModel:GetCurActivityEndTime()
    local activityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then return 0 end
    local timeId = self:GetActivityCfgTimeId(activityId)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XGoldenMinerModel:GetCurActivityHexMapStages(index)
    local activityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then return 0 end
    local stageIndexList = self:GetActivityCfgHexMapStages(activityId)
    return stageIndexList and stageIndexList[index]
end

function XGoldenMinerModel:CheckIsOpen()
    local activityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then return false end
    local timeId = self:GetActivityCfgTimeId(activityId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end
--endregion

--region Data - Task
---@return XTaskData[]
function XGoldenMinerModel:GetTaskDataList(taskGroupId)
    local taskIdList = self:_GetTaskGroupCfgTaskId(taskGroupId)
    local taskList = {}
    local tastData
    for _, taskId in pairs(taskIdList) do
        tastData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if tastData then
            table.insert(taskList, tastData)
        end
    end

    local achieved = XDataCenter.TaskManager.TaskState.Achieved
    local finish = XDataCenter.TaskManager.TaskState.Finish
    table.sort(taskList, function(a, b)
        if a.State ~= b.State then
            if a.State == achieved then
                return true
            end
            if b.State == achieved then
                return false
            end
            if a.State == finish then
                return false
            end
            if b.State == finish then
                return true
            end
        end

        local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
        local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
        return templatesTaskA.Priority > templatesTaskB.Priority
    end)

    return taskList
end

--- 是否存在任务可奖励
function XGoldenMinerModel:CheckHaveTaskCanRecv()
    local configs = self:GetTaskGroupCfgList()
    for _, cfg in pairs(configs) do
        if self:CheckTaskCanRecvByTaskId(cfg.Id) then
            return true
        end
    end
    return false
end

--- 任务页签是否存在任务可领取
function XGoldenMinerModel:CheckTaskCanRecvByTaskId(taskGroupId)
    for _, taskId in ipairs(self:_GetTaskGroupCfgTaskId(taskGroupId)) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end
--endregion

--region Cfg - Activity
---@return XTableGoldenMinerActivity[]
function XGoldenMinerModel:GetActivityCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerActivity)
end

---@return XTableGoldenMinerActivity
function XGoldenMinerModel:GetActivityCfg(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerActivity, activityId)
end

function XGoldenMinerModel:GetActivityCfgTimeId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.TimeId
end

function XGoldenMinerModel:GetActivityCfgHexMapStages(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.HexMapStages
end
--endregion

--region Cfg - Buff
---@return XTableGoldenMinerBuff[]
function XGoldenMinerModel:GetBuffCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerBuff)
end

---@return XTableGoldenMinerBuff
function XGoldenMinerModel:GetBuffCfg(buffId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerBuff, buffId)
end

function XGoldenMinerModel:GetShopGridLockCount()
    if self._ShopGridLockCount then
        return self._ShopGridLockCount
    end
    for _, buff in pairs(self:GetBuffCfgList()) do
        if buff.BuffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHOP_DROP  then
            if self._ShopGridLockCount and self._ShopGridLockCount < buff.Params[1] then
                self._ShopGridLockCount = buff.Params[1]
            else
                self._ShopGridLockCount = buff.Params[1]
            end
        end
    end
end
--endregion

--region Cfg - Character
---@return XTableGoldenMinerCharacter[]
function XGoldenMinerModel:GetCharacterCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerCharacter)
end

---@return XTableGoldenMinerCharacter
function XGoldenMinerModel:GetCharacterCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerCharacter, id)
end

function XGoldenMinerModel:GetCharacterCfgCondition(id)
    local cfg = self:GetCharacterCfg(id)
    return cfg and cfg.Condition
end
--endregion

--region Cfg - HideTask
---@return XTableGoldenMinerHideTask[]
function XGoldenMinerModel:GetHideTaskCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerHideTask)
end

---@return XTableGoldenMinerHideTask
function XGoldenMinerModel:GetHideTaskCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerHideTask, id)
end
--endregion

--region Cfg - Item
---@return XTableGoldenMinerItem[]
function XGoldenMinerModel:GetItemCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerItem)
end

---@return XTableGoldenMinerItem
function XGoldenMinerModel:GetItemCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerItem, id)
end
--endregion

--region Cfg - Map
---@return XTableGoldenMinerMap[]
function XGoldenMinerModel:GetMapCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerMap)
end

---@return XTableGoldenMinerMap
function XGoldenMinerModel:GetMapCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerMap, id)
end
--endregion

--region Cfg - Stage
---@return XTableGoldenMinerStage[]
function XGoldenMinerModel:GetStageCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerStage)
end

---@return XTableGoldenMinerStage
function XGoldenMinerModel:GetStageCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerStage, id)
end
--endregion

--region Cfg - Upgrade
---@return XTableGoldenMinerUpgrade[]
function XGoldenMinerModel:GetUpgradeCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerUpgrade)
end

---@return XTableGoldenMinerUpgrade
function XGoldenMinerModel:GetUpgradeCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerUpgrade, id)
end

function XGoldenMinerModel:GetUpgradeCfgCosts(id, index)
    local cfg = self:GetUpgradeCfg(id)
    return cfg and index and cfg.UpgradeCosts[index]
end

function XGoldenMinerModel:GetUpgradeCfgBuffId(id, index)
    local cfg = self:GetUpgradeCfg(id)
    return cfg and index and cfg.UpgradeBuffs[index] or 0
end
--endregion

--region Cfg - ClientConfig
---@return XTableGoldenMinerClientConfig
function XGoldenMinerModel:GetClientConfigCfg(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerClientConfig, key)
end

function XGoldenMinerModel:GetClientCfgValue(key, index)
    local cfg = self:GetClientConfigCfg(key)
    index = index or 1
    if cfg and #cfg.Values < index then
        index = #cfg.Values
    end
    return cfg and cfg.Values[index]
end

function XGoldenMinerModel:GetClientCfgNumberValue(key, index)
    local value = self:GetClientCfgValue(key, index)
    if value then 
        return tonumber(value)
    end
    return 0
end
--endregion

--region Cfg - Face
---@return XTableGoldenMinerFace[]
function XGoldenMinerModel:GetFaceCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerFace)
end

---@return XTableGoldenMinerFace
function XGoldenMinerModel:GetFaceCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerFace, id)
end
--endregion

--region Cfg - FalculaType / Hook
---@return XTableGoldenMinerFalculaType[]
function XGoldenMinerModel:GetHookCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerFalculaType)
end

---@return XTableGoldenMinerFalculaType
function XGoldenMinerModel:GetHookCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerFalculaType, type)
end
--endregion

--region Cfg - QTELevelGroup
---@return XTableGoldenMinerQTELevelGroup[]
function XGoldenMinerModel:GetQTELevelGroupCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerQTELevelGroup)
end

---@return XTableGoldenMinerQTELevelGroup
function XGoldenMinerModel:GetQTELevelGroupCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerQTELevelGroup, id)
end
--endregion

--region Cfg - RedEnvelopeRandPool
---@return XTableGoldenMinerRedEnvelopeRandPool[]
function XGoldenMinerModel:GetRedEnvelopeRandPoolCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerRedEnvelopeRandPool)
end

---@return XTableGoldenMinerRedEnvelopeRandPool
function XGoldenMinerModel:GetRedEnvelopeRandPoolCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerRedEnvelopeRandPool, id)
end
--endregion

--region Cfg - Score
---@return XTableGoldenMinerScore[]
function XGoldenMinerModel:GetTimeScoreCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerScore)
end

---@return XTableGoldenMinerScore
function XGoldenMinerModel:GetTimeScoreCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerScore, id)
end
--endregion

--region Cfg - Stone
---@return XTableGoldenMinerStone[]
function XGoldenMinerModel:GetStoneCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerStone)
end

---@return XTableGoldenMinerStone
function XGoldenMinerModel:GetStoneCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerStone, id)
end
--endregion

--region Cfg - StoneType
---@return XTableGoldenMinerStoneType[]
function XGoldenMinerModel:GetStoneTypeCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerStoneType)
end

---@return XTableGoldenMinerStoneType
function XGoldenMinerModel:GetStoneTypeCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerStoneType, type)
end
--endregion

--region Cfg - UpgradeLocal
---@return XTableGoldenMinerUpgradeLocal[]
function XGoldenMinerModel:GetUpgradeLocalCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerUpgradeLocal)
end

---@return XTableGoldenMinerUpgradeLocal
function XGoldenMinerModel:GetUpgradeLocalCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerUpgradeLocal, id)
end
--endregion

--region Cfg - HideTaskMapDrawGroup
---@return XTableGoldenMinerHideTaskMapDrawGroup[]
function XGoldenMinerModel:GetHideTaskMapDrawGroupCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerHideTaskMapDrawGroup)
end

---@return XTableGoldenMinerHideTaskMapDrawGroup
function XGoldenMinerModel:GetHideTaskMapDrawGroupCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerHideTaskMapDrawGroup, id)
end
--endregion

--region Cfg - Task
---@return XTableGoldenMinerTask[]
function XGoldenMinerModel:GetTaskGroupCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerTask)
end

---@return XTableGoldenMinerTask
function XGoldenMinerModel:GetTaskGroupCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerTask, id)
end

function XGoldenMinerModel:_GetTaskGroupCfgTaskId(id)
    local cfg = self:GetTaskGroupCfg(id)
    return cfg and cfg.TaskId
end
--endregion

--region Cfg - Partner
---@return XTableGoldenMinerPartner[]
function XGoldenMinerModel:GetGoldenMinerPartnerCfgList()
    return self._ConfigUtil:GetByTableKey(TableKey.GoldenMinerPartner)
end

---@return XTableGoldenMinerPartner
function XGoldenMinerModel:GetGoldenMinerPartnerCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerPartner, type)
end
--endregion

--region Cfg - Hex
---@return XTableGoldenMinerHex
function XGoldenMinerModel:GetGoldenMinerHexCfg(hexId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerHex, hexId)
end
--endregion

--region Cfg - ShipShell

---@return XTableGoldenMinerShipShell
function XGoldenMinerModel:GetShipShellCfg(id)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.GoldenMinerShipShell, id)
    return cfg and cfg.ShellRawImage
end

--endregion

return XGoldenMinerModel