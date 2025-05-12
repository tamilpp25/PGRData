--抓取的黄金类的道具信息
---@class XGoldenMinerGrabDataInfo
local XGoldenMinerGrabDataInfo = XClass(nil, "XGoldenMinerGrabDataInfo")

function XGoldenMinerGrabDataInfo:Ctor(itemId)
    self._ItemId = itemId
    self._Scores = 0            --抓取物积分
    self._Count = 0             --抓到的数量
    self._AdditionalItem = {}   --附加道具id
    self._Status = XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_TYPE.NORMAL -- 抓取物的日月状态 2.17
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerGrabDataInfo:AddDataByStoneEntity(stoneEntity)
    local stoneComponent = stoneEntity:GetComponentStone()
    local carryStone = stoneEntity:GetCarryStoneEntity()
    self._Count = self._Count + 1
    self._Scores = self._Scores + stoneComponent.CurScore

    local goldenMinerItemId
    if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE) then
        goldenMinerItemId = stoneComponent.Score
    end
    if carryStone and carryStone.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE) then
        goldenMinerItemId = carryStone:GetComponentStone().Score
    end
    if XTool.IsNumberValid(goldenMinerItemId) then
        table.insert(self._AdditionalItem, goldenMinerItemId)
    end

    ---@type XGoldenMinerComponentSunMoon
    local componentSunMoon = stoneEntity:GetComponentSunMoon()
    if componentSunMoon then
        self._Status = componentSunMoon.SunMoonType
    end
end

function XGoldenMinerGrabDataInfo:GetItemId()
    return self._ItemId
end

function XGoldenMinerGrabDataInfo:GetScores()
    return math.floor(self._Scores)
end

function XGoldenMinerGrabDataInfo:GetCount()
    return self._Count
end

function XGoldenMinerGrabDataInfo:GetAdditionalItem()
    return self._AdditionalItem
end

function XGoldenMinerGrabDataInfo:GetStatus()
    return self._Status
end

return XGoldenMinerGrabDataInfo