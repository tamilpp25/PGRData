---@class XBagOrganizeActivityModel : XModel
local XBagOrganizeActivityModel = XClass(XModel, "XBagOrganizeActivityModel")

local TableNormal = {
    BagOrganizeClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    BagOrganizeStage = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeActivity = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeChapter =  { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
}

local TablePrivate = {
    BagOrganizeGoods = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeBags = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeStageBaseRuleSet = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeScoreGrade = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "StageId", ReadFunc = XConfigUtil.ReadType.Int },

    BagOrganizeGoodsRule = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeGoodsGroup = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },

    BagOrganizeEvent = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeEventResult = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },
    BagOrganizeEventRule = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id", ReadFunc = XConfigUtil.ReadType.Int },

}

function XBagOrganizeActivityModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/BagOrganize', TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/BagOrganize', TablePrivate, XConfigUtil.CacheType.Private)

    self._StageDatas = nil
    self._ActivityId = nil
    
    ---@type XBagOrganizeActivityReddotData
    self.ReddotData = require('XModule/XBagOrganizeActivity/Entity/XBagOrganizeActivityReddotData').New()
end

function XBagOrganizeActivityModel:ClearPrivate()
    self:SetCurStageId(nil)
end

function XBagOrganizeActivityModel:ResetAll()
    self._StageDatas = nil
    self._ActivityId = nil
end

function XBagOrganizeActivityModel:ClearOnGameControlRelease()
    self._TurnId = nil
    self._StartTime = nil
end

function XBagOrganizeActivityModel:SetCurStageId(stageId)
    self._StageId = stageId
end

function XBagOrganizeActivityModel:GetCurStageId()
    return self._StageId or 0
end

--region -------------------- ActivityData -------------------->>
function XBagOrganizeActivityModel:UpdateActivityId(activityId)
    self._ActivityId = XTool.IsNumberValid(activityId) and activityId or 0

    if XTool.IsNumberValid(self._ActivityId) then
        self.ReddotData:UpdateUniqueKeyByActivityId(self._ActivityId)
    end
end

function XBagOrganizeActivityModel:UpdateStageRecords(stageDatas)
    self._StageDatas = stageDatas or {}
end

function XBagOrganizeActivityModel:UpdateCurStageTurnId(turnId)
    self._TurnId = turnId
end

function XBagOrganizeActivityModel:UpdateCurStageStartTime(startTime)
    self._StartTime = startTime
end

function XBagOrganizeActivityModel:GetCurActivityId()
    return self._ActivityId or 0
end

function XBagOrganizeActivityModel:GetStageRecordById(stageId)
    if not XTool.IsTableEmpty(self._StageDatas) then
        for i, v in ipairs(self._StageDatas) do
            if v.StageId == stageId then
                return v
            end
        end
    end
    
    return nil
end

function XBagOrganizeActivityModel:GetCurStageTurnId()
    return self._TurnId or 0
end

function XBagOrganizeActivityModel:GetCurStageStartTime()
    return self._StartTime or 0
end
--endregion <<--------------------------------------------------

function XBagOrganizeActivityModel:GetStageMapPath(mapId, fullPath)
    if fullPath then
        return CS.UnityEngine.Application.dataPath .. "../../../../Product/Table/" .. self:GetStageMapPath(mapId)
    end
    local path = "Client/MiniActivity/BagOrganize/Maps/BagOrganizeMap" .. tostring(mapId) .. ".tab"
    return path
end

--region -------------------- Configs ------------------->>

function XBagOrganizeActivityModel:GetClientConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.BagOrganizeClientConfig)
end

function XBagOrganizeActivityModel:GetBagOrganizeStageConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.BagOrganizeStage)
end

function XBagOrganizeActivityModel:GetBagOrganizeStageCfgById(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.BagOrganizeStage, stageId)
end

function XBagOrganizeActivityModel:GetBagOrganizeActivityConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.BagOrganizeActivity)
end

function XBagOrganizeActivityModel:GetBagOrganizeChapterConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.BagOrganizeChapter)
end

function XBagOrganizeActivityModel:GetBagOrganizeGoodsConfig()
    return self._ConfigUtil:GetByTableKey(TablePrivate.BagOrganizeGoods)
end

function XBagOrganizeActivityModel:GetBagOrganizeBagsCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.BagOrganizeBags)
end

function XBagOrganizeActivityModel:GetBagOrganizeBagCfgById(mapId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeBags, mapId)
end

function XBagOrganizeActivityModel:GetBagOrganizeScoreGradeCfgById(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeScoreGrade, stageId)
end

function XBagOrganizeActivityModel:GetBagOrganizeGoodsRuleCfgById(goodsRuleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeGoodsRule, goodsRuleId)
end

function XBagOrganizeActivityModel:GetBagOrganizeGoodsGroupCfgById(goodsGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeGoodsGroup, goodsGroupId)
end

function XBagOrganizeActivityModel:GetClientConfigVector2(key)
    local config = self:GetClientConfig()[key]
    if config then
        local _x = string.IsNumeric(config.Values[1]) and tonumber(config.Values[1]) or 0
        local _y = string.IsNumeric(config.Values[2]) and tonumber(config.Values[2]) or 0
        
        return { x = _x, y = _y }
    end
    return {0, 0}
end

function XBagOrganizeActivityModel:GetClientConfigNum(key, index)
    index = index or 1

    local config = self:GetClientConfig()[key]
    if config and config.Values[index] then
        local val = string.IsFloatNumber(config.Values[index]) and tonumber(config.Values[index]) or 0
        return val
    end
    
    return 0
end

function XBagOrganizeActivityModel:GetClientConfigText(key, index)
    index = index or 1

    local config = self:GetClientConfig()[key]
    if config then
        return config.Values[index] or ''
    end

    return ''
end

function XBagOrganizeActivityModel:GetBagOrganizeStageBaseRuleSet()
    return self._ConfigUtil:GetByTableKey(TablePrivate.BagOrganizeStageBaseRuleSet)
end

function XBagOrganizeActivityModel:GetIsSameColroComboEnabledByStageId(stageId)
    local cfg = self:GetBagOrganizeStageBaseRuleSet()[stageId]
    if cfg then
        return cfg.IsSameColroComboEnabled
    end
    return false
end

function XBagOrganizeActivityModel:GetIsMultyBagEnabledByStageId(stageId)
    local cfg = self:GetBagOrganizeStageBaseRuleSet()[stageId]
    if cfg then
        return cfg.IsMultyBagEnabled
    end
    return false
end

function XBagOrganizeActivityModel:GetIsTimelimitEnabledByStageId(stageId)
    local cfg = self:GetBagOrganizeStageBaseRuleSet()[stageId]
    if cfg then
        return cfg.IsTimelimitEnabled
    end
    return false
end

function XBagOrganizeActivityModel:GetSingleMapConfigById(stageId)
    local cfg = self:GetBagOrganizeStageCfgById(stageId)

    if cfg and cfg.MapIds then
        local mapId = cfg.MapIds[1]

        return self:GetMapConfigById(mapId), mapId
    end
end

function XBagOrganizeActivityModel:GetMapConfigById(mapId)
    if XTool.IsNumberValid(mapId) then
        local path = self:GetStageMapPath(mapId)

        if not self._ConfigUtil:HasArgs(path) then
            self._ConfigUtil:InitConfig({
                [path] = { XConfigUtil.ReadType.Int, XTable.XTableBagOrganizeMap, "Id", XConfigUtil.CacheType.Private },
            })
        end
        local configs = self._ConfigUtil:Get(path)
        if not configs then
            XLog.Debug("[XBagOrganizeActivityModel] 文件尚不存在:", mapId)
            return
        end
        return configs
    end
end

function XBagOrganizeActivityModel:GetBagOrganizeEventRuleCfgById(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeEventRule, id, noTips)
end

function XBagOrganizeActivityModel:GetBagOrganizeEventCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeEvent, id)
end

function XBagOrganizeActivityModel:GetBagOrganizeEventResultCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.BagOrganizeEventResult, id)
end
--endregion <<--------------------------------------------

--region Editor
function XBagOrganizeActivityModel:ClearBagOrganizeBagsCfgs()
    self._ConfigUtil:Clear(self._ConfigUtil:GetPathByTableKey(TablePrivate.BagOrganizeBags))
end

--endregion

return XBagOrganizeActivityModel