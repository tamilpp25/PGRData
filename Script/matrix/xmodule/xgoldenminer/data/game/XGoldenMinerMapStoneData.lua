--地图抓取物数据
---@class XGoldenMinerMapStoneData
local XGoldenMinerMapStoneData = XClass(nil, "XGoldenMinerMapStoneData")

function XGoldenMinerMapStoneData:Ctor(stoneId)
    self._StoneId = stoneId
    self._MapIndex = 0
    self._XPosPercent = 0
    self._YPosPercent = 0
    self._RotationZ = 0
    self._Scale = 0
    self._IsUseOriginalScale = false
    ---@type XTableGoldenMinerStone
    self._Config = false
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

function XGoldenMinerMapStoneData:SetIsUseOriginalScale(value)
    self._IsUseOriginalScale = value
end

function XGoldenMinerMapStoneData:SetStoneConfig(config)
    self._Config = config
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

function XGoldenMinerMapStoneData:GetIsUseOriginalScale()
    return self._IsUseOriginalScale
end

function XGoldenMinerMapStoneData:GetType()
    return self._Config.Type
end

function XGoldenMinerMapStoneData:GetPrefab()
    return self._Config.Prefab
end

function XGoldenMinerMapStoneData:GetScore()
    return self._Config.Score
end

function XGoldenMinerMapStoneData:GetStartMoveDirection()
    return self._Config.StartMoveDirection
end

function XGoldenMinerMapStoneData:GetMoveType()
    return self._Config.MoveType
end

function XGoldenMinerMapStoneData:GetMoveRange()
    return self._Config.MoveRange
end

function XGoldenMinerMapStoneData:GetMoveSpeed()
    return self._Config.MoveSpeed
end

function XGoldenMinerMapStoneData:GetBornDelay()
    return self._Config.BornDelay
end

function XGoldenMinerMapStoneData:GetDestroyTime()
    return self._Config.DestoryTime
end

function XGoldenMinerMapStoneData:GetWeight()
    return self._Config.Weight
end

function XGoldenMinerMapStoneData:GetCarryStoneId()
    return self._Config.CarryStoneId
end

function XGoldenMinerMapStoneData:GetCatchEffect()
    return self._Config.CatchEffect
end

function XGoldenMinerMapStoneData:GetInitialType()
    return self._Config.InitialType
end

function XGoldenMinerMapStoneData:_GetInitParams()
    return self._Config.IntParams
end

function XGoldenMinerMapStoneData:_GetFloatParams()
    return self._Config.FloatParams
end
--endregion

--region RedEnvelope
function XGoldenMinerMapStoneData:GetRedEnvelopeGroup()
    return self:_GetInitParams(self._StoneId)[1]
end
--endregion

--region AddTimeStone
function XGoldenMinerMapStoneData:GetAddTimeStoneAddTime()
    return self:_GetFloatParams(self._StoneId)[1]
end
--endregion

--region ItemStone
function XGoldenMinerMapStoneData:GetItemStoneItemId()
    return self:_GetInitParams(self._StoneId)[1]
end
--endregion

--region HookDirectionPoint
---@return number[]
function XGoldenMinerMapStoneData:GetHookDirectionPointAngleList()
    return self:_GetInitParams(self._StoneId)
end

---@return number[]
function XGoldenMinerMapStoneData:GetHookDirectionPointTimeList()
    return self:_GetFloatParams(self._StoneId)
end
--endregion

--region AimDirection
---@return number
function XGoldenMinerMapStoneData:GetAimDirectionTargetStoneId()
    return self:_GetInitParams(self._StoneId)[1]
end
--endregion

--region Mussel
---@return boolean
function XGoldenMinerMapStoneData:GetMusselIsGrabbed()
    return not XTool.IsNumberValid(self:GetCarryStoneId())
end

---@return boolean
function XGoldenMinerMapStoneData:GetMusselInitIsOpen()
    return XTool.IsNumberValid(self:_GetInitParams(self._StoneId)[1])
end

function XGoldenMinerMapStoneData:GetMusselOpenTime()
    return self:_GetFloatParams(self._StoneId)[1]
end

function XGoldenMinerMapStoneData:GetMusselHideTime()
    return self:_GetFloatParams(self._StoneId)[2]
end
--endregion

--region QTE
function XGoldenMinerMapStoneData:GetQTETime()
    return self:_GetFloatParams(self._StoneId)[1]
end

function XGoldenMinerMapStoneData:GetQTEGroupId()
    return self:_GetInitParams(self._StoneId)[1]
end
--endregion

--region Checker
function XGoldenMinerMapStoneData:CheckType(stoneType)
    return self:GetType() == stoneType
end

function XGoldenMinerMapStoneData:IsHaveCarryStone()
    return XTool.IsNumberValid(self:GetCarryStoneId())
end

function XGoldenMinerMapStoneData:IsHaveQTE()
    return self:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.QTE) 
            and XTool.IsNumberValid(self:GetQTEGroupId())
            and XTool.IsNumberValid(self:GetQTETime())
end

function XGoldenMinerMapStoneData:IsHaveMussel()
    return self:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MUSSEL)
            and XTool.IsNumberValid(self:GetMusselHideTime())
            and XTool.IsNumberValid(self:GetMusselOpenTime())
end

function XGoldenMinerMapStoneData:IsHaveDirectionPoint()
    return self:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.HOOK_DIRECTION_POINT)
            and not XTool.IsTableEmpty(self:GetHookDirectionPointAngleList())
            and not XTool.IsTableEmpty(self:GetHookDirectionPointTimeList())
end

function XGoldenMinerMapStoneData:IsBoomDestroy()
    return XTool.IsNumberValid(self._Config.IsBoomDestroy)
end

function XGoldenMinerMapStoneData:IsSunOrMoonStone()
    return self._Config.InitialType == XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_TYPE.SUN
            or self._Config.InitialType == XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_TYPE.MOON
end
--endregion

return XGoldenMinerMapStoneData