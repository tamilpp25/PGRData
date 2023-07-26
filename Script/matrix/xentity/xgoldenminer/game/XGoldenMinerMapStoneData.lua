--地图抓取物数据
---@class XGoldenMinerMapStoneData
local XGoldenMinerMapStoneData = XClass(nil, "XGoldenMinerMapStoneData")

local Default = {
    _StoneId = 0,
    _MapIndex = 0,
}

function XGoldenMinerMapStoneData:Ctor(stoneId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._StoneId = stoneId
end

--region Setter
function XGoldenMinerMapStoneData:SetMapIndex(mapIndex)
    self._MapIndex = mapIndex
end

function XGoldenMinerMapStoneData:SetXPosPercent(XPosPercent)
    self._XPosPercent = XPosPercent
end

function XGoldenMinerMapStoneData:SetYPosPercent(YPosPercent)
    self._YPosPercent = YPosPercent
end

function XGoldenMinerMapStoneData:SetRotationZ(rotationZ)
    self._RotationZ = rotationZ
end

function XGoldenMinerMapStoneData:SetScale(scale)
    self._Scale = scale
end
--endregion

--region Getter
function XGoldenMinerMapStoneData:GetId()
    return self._StoneId
end

function XGoldenMinerMapStoneData:GetMapIndex()
    return self._MapIndex
end

function XGoldenMinerMapStoneData:GetXPosPercent()
    return self._XPosPercent
end

function XGoldenMinerMapStoneData:GetYPosPercent()
    return self._YPosPercent
end

function XGoldenMinerMapStoneData:GetRotationZ()
    return self._RotationZ
end

function XGoldenMinerMapStoneData:GetScale()
    return self._Scale
end

function XGoldenMinerMapStoneData:GetType()
    return XGoldenMinerConfigs.GetStoneType(self._StoneId)
end

function XGoldenMinerMapStoneData:GetPrefab()
    return XGoldenMinerConfigs.GetStonePrefab(self._StoneId)
end

function XGoldenMinerMapStoneData:GetScore()
    return XGoldenMinerConfigs.GetStoneScore(self._StoneId)
end

function XGoldenMinerMapStoneData:GetStartMoveDirection()
    return XGoldenMinerConfigs.GetStoneStartMoveDirection(self._StoneId)
end

function XGoldenMinerMapStoneData:GetMoveType()
    return XGoldenMinerConfigs.GetStoneMoveType(self._StoneId)
end

function XGoldenMinerMapStoneData:GetMoveRange()
    return XGoldenMinerConfigs.GetStoneMoveRange(self._StoneId)
end

function XGoldenMinerMapStoneData:GetMoveSpeed()
    return XGoldenMinerConfigs.GetStoneMoveSpeed(self._StoneId)
end

function XGoldenMinerMapStoneData:GetBornDelay()
    return XGoldenMinerConfigs.GetStoneBornDelay(self._StoneId)
end

function XGoldenMinerMapStoneData:GetDestroyTime()
    return XGoldenMinerConfigs.GetStoneDestroyTime(self._StoneId)
end

function XGoldenMinerMapStoneData:GetWeight()
    return XGoldenMinerConfigs.GetStoneWeight(self._StoneId)
end

function XGoldenMinerMapStoneData:GetCarryStoneId()
    return XGoldenMinerConfigs.GetStoneCarryStoneId(self._StoneId)
end

function XGoldenMinerMapStoneData:GetCatchEffect()
    return XGoldenMinerConfigs.GetStoneCatchEffect(self._StoneId)
end
--endregion

--region RedEnvelope
function XGoldenMinerMapStoneData:GetRedEnvelopeGroup()
    return XGoldenMinerConfigs.GetStoneIntParams(self._StoneId)[1]
end
--endregion

--region AddTimeStone
function XGoldenMinerMapStoneData:GetAddTimeStoneAddTime()
    return XGoldenMinerConfigs.GetStoneFloatParams(self._StoneId)[1]
end
--endregion

--region ItemStone
function XGoldenMinerMapStoneData:GetItemStoneItemId()
    return XGoldenMinerConfigs.GetStoneIntParams(self._StoneId)[1]
end
--endregion

--region HookDirectionPoint
---@return number[]
function XGoldenMinerMapStoneData:GetHookDirectionPointAngleList()
    return XGoldenMinerConfigs.GetStoneIntParams(self._StoneId)
end

---@return number[]
function XGoldenMinerMapStoneData:GetHookDirectionPointTimeList()
    return XGoldenMinerConfigs.GetStoneFloatParams(self._StoneId)
end
--endregion

--region Mussel
---@return boolean
function XGoldenMinerMapStoneData:GetMusselIsGrabbed()
    return not XTool.IsNumberValid(self:GetCarryStoneId())
end

---@return boolean
function XGoldenMinerMapStoneData:GetMusselInitIsOpen()
    return XTool.IsNumberValid(XGoldenMinerConfigs.GetStoneIntParams(self._StoneId)[1])
end

function XGoldenMinerMapStoneData:GetMusselOpenTime()
    return XGoldenMinerConfigs.GetStoneFloatParams(self._StoneId)[1]
end

function XGoldenMinerMapStoneData:GetMusselHideTime()
    return XGoldenMinerConfigs.GetStoneFloatParams(self._StoneId)[2]
end
--endregion

--region QTE
function XGoldenMinerMapStoneData:GetQTETime()
    return XGoldenMinerConfigs.GetStoneFloatParams(self._StoneId)[1]
end

function XGoldenMinerMapStoneData:GetQTEGroupId()
    return XGoldenMinerConfigs.GetStoneIntParams(self._StoneId)[1]
end
--endregion

--region Checker
function XGoldenMinerMapStoneData:IsHaveCarryStone()
    return XTool.IsNumberValid(self:GetCarryStoneId())
end

function XGoldenMinerMapStoneData:IsHaveQTE()
    return self:GetType() == XGoldenMinerConfigs.StoneType.QTE
            and XTool.IsNumberValid(self:GetQTEGroupId())
            and XTool.IsNumberValid(self:GetQTETime())
end

function XGoldenMinerMapStoneData:IsHaveMussel()
    return self:GetType() == XGoldenMinerConfigs.StoneType.Mussel
            and XTool.IsNumberValid(self:GetMusselHideTime())
            and XTool.IsNumberValid(self:GetMusselOpenTime())
end

function XGoldenMinerMapStoneData:IsHaveDirectionPoint()
    return self:GetType() == XGoldenMinerConfigs.StoneType.HookDirectionPoint
            and not XTool.IsTableEmpty(self:GetHookDirectionPointAngleList())
            and not XTool.IsTableEmpty(self:GetHookDirectionPointTimeList())
end

function XGoldenMinerMapStoneData:IsBoomDestroy()
    return XGoldenMinerConfigs.GetStoneIsBoomDestroy(self._StoneId)
end
--endregion

return XGoldenMinerMapStoneData