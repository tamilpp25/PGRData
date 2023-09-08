---@class XTheatre3EquipDescData
---@field PassFightCount number
---@field PassBossFightCount number

---@class XTheatre3EquipSuitDescData
---@field PassFightCount number
---@field PassBossFightCount number

---@class XTheatre3ItemDescData
---@field PassFightCount number
---@field PassBossFightCount number

---@class XTheatre3AdventureEffectDescData
local XTheatre3AdventureEffectDescData = XClass(nil, "XTheatre3AdventureEffectDescData")

function XTheatre3AdventureEffectDescData:Ctor()
    self._ItemBuyCount = 0
    self._TotalRecvCoin = 0
    ---@type XTheatre3EquipDescData[]
    self._EquipDataDir = {}
    ---@type XTheatre3EquipSuitDescData[]
    self._SuitDataDir = {}
    ---@type XTheatre3ItemDescData[]
    self._ItemDataDir = {}
end

function XTheatre3AdventureEffectDescData:UpdateData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self._ItemBuyCount = data.CurBuyCount
    self._TotalRecvCoin = data.TotalRecvCoin
    if not XTool.IsTableEmpty(data.Equip) then
        self._EquipDataDir[data.Equip.EquipId] = self._EquipDataDir[data.Equip.EquipId] or {}
        self._EquipDataDir[data.Equip.EquipId].PassFightCount = data.Equip.PassFightCount
        self._EquipDataDir[data.Equip.EquipId].PassBossFightCount = data.Equip.PassBossFightCount
    end
    if not XTool.IsTableEmpty(data.EquipSuit) then
        self._SuitDataDir[data.EquipSuit.SuitId] = self._SuitDataDir[data.EquipSuit.SuitId] or {}
        self._SuitDataDir[data.EquipSuit.SuitId].PassFightCount = data.EquipSuit.PassFightCount
        self._SuitDataDir[data.EquipSuit.SuitId].PassBossFightCount = data.EquipSuit.PassBossFightCount
    end
    if not XTool.IsTableEmpty(data.Item) then
        self._ItemDataDir[data.Item.ItemId] = self._ItemDataDir[data.Item.ItemId] or {}
        self._ItemDataDir[data.Item.ItemId].PassFightCount = data.Item.PassFightCount
        self._ItemDataDir[data.Item.ItemId].PassBossFightCount = data.Item.PassBossFightCount
    end
end

--region Getter
function XTheatre3AdventureEffectDescData:GetItemBuyCount()
    return self._ItemBuyCount
end

function XTheatre3AdventureEffectDescData:GetTotalRecvCoin()
    return self._TotalRecvCoin
end

function XTheatre3AdventureEffectDescData:GetEquipPassFightCount(equipId)
    if XTool.IsTableEmpty(self._EquipDataDir[equipId]) then
        return 0
    end
    return self._EquipDataDir[equipId].PassFightCount
end

function XTheatre3AdventureEffectDescData:GetEquipPassBossFightCount(equipId)
    if XTool.IsTableEmpty(self._EquipDataDir[equipId]) then
        return 0
    end
    return self._EquipDataDir[equipId].PassBossFightCount
end

function XTheatre3AdventureEffectDescData:GetEquipPassNodeCount(equipId)
    if XTool.IsTableEmpty(self._EquipDataDir[equipId]) then
        return 0
    end
    return self._EquipDataDir[equipId].PassFightCount + self._EquipDataDir[equipId].PassBossFightCount
end

function XTheatre3AdventureEffectDescData:GetSuitPassFightCount(suitId)
    if XTool.IsTableEmpty(self._SuitDataDir[suitId]) then
        return 0
    end
    return self._SuitDataDir[suitId].PassFightCount
end

function XTheatre3AdventureEffectDescData:GetSuitPassBossFightCount(suitId)
    if XTool.IsTableEmpty(self._SuitDataDir[equipId]) then
        return 0
    end
    return self._SuitDataDir[suitId].PassBossFightCount
end

function XTheatre3AdventureEffectDescData:GetSuitPassNodeCount(suitId)
    if XTool.IsTableEmpty(self._SuitDataDir[suitId]) then
        return 0
    end
    return self._SuitDataDir[suitId].PassFightCount + self._SuitDataDir[suitId].PassBossFightCount
end
--endregion

--region Checker
function XTheatre3AdventureEffectDescData:CheckHasEquipData(equipId)
    return not XTool.IsTableEmpty(self._EquipDataDir[equipId])
end

function XTheatre3AdventureEffectDescData:CheckHasSuitData(suitId)
    return not XTool.IsTableEmpty(self._SuitDataDir[suitId])
end
--endregion

return XTheatre3AdventureEffectDescData