local XReform2ndMob = require("XEntity/XReform2/XReform2ndMob")

-- 一波怪
---@class XReform2ndMobGroup
local XReform2ndMobGroup = XClass(nil, "XReform2ndMobGroup")

function XReform2ndMobGroup:Ctor(stage, groupList, index, mobAmount)
    self._IndexInStage = index

    self._GroupList = groupList

    ---@type XReform2ndMob[]
    self._MobCanSelect = false

    ---@type XReform2ndMob[]
    self._MobList = {}

    self._IsShow = index == 1

    self._GroupId = false
    
    self._MobAmountMax = mobAmount

    -- 每个格子, 对应一个sourceId
    self._SourceIdArray = false

    ---@type XReform2ndStage
    self._Stage = stage
end

function XReform2ndMobGroup:GetStage()
    return self._Stage
end

function XReform2ndMobGroup:SetGroupId(id)
    self._GroupId = id
end

function XReform2ndMobGroup:GetGroupId()
    return self._GroupId
end

function XReform2ndMobGroup:SetSourceId(idArray)
    self._SourceIdArray = idArray
end

function XReform2ndMobGroup:GetSourceId(index)
    return self._SourceIdArray[index]
end

function XReform2ndMobGroup:GetIndexBySourceId(id)
    for i = 1, #self._SourceIdArray do
        local sourceId = self._SourceIdArray[i]
        if id == sourceId then
            return i
        end
    end
    return false
end

function XReform2ndMobGroup:IsAlwaysExist()
    return false
end

---@return XReform2ndMob[]
function XReform2ndMobGroup:GetMobCanSelect()
    if not self._MobCanSelect then
        self._MobCanSelect = {}
        for i = 1, #self._GroupList do
            local mobId = self._GroupList[i]
            local mob = XReform2ndMob.New(mobId)
            self._MobCanSelect[i] = mob
        end
    end
    return self._MobCanSelect
end

---@return XReform2ndMob
function XReform2ndMobGroup:GetMob(index)
    return self._MobList[index]
end

function XReform2ndMobGroup:GetMobList()
    return self._MobList
end

function XReform2ndMobGroup:ClearMob()
    self._MobList = {}
end

function XReform2ndMobGroup:AddMob(mob)
    if self:GetMobAmount() < self:GetMobAmountMax() then
        table.insert(self._MobList, 1, mob)
    end
end

function XReform2ndMobGroup:SetMob(index, mob)
    local mobOld = self:GetMob(index)
    if mobOld and mobOld:IsAlwaysExist() then
        return
    end

    if not mob then
        if mobOld then
            mobOld:ClearAffixSelected()
            table.remove(self._MobList, index)
        end
        return
    end

    self._MobList[index] = mob
end

---@param mob XReform2ndMob
function XReform2ndMobGroup:IsMobSelected(mob, index)
    if index then
        local mobSelected = self:GetMob(index)
        if mob:Equals(mobSelected) then
            return true, mobSelected
        end
        return false
    end
    for i = 1, #self._MobList do
        local mobSelected = self._MobList[i]
        if mobSelected:Equals(mob) then
            return true
        end
    end
    return false
end

function XReform2ndMobGroup:IsShow()
    --return self._IsShow
    return #self._MobList > 0 or self._IsShow or self._IndexInStage == 1
end

function XReform2ndMobGroup:SetIsShow(value)
    self._IsShow = value
end

function XReform2ndMobGroup:GetMobAmount()
    local amountMax = self:GetMobAmountMax()
    local amount = 0
    for i = 1, amountMax do
        local mob = self:GetMob(i)
        if mob then
            amount = amount + 1
        end
    end
    return amount
end

function XReform2ndMobGroup:GetMobAmountMax()
    return self._MobAmountMax
end

function XReform2ndMobGroup:IsEmpty()
    return self:GetMobAmount() <= 0
end

return XReform2ndMobGroup
