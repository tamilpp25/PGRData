---@class XDlcCasualCuteCharacter
local XDlcCasualCuteCharacter = XClass(nil, "XDlcCasualCuteCharacter")

function XDlcCasualCuteCharacter:Ctor(config)
    self._Config = config
end

function XDlcCasualCuteCharacter:GetCharacterId()
    return self._Config.Id
end

function XDlcCasualCuteCharacter:GetNpcId()
    return self._Config.NpcId
end

function XDlcCasualCuteCharacter:GetName()
    return self._Config.Name
end

function XDlcCasualCuteCharacter:GetTradeName()
    return self._Config.TradeName
end

function XDlcCasualCuteCharacter:GetHeadIcon()
    return self._Config.HeadIcon
end

function XDlcCasualCuteCharacter:GetRoundHeadImage()
    return self._Config.RoundHeadImage
end

function XDlcCasualCuteCharacter:GetMVPAction()
    return self._Config.MVPAction
end

function XDlcCasualCuteCharacter:GetVictoryAction()
    return self._Config.VictoryAction
end

function XDlcCasualCuteCharacter:GetFailAction()
    return self._Config.FailAction
end

function XDlcCasualCuteCharacter:IsEmpty()
    return self._Config == nil
end

---@param character XDlcCasualCuteCharacter
function XDlcCasualCuteCharacter:Equals(character)
    if self:IsEmpty() and character:IsEmpty() then
        return true
    end
    if self:IsEmpty() or character:IsEmpty() then
        return false
    end
    
    return self:GetCharacterId() == character:GetCharacterId()
end

function XDlcCasualCuteCharacter:EqualsId(characterId)
    if self:IsEmpty() and not characterId then
        return true
    end
    if self:IsEmpty() or not characterId then
        return false
    end

    return self:GetCharacterId() == characterId
end

function XDlcCasualCuteCharacter:Release()
    self._Config = nil
end

function XDlcCasualCuteCharacter:GetModelId()
    local characterId = self:GetCharacterId()

    return XCharacterCuteConfig.GetCuteModelModelName(characterId)
end

function XDlcCasualCuteCharacter:GetActionArray()
    return XCharacterCuteConfig.GetModelRandomAction(self:GetModelId())
end

return XDlcCasualCuteCharacter