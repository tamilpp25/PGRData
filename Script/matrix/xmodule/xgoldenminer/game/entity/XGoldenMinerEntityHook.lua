---@class XGoldenMinerEntityHook:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityHook = XClass(XEntity, "XGoldenMinerEntityHook")

--region Override
function XGoldenMinerEntityHook:OnInit()
    ---@type number[]
    self._HookGrabbedStoneUidList = {}
    ---@type number[]
    self._HookGrabbingStoneUidList = {}
    ---@type number[]
    self._HookHitStoneUidList = {}
    ---@type number[]
    self._ShipGrabbedStoneUidList = {} -- 飞船撞到的抓取物
end

function XGoldenMinerEntityHook:OnRelease()
    self._HookGrabbedStoneUidList = nil
    self._HookGrabbingStoneUidList = nil
    self._HookHitStoneUidList = nil
    self._ShipGrabbedStoneUidList = nil
end
--endregion

--region Getter
---@return XGoldenMinerComponentHook
function XGoldenMinerEntityHook:GetComponentHook()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.HOOK)
end

---@return XGoldenMinerComponentTimeLineAnim
function XGoldenMinerEntityHook:GetComponentAnim()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.TIME_LINE)
end

function XGoldenMinerEntityHook:GetHitStoneUidList()
    return self._HookHitStoneUidList
end

function XGoldenMinerEntityHook:GetGrabbingStoneUidList()
    return self._HookGrabbingStoneUidList
end

function XGoldenMinerEntityHook:GetGrabbedStoneUidList()
    return self._HookGrabbedStoneUidList
end

function XGoldenMinerEntityHook:GetShipGrabbedStoneUidList()
    return self._ShipGrabbedStoneUidList
end
--endregion

--region Control
function XGoldenMinerEntityHook:AddHitStone(uid)
    self._HookHitStoneUidList[#self._HookHitStoneUidList + 1] = uid
end

function XGoldenMinerEntityHook:AddGrabbingStone(uid)
    self._HookGrabbingStoneUidList[#self._HookGrabbingStoneUidList + 1] = uid
end

function XGoldenMinerEntityHook:AddGrabbedStone(uid)
    self._HookGrabbedStoneUidList[#self._HookGrabbedStoneUidList + 1] = uid
end

function XGoldenMinerEntityHook:AddShipGrabbedStone(uid)
    self._ShipGrabbedStoneUidList[#self._ShipGrabbedStoneUidList + 1] = uid
end

function XGoldenMinerEntityHook:ClearHitStone()
    self._HookHitStoneUidList = {}
end

function XGoldenMinerEntityHook:ClearGrabbingStone()
    self._HookGrabbingStoneUidList = {}
end

function XGoldenMinerEntityHook:ClearGrabbedStone()
    self._HookGrabbedStoneUidList = {}
end

function XGoldenMinerEntityHook:ClearShipGrabbedStone()
    self._ShipGrabbedStoneUidList = {}
end
--endregion

return XGoldenMinerEntityHook