---@class XTempleConfigControl : XEntityControl
---@field private _Model XTempleModel
local XTempleConfigControl = XClass(XEntityControl, "XTempleConfigControl")

function XTempleConfigControl:GetGridIcon(gridId)
    return self._Model:GetGridIcon(gridId)
end

function XTempleConfigControl:GetGridName(gridId)
    return self._Model:GetGridName(gridId)
end

function XTempleConfigControl:GetGridFusionIcon(gridId)
    local fusion = self._Model:GetGridFusionIcon(gridId)
    return fusion
end

function XTempleConfigControl:GetGridFusionType(gridId)
    local fusion = self._Model:GetGridFusionType(gridId)
    return fusion
end

function XTempleConfigControl:GetTimeOfDayName(timeOfDay)
    return self._Model:GetTimeOfDayName(timeOfDay)
end

function XTempleConfigControl:GetTimeOfDayIconOn(timeOfDay)
    return self._Model:GetTimeOfDayIconOn(timeOfDay)
end

function XTempleConfigControl:GetTimeOfDayIconOff(timeOfDay)
    return self._Model:GetTimeOfDayIconOff(timeOfDay)
end

function XTempleConfigControl:GetRuleText(ruleType)
    return self._Model:GetRuleText(ruleType)
end

function XTempleConfigControl:GetAllBlocks()
    return self._Model:GetAllBlocks()
end

function XTempleConfigControl:GetBlockConfigById(blockId)
    return self._Model:GetBlockById(blockId)
end

function XTempleConfigControl:IsGridCanRotate(gridId)
    return self._Model:IsGridCanRotate(gridId)
end

function XTempleConfigControl:GetGridCommunityAmount()
    return self._Model:GetGridCommunityAmount()
end

function XTempleConfigControl:GetOptionRewardScore(time)
    return self._Model:GetOptionRewardScore(time)
end

function XTempleConfigControl:GetAllGrid()
    return self._Model:GetGrids()
end

return XTempleConfigControl
