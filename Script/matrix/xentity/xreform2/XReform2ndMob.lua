local XReform2ndAffix = require("XEntity/XReform2/XReform2ndAffix")

---@class XReform2ndMob
local XReform2ndMob = XClass(nil, "XReform2ndMob")

function XReform2ndMob:Ctor(id)
    self._Id = id

    ---@type XReform2ndAffix[]
    self._AffixList = {}

    ---@type XReform2ndAffix[]
    self._AffixCanSelect = false
end

function XReform2ndMob:GetId()
    return self._Id
end

function XReform2ndMob:SetAffixSelected(affix)
    if self:IsAffixSelected(affix) then
        return false
    end
    table.insert(self._AffixList, affix)
    return true
end

function XReform2ndMob:SetAffixUnselected(affix)
    local isSelected, index = self:IsAffixSelected(affix)
    if isSelected then
        table.remove(self._AffixList, index)
        return true
    end
    return false
end

function XReform2ndMob:GetName()
    return XReform2ndConfigs.GetMobName(self._Id)
end

function XReform2ndMob:GetIcon()
    return XReform2ndConfigs.GetMobIcon(self._Id)
end

function XReform2ndMob:GetMobPressure()
    return XReform2ndConfigs.GetMobPressure(self._Id)
end

-- include affix
function XReform2ndMob:GetPressure()
    local pressure = self:GetMobPressure()
    for i = 1, #self._AffixList do
        local affix = self._AffixList[i]
        pressure = pressure + affix:GetPressure()
    end
    return pressure
end

function XReform2ndMob:GetAffixAmount()
    return #self._AffixList
end

function XReform2ndMob:GetAffixAmountMax()
    return XReform2ndConfigs.GetMobAffixMaxCount(self._Id)
end

---@return XReform2ndAffix[]
function XReform2ndMob:GetAffixCanSelect()
    if not self._AffixCanSelect then
        self._AffixCanSelect = {}
        local groupId = XReform2ndConfigs.GetMobAffixGroupId(self._Id)
        local affixIdList = XReform2ndConfigs.GetAffixGroup(groupId)
        for i = 1, #affixIdList do
            local id = affixIdList[i]
            local affix = XReform2ndAffix.New(id)
            self._AffixCanSelect[i] = affix
        end
    end
    return self._AffixCanSelect
end

function XReform2ndMob:IsAffixSelected(affix)
    for i = 1, #self._AffixList do
        local affixSelected = self._AffixList[i]
        if affix:Equals(affixSelected) then
            return true, i
        end
    end
    return false
end

function XReform2ndMob:GetLevel()
    return XReform2ndConfigs.GetMobLevel(self._Id)
end

function XReform2ndMob:GetAffixList()
    return self._AffixList
end

function XReform2ndMob:GetAffixIconList()

end

function XReform2ndMob:IsAlwaysExist()
    return false
end

---@param mob XReform2ndMob
function XReform2ndMob:Equals(mob)
    if not mob then
        return false
    end
    return self._Id == mob:GetId()
end

function XReform2ndMob:ClearAffixSelected()
    self._AffixList = {}
end

function XReform2ndMob:IsHardMode()
    return XReform2ndConfigs.GetMobIsHardMode(self._Id)
end

-- 只克隆id
function XReform2ndMob:Clone()
    local mob = XReform2ndMob.New(self._Id)
    return mob
end

return XReform2ndMob
