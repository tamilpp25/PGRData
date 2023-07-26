local XPlanetRoleBase = require("XEntity/XPlanet/Explore/XPlanetRoleBase")
local XPlanetBuff = require("XEntity/XPlanet/Explore/XPlanetBuff")
local ATTR = XPlanetCharacterConfigs.ATTR

---@class XPlanetBoss:XPlanetRoleBase
local XPlanetBoss = XClass(XPlanetRoleBase, "XPlanetBoss")

function XPlanetBoss:Ctor(id)
    self._Id = id
    self._GroupIdFromStage = false
    self._AttrList = false
    self._Buff = false
    self._Debuff = false
    self._Camp = XPlanetExploreConfigs.CAMP.BOSS
    self._IdFromServer = 0
    self._GridIdInExplore = 0
end

function XPlanetBoss:SetBossId(id)
    self._Id = id
end

function XPlanetBoss:SetGroupIdFromStage(id)
    self._GroupIdFromStage = id
end

function XPlanetBoss:SetGroupIdByStage(stageId)
    if not stageId then
        stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    end
    self._GroupIdFromStage = stageId
end

function XPlanetBoss:GetBossId()
    return self._Id
end

function XPlanetBoss:SetIdFromServer(id)
    self._IdFromServer = id
end

function XPlanetBoss:GetIdFromServer()
    return self._IdFromServer
end

function XPlanetBoss:GetIcon()
    return XPlanetStageConfigs.GetBossIcon(self._Id)
end

function XPlanetBoss:GetProgress2Born()
    return XPlanetStageConfigs.GetBossProgress2Born(self._GroupIdFromStage, self._Id)
end

function XPlanetBoss:GetFightingPower()
    return XPlanetStageConfigs.GetBossFightingPower(self._GroupIdFromStage, self._Id)
end

function XPlanetBoss:GetFightingPowerRecommend()
    return XPlanetStageConfigs.GetBossFightingPowerRecommend(self._GroupIdFromStage, self._Id)
end

function XPlanetBoss:GetName()
    return XPlanetStageConfigs.GetBossName(self._Id)
end

function XPlanetBoss:_GetAttr()
    if self._AttrList then
        return self._AttrList
    end
    local attrId = XPlanetStageConfigs.GetBossAttrId(self._Id)
    local attrConfig = XPlanetStageConfigs.GetAttr(attrId)
    local list = {
        [ATTR.Life] = attrConfig.Life,
        [ATTR.MaxLife] = attrConfig.Life,
        [ATTR.Attack] = attrConfig.Attack,
        [ATTR.Defense] = attrConfig.Defense,
        [ATTR.AttackSpeed] = attrConfig.AttackSpeed,
        [ATTR.CriticalDamage] = attrConfig.CriticalDamage,
        [ATTR.CriticalChance] = attrConfig.CriticalChance,
    }
    return list
end

function XPlanetBoss:SetAttrList(attrList)
    self._AttrList = attrList
end

function XPlanetBoss:SetBuff()

end

function XPlanetBoss:_GetBuff()
    if self._Buff and self._Debuff then
        return self._Buff, self._Debuff
    end
    local list = XPlanetStageConfigs.GetBossEvents(self._Id)
    local buffList = {}
    local debuffList = {}
    for _, eventId in pairs(list) do
        ---@type XPlanetBuff
        local buff = XPlanetBuff.New()
        buff:SetEventId(eventId)
        buff:SetAmount(1)
        if buff:IsIncrease() then
            buffList[#buffList + 1] = buff
        else
            debuffList[#debuffList + 1] = buff
        end
    end
    self._Buff = buffList
    self._Debuff = debuffList
    return buffList, debuffList
end

function XPlanetBoss:GetRound2Born()
    local stage = XDataCenter.PlanetExploreManager.GetStage()
    local progressPerRound = stage:GetProgressPerRound()
    local progress2Born = self:GetProgress2Born()
    return math.ceil(progress2Born / progressPerRound)
end

function XPlanetBoss:IsSpecialBoss()
    return XPlanetStageConfigs.IsSpecialBoss(self._Id)
end

function XPlanetBoss:RequestUpdateAttr()
    XDataCenter.PlanetManager.RequestUpdateDetailMonster(self)
end

function XPlanetBoss:SetGridId(id)
    self._GridIdInExplore = id
end

function XPlanetBoss:GetGridId()
    return self._GridIdInExplore
end

return XPlanetBoss