---行星环游记天赋配置
XPlanetTalentConfigs = XPlanetTalentConfigs or {}
local XPlanetTalentConfigs = XPlanetTalentConfigs

XPlanetTalentConfigs.TalentCardFilter = {
    All = 1,    -- 全部
    Build = 2,  -- 建筑型
    Floor = 3,  -- 地板型
}

---@type XConfig
local _ConfigTalentBuilding

function XPlanetTalentConfigs.Init()
    _ConfigTalentBuilding = XConfig.New("Share/PlanetRunning/PlanetRunningTalentBuilding.tab", XTable.XTablePlanetRunningTalentBuilding)
end


function XPlanetTalentConfigs.GetFilterName(talentCardFilter)
    if talentCardFilter == XPlanetTalentConfigs.TalentCardFilter.All then
        return "全部"
    elseif talentCardFilter == XPlanetTalentConfigs.TalentCardFilter.Build then
        return "建筑"
    elseif talentCardFilter == XPlanetTalentConfigs.TalentCardFilter.Floor then
        return "地板"
    end
end

--#region _ConfigTalentBuilding 天赋建筑
function XPlanetTalentConfigs.GetTalentBuildingConfigs()
    return _ConfigTalentBuilding:GetConfigs()
end

---@return string
function XPlanetTalentConfigs.GetTalentBuildingName(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "Name")
end

---天赋建筑描述
---@return number
function XPlanetTalentConfigs.GetTalentBuildingDesc(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "Desc")
end

---天赋建筑排序优先级
---@return number
function XPlanetTalentConfigs.GetTalentBuildingSorting(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "Sorting")
end

---天赋建筑解锁前置关卡Id
---@return number
function XPlanetTalentConfigs.GetTalentBuildingUnlockStageId(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "UnlockStageId")
end

---天赋建筑消耗货币数量
---@return number
function XPlanetTalentConfigs.GetTalentBuildingBuyPrices(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "BuyPrices")
end

---天赋建筑默认最大持有数量
---@return number
function XPlanetTalentConfigs.GetTalentBuildingHoldingCount(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "HoldingCount")
end

---天赋建筑触发事件
---@return number[]
function XPlanetTalentConfigs.GetTalentBuildingEventList(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "Events")
end

---天赋建筑默认地板材质id
---@return number
function XPlanetTalentConfigs.GetTalentBuildingDefaultFloorId(talentBuildingId)
    local floorIdList = _ConfigTalentBuilding:GetProperty(talentBuildingId, "CanUseFloorId")
    return floorIdList[1] or 1
end

---天赋建筑可用地板材质是否包含id
---@return number
function XPlanetTalentConfigs.CheckTalentBuildingCanUseFloor(talentBuildingId, tagetFloorId)
    local floorIdList = XPlanetTalentConfigs.GetTalentBuildingCanUseFloorId(talentBuildingId)
    for _, floorId in ipairs(floorIdList) do
        if floorId == tagetFloorId then
            return true
        end
    end
    return false
end

---@return number
function XPlanetTalentConfigs.GetTalentBuildingCanUseFloorId(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "CanUseFloorId")
end

---天赋建筑解锁最大持有数量的关卡序列
---@return number
function XPlanetTalentConfigs.GetTalentBuildingUnlockCountStageIds(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "UnlockCountStageIds")
end

---@return number
function XPlanetTalentConfigs.GetTalentBuildingUnlockCounts(talentBuildingId)
    return _ConfigTalentBuilding:GetProperty(talentBuildingId, "UnlockCounts")
end

---是否以卡片形式在家园模式展示
---@return boolean
function XPlanetTalentConfigs.GetTalentBuildingIsCard(talentBuildingId)
    return XTool.IsNumberValid(_ConfigTalentBuilding:GetProperty(talentBuildingId, "IsCard"))
end
--#endregion