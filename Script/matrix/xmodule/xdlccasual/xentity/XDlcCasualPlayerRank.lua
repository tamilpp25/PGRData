---@class XDlcCasualPlayerRank
local XDlcCasualPlayerRank = XClass(nil, "XDlcCasualPlayerRank")

function XDlcCasualPlayerRank:Ctor(rankPlayerData)
    self:SetData(rankPlayerData)
end

function XDlcCasualPlayerRank:SetData(rankPlayerData)
    if not rankPlayerData then
        return
    end

    self._Id = rankPlayerData.Id
    self._Name = rankPlayerData.Name
    self._HeadPortraitId = rankPlayerData.HeadPortraitId
    self._HeadFrameId = rankPlayerData.HeadFrameId
end

function XDlcCasualPlayerRank:GetPlayerId()
    return self._Id
end

function XDlcCasualPlayerRank:GetPlayerName()
    return self._Name
end

function XDlcCasualPlayerRank:GetHeadPortraitId()
    return self._HeadPortraitId
end

function XDlcCasualPlayerRank:GetHeadFrameId()
    return self._HeadFrameId
end

return XDlcCasualPlayerRank