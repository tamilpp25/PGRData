---@class XFightLilithGachaModel : XModel
local XFightLilithGachaModel = XClass(XModel, "XFightLilithGachaModel")

local TableKey = {
    UiFightLilithGacha = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XFightLilithGachaModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fight", TableKey)
    self.GroupIdToIdList = {}
end

function XFightLilithGachaModel:ClearPrivate()
end

function XFightLilithGachaModel:ResetAll()
end

function XFightLilithGachaModel:GetIdList(groupId)
    if XTool.IsTableEmpty(self.GroupIdToIdList) then
        for id, cfg in pairs(self._ConfigUtil:GetByTableKey(TableKey.UiFightLilithGacha)) do
            if not self.GroupIdToIdList[cfg.GroupId] then
                self.GroupIdToIdList[cfg.GroupId] = {}
            end
            table.insert(self.GroupIdToIdList[cfg.GroupId], id)
        end
    end
    
    return self.GroupIdToIdList[groupId]
end

function XFightLilithGachaModel:GetGachaIcon(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.UiFightLilithGacha, id)
    return config and config.GachaIcon
end

function XFightLilithGachaModel:GetGapuLeftIcon(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.UiFightLilithGacha, id)
    return config and config.GapuLeftIcon
end

function XFightLilithGachaModel:GetGapuRightIcon(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.UiFightLilithGacha, id)
    return config and config.GapuRightIcon
end

function XFightLilithGachaModel:GetIntervalTime(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.UiFightLilithGacha, id)
    return config and config.IntervalTime
end

return XFightLilithGachaModel