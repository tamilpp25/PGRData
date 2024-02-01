local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local TIME_OF_DAY = XTempleEnumConst.TIME_OF_DAY

---@field _OwnControl XTempleGameControl
---@class XTempleTimeOfDay:XEntity
local XTempleTimeOfDay = XClass(XEntity, "XTempleTimeOfDay")

function XTempleTimeOfDay:Ctor()
    self._Type = TIME_OF_DAY.MORNING
    self._Duration = 0
    self._BinCode = 1 << (self._Type - 1)
end

function XTempleTimeOfDay:SetType(type)
    self._Type = type
    self._BinCode = 1 << (self._Type - 1)
end

function XTempleTimeOfDay:SetDuration(value)
    self._Duration = value
end

function XTempleTimeOfDay:IsOverThisTime(spendTime)
    if spendTime >= self._Duration then
        return true
    end
    return false
end

function XTempleTimeOfDay:GetType()
    return self._Type
end

function XTempleTimeOfDay:IsTimeActive(time)
    return time & self._BinCode ~= 0
end

function XTempleTimeOfDay:GetName()
    return self._OwnControl:GetTimeOfDayName(self._Type)
end

function XTempleTimeOfDay:GetIconOn()
    return self._OwnControl:GetTimeOfDayIconOn(self._Type)
end

function XTempleTimeOfDay:GetIconOff()
    return self._OwnControl:GetTimeOfDayIconOff(self._Type)
end

function XTempleTimeOfDay:GetDuration()
    return self._Duration
end

function XTempleTimeOfDay:GetBinCode()
    return self._BinCode
end

return XTempleTimeOfDay
