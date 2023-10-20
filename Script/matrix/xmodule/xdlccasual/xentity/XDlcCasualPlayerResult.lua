---@class XDlcCasualPlayerResult
local XDlcCasualPlayerResult = XClass(nil, "XDlcCasualPlayerResult")

function XDlcCasualPlayerResult:Ctor(playerData, playerResultData)
    self:SetData(playerData, playerResultData)
end

function XDlcCasualPlayerResult:SetData(playerData, playerResultData)
    if not playerData then
        return
    end

    self._PlayerId = playerData.PlayerId
    self._PersonalScore = playerData.PersonalScore
    self._HitScore = playerData.HitScore
    self._BeHitDamage = playerData.BeHitDamage
    self._CooperateBonus = playerData.CooperateBonus
    self._IsOffline = false

    if playerResultData then
        self._IsOffline = playerResultData[self._PlayerId] ~= nil
    end
end 

function XDlcCasualPlayerResult:GetPlayerId()
    return self._PlayerId
end 

function XDlcCasualPlayerResult:GetPersonalScore()
    return self._PersonalScore
end

function XDlcCasualPlayerResult:GetHitScore()
    return self._HitScore
end 

function XDlcCasualPlayerResult:GetBeHitDamage()
    return self._BeHitDamage
end 

function XDlcCasualPlayerResult:GetCooperateBonus()
    return self._CooperateBonus
end

function XDlcCasualPlayerResult:IsOffline()
    return self._IsOffline
end

return XDlcCasualPlayerResult