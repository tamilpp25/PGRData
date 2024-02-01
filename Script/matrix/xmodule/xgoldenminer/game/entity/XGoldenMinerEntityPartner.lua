---@class XGoldenMinerEntityPartner:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityPartner = XClass(XEntity, "XGoldenMinerEntityPartner")

--region Override
function XGoldenMinerEntityPartner:OnInit()
    self._Status = XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.NONE
    self._GrabStoneList = {}
end

function XGoldenMinerEntityPartner:OnRelease()
    self._GrabStoneList = nil
end
--endregion

--region Getter
---@return XGoldenMinerComponentPartnerShip
function XGoldenMinerEntityPartner:GetComponentPartnerShip()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.PARTNER_SHIP)
end

---@return XGoldenMinerComponentScanLine
function XGoldenMinerEntityPartner:GetComponentScanLine()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.PARTNER_SCAN)
end

function XGoldenMinerEntityPartner:GetGrabStoneUidList()
    return self._GrabStoneList
end
--endregion

--region Setter
---@param status number XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS
function XGoldenMinerEntityPartner:SetStatus(status)
    self._Status = status
end

---@param entity XGoldenMinerEntityStone
function XGoldenMinerEntityPartner:AddGrabStoneList(entity)
    self._GrabStoneList[#self._GrabStoneList + 1] = entity:GetUid()
end
--endregion

--region Check
function XGoldenMinerEntityPartner:CheckStatus(status)
    return self._Status == status
end
--endregion

return XGoldenMinerEntityPartner