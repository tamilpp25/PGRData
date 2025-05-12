---@class XGoldenMinerEntityBuff:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityBuff = XClass(XEntity, "XGoldenMinerEntityBuff")

--region Override
function XGoldenMinerEntityBuff:OnInit(buffId)
    self.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.CREATE
    self._BuffId = buffId
    -- Static Value
    self.CurTimeTypeParam = 0
    self._CurBeDieTime = 0
end

function XGoldenMinerEntityBuff:OnRelease()
end
--endregion

--region Getter
function XGoldenMinerEntityBuff:GetId()
    return self._BuffId
end

function XGoldenMinerEntityBuff:GetType()
    return self._OwnControl:GetControl():GetCfgBuffType(self:GetId())
end

function XGoldenMinerEntityBuff:GetBuffParams(index)
    local buffParams = self._OwnControl:GetControl():GetCfgBuffParams(self:GetId())
    if index then
        return buffParams[index]
    end
    return buffParams
end

function XGoldenMinerEntityBuff:GetTimeType()
    return self._OwnControl:GetControl():GetCfgBuffTimeType(self:GetId())
end

function XGoldenMinerEntityBuff:GetTimeTypeParam()
    return self._OwnControl:GetControl():GetCfgBuffTimeTypeParam(self:GetId())
end
--endregion

--region Setter
function XGoldenMinerEntityBuff:SetCurBeDieTime(value)
    self._CurBeDieTime = value
end
--endregion

--region Checker
---@param type number XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS
function XGoldenMinerEntityBuff:CheckType(type)
    return self:GetType() == type
end

---@param timeType number XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE
function XGoldenMinerEntityBuff:CheckTimeType(timeType)
    return self:GetTimeType() == timeType
end

function XGoldenMinerEntityBuff:CheckIsWillBeDie()
    return self._CurBeDieTime <= 0
end

function XGoldenMinerEntityBuff:IsCreate()
    return self.Status == XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.CREATE
end

function XGoldenMinerEntityBuff:IsAlive()
    return self.Status == XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.ALIVE
end
--endregion

--region Control
function XGoldenMinerEntityBuff:ChangeAlive()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.ALIVE
end

function XGoldenMinerEntityBuff:DownBeDieTime(deltaTime)
    if self:CheckIsWillBeDie() then
        return
    end
    self._CurBeDieTime = self._CurBeDieTime - deltaTime
end
--endregion

--region Debug
function XGoldenMinerEntityBuff:__DebugLog()
    return {
        BuffId = self:GetId(),
        BuffType = self:GetType(),
        BuffParams = self:GetBuffParams(),
        TimeType = self:GetTimeType(),
        TimeTypeParam = self:GetTimeTypeParam(),
        CurTimeTypeParam = self.CurTimeTypeParam,
        CurBeDieTime = self._CurBeDieTime,
    }
end
--endregion

return XGoldenMinerEntityBuff