local XSmashBRole = require("XEntity/XSuperSmashBros/XSmashBRole")
local XSmashBAssistanceMonsterRawData = require("XEntity/XSuperSmashBros/XSmashBAssistanceMonsterRawData")

---@class XSmashBAssistanceMonster:XSmashBCharacter
local XSmashBAssistanceMonster = XClass(XSmashBRole, "XSmashBAssistanceMonster")

function XSmashBAssistanceMonster:Ctor(config)
    self._Config = config
    self.RawData = XSmashBAssistanceMonsterRawData.New(config)
end

function XSmashBAssistanceMonster:GetId()
    return self._Config.AssistId
end

function XSmashBAssistanceMonster:GetCore()
    return nil
end

function XSmashBAssistanceMonster:SetCore()
    -- do nothing
end

function XSmashBAssistanceMonster:GetAbility()
    return self._Config.Ability
end

function XSmashBAssistanceMonster:GetCharacterId()
    return self:GetId()
end

function XSmashBAssistanceMonster:GetName()
    return self._Config.MonsterName
end

function XSmashBAssistanceMonster:GetSmallHeadIcon()
    return self._Config.Icon or ""
end

function XSmashBAssistanceMonster:GetHalfBodyIcon()
    return self._Config.RoleCharacterBig
end

function XSmashBAssistanceMonster:GetCareerIcon()
    return self._Config.CareerIcon
end

function XSmashBAssistanceMonster:GetTradeName()
    return false
end

function XSmashBAssistanceMonster:GetObtainElementIcons()
    return false
end

function XSmashBAssistanceMonster:IsNoCareer()
    return true
end

function XSmashBAssistanceMonster:GetHalfBodyCommonIcon()
    return self._Config.HalfBodyImage
end

function XSmashBAssistanceMonster:GetCharacterType()
    return -999
end

return XSmashBAssistanceMonster