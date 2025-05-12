local XReform2ndAffix = require("XEntity/XReform2/XReform2ndAffix")

---@class XReform2ndMob
local XReform2ndMob = XClass(nil, "XReform2ndMob")

function XReform2ndMob:Ctor(id)
    self._Id = id

    ---@type XReform2ndAffix[]
    self._AffixList = {}
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

function XReform2ndMob:GetAffixAmount()
    return #self._AffixList
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

function XReform2ndMob:GetAffixList()
    return self._AffixList
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

-- 只克隆id
---@return XReform2ndMob
function XReform2ndMob:Clone()
    local mob = XReform2ndMob.New(self._Id)
    return mob
end

---@param model XReformModel
function XReform2ndMob:GetNpcId(model)
    local npcId = model:GetMobNpcId(self._Id)
    return npcId
end

return XReform2ndMob
