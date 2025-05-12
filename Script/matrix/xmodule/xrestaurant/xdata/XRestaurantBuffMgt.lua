local XRestaurantData = require("XModule/XRestaurant/XData/XRestaurantData")

---@class XRestaurantBuffData : XRestaurantData buff数据
---@field
local  XRestaurantBuffData = XClass(XRestaurantData, " XRestaurantBuff")

local Properties = {
    BuffId = "BuffId",
    AreaType = "AreaType",
    IsUnlock = "IsUnlock",
    IsDefault = "IsDefault"
}

function XRestaurantBuffData:InitData(buffId)
    self.Data = {
        BuffId = buffId,
        AreaType = XMVCA.XRestaurant.AreaType.None,
        IsUnlock = false,
        IsDefault = false
    }
end

function XRestaurantBuffData:UpdateData(buffId, areaType)
    self:SetProperty(Properties.BuffId, buffId)
    self:UpdateAreaType(areaType)
    self:UpdateUnlock(true)
end

function XRestaurantBuffData:UpdateAreaType(areaType)
    self:SetProperty(Properties.AreaType, areaType)
end

function XRestaurantBuffData:UpdateUnlock(value)
    self:SetProperty(Properties.IsUnlock, value)
end

function XRestaurantBuffData:UpdateIsDefault(value)
    self:SetProperty(Properties.IsDefault, value)
end

function XRestaurantBuffData:IsUnlock()
    return self:GetProperty(Properties.IsUnlock) or false
end

function XRestaurantBuffData:IsDefault()
    return self:GetProperty(Properties.IsDefault) or false
end

function XRestaurantBuffData:GetAreaType()
    return self:GetProperty(Properties.AreaType)
end

function XRestaurantBuffData:GetBuffId()
    return self:GetProperty(Properties.BuffId)
end

function XRestaurantBuffData:GetPropertyNameDict()
    return Properties
end

---@class XRestaurantBuffMgt 餐厅Buff管理
---@field BuffDataDict table<number, XRestaurantBuffData>
local XRestaurantBuffMgt = XClass(nil, "XRestaurantBuffMgt")

function XRestaurantBuffMgt:Ctor()
    --正在使用的Buff
    self.ApplyBuff = {}
    --已经解锁的Buff
    self.UnlockBuffId = {}
    self.BuffDataDict = {}
    --默认Buff
    self.DefaultBuffs = nil
end

function XRestaurantBuffMgt:UpdateData(areaTypeBuffInfos, unlockSectionBuffs, defaultBuffs)
    self.ApplyBuff = areaTypeBuffInfos
    for _, buffInfo in ipairs(areaTypeBuffInfos) do
        local buffId = buffInfo.BuffId
        local buff = self:GetBuffData(buffId)
        buff:UpdateData(buffId, buffInfo.SectionType)
    end
    for _, buffId in ipairs(unlockSectionBuffs) do
        self:UpdateSingleBuff(buffId, false)
    end

    for _, buffId in ipairs(defaultBuffs) do
        self:UpdateSingleBuff(buffId, true)
    end
    self.DefaultBuffs = defaultBuffs
end

function XRestaurantBuffMgt:UpdateSingleBuff(buffId, isDefault) 
    self.UnlockBuffId[buffId] = buffId
    local buffData = self:GetBuffData(buffId)
    buffData:UpdateIsDefault(isDefault)
    buffData:UpdateUnlock(true)
end

--- 获取buff数据
---@param buffId number buffId
---@return XRestaurantBuffData
--------------------------
function XRestaurantBuffMgt:GetBuffData(buffId)
    if not self.BuffDataDict then
        self.BuffDataDict = {}
    end
    local buff = self.BuffDataDict[buffId]
    if not buff then
        buff = XRestaurantBuffData.New(buffId)
        self.BuffDataDict[buffId] = buff
    end

    return buff
end

--- 检查Buff是否解锁
---@param buffId number
---@return boolean
--------------------------
function XRestaurantBuffMgt:CheckBuffUnlok(buffId)
    return self.UnlockBuffId[buffId] ~= nil
end

function XRestaurantBuffMgt:GetDefaultBuffIds()
    return self.DefaultBuffs
end

function XRestaurantBuffMgt:GetApplyBuff()
    return self.ApplyBuff
end

return XRestaurantBuffMgt