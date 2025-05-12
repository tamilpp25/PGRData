---@class XDlcHuntPlayerData
local XDlcHuntPlayerData = XClass(nil, "XDlcHuntPlayerData")

function XDlcHuntPlayerData:Ctor(data)
    ---@private
    self._Data = false
    
    if data then
        self:SetData(data)
    end
end

function XDlcHuntPlayerData:IsEmpty()
    return self._Data and true or false
end

function XDlcHuntPlayerData:SetData(data)
    self._Data = data
end

function XDlcHuntPlayerData:GetPlayerId()
    return self._Data.Id
end

function XDlcHuntPlayerData:GetCharacterId()
    -- 目前联机只有一个角色
    return self._Data.NpcList[1].Character.Id
end

function XDlcHuntPlayerData:GetFashionId()
    return XDlcHuntCharacterConfigs.GetFashionId(self:GetCharacterId())
end

function XDlcHuntPlayerData:GetHeadIcon()
    return XDataCenter.FashionManager.GetFashionSmallHeadIcon(self:GetFashionId())
end

function XDlcHuntPlayerData:_GetName()
    return self._Data.Name or "???"
end

function XDlcHuntPlayerData:GetNickname()
    return XDataCenter.SocialManager.GetPlayerRemark(self:GetPlayerId(), self:_GetName())
end

return XDlcHuntPlayerData