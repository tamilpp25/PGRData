local ATTR = XPlanetCharacterConfigs.ATTR

---@class XViewModelPlanetDetail
local XViewModelPlanetDetail = XClass(nil, "XViewModelPlanetDetail")

function XViewModelPlanetDetail:Ctor()
    self._Name = ""
    self._HpPercent = 100
    self._Attr = false
    self._Buff = false
end

---@param entity XPlanetRunningExploreEntity
---@param explore XPlanetRunningExplore
function XViewModelPlanetDetail:SetEntity(entity, explore)
    local characterId = entity.Data.IdFromConfig
    self._Name = XPlanetCharacterConfigs.GetCharacterName(characterId)
    self:UpdateAttr(entity)
    self:UpdateBuff(entity)
end

---@param entity XPlanetRunningExploreEntity
function XViewModelPlanetDetail:UpdateAttr(entity)
    self._Attr = {}

    -- 生命
    local hp = entity.Attr.Life
    local hpMax = entity.Attr.MaxLife
    self._Attr[#self._Attr + 1] = {
        Name = XPlanetCharacterConfigs.GetAttrName(ATTR.Life),
        Value = string.format("%d/%d", hp, hpMax)
    }
    if hpMax > 0 then
        self._HpPercent = hp / hpMax
    else
        self._HpPercent = 100
    end

    -- 攻击
    local attack = entity.Attr.Attack
    self._Attr[#self._Attr + 1] = {
        Name = XPlanetCharacterConfigs.GetAttrName(ATTR.Attack),
        Value = attack
    }

    -- 防御
    local defense = entity.Attr.Defense
    self._Attr[#self._Attr + 1] = {
        Name = XPlanetCharacterConfigs.GetAttrName(ATTR.Defense),
        Value = defense
    }

    -- 防御
    local speed = entity.Attr.Speed
    self._Attr[#self._Attr + 1] = {
        Name = XPlanetCharacterConfigs.GetAttrName(ATTR.AttackSpeed),
        Value = speed
    }

    -- 暴击率
    local criticalPercent = entity.Attr.CriticalPercent
    if criticalPercent > 0 then
        self._Attr[#self._Attr + 1] = {
            Name = XPlanetCharacterConfigs.GetAttrName(ATTR.CriticalChance),
            Value = criticalPercent
        }
    end

    -- 暴击加成
    local criticalDamageAdded = entity.Attr.CriticalDamageAdded
    if criticalDamageAdded > 0 then
        self._Attr[#self._Attr + 1] = {
            Name = XPlanetCharacterConfigs.GetAttrName(ATTR.CriticalDamage),
            Value = criticalDamageAdded
        }
    end
end

function XViewModelPlanetDetail:UpdateBuff()

end

function XViewModelPlanetDetail:GetAttr()

end

function XViewModelPlanetDetail:GetBuff()

end

function XViewModelPlanetDetail:GetName()

end

function XViewModelPlanetDetail:GetHpPercent()
    return self._HpPercent
end

function XViewModelPlanetDetail:IsShowBtnSetLeader()

end

function XViewModelPlanetDetail:SetLeader()

end

return XViewModelPlanetDetail