---@class XDlcMultiMouseHunterCampResult
local XDlcMultiMouseHunterCampResult = XClass(nil, "XDlcMultiMouseHunterCampResult")

function XDlcMultiMouseHunterCampResult:Ctor(catCampData, mouseCampData)
    self:SetCatCampData(catCampData)
    self:SetMouseCampData(mouseCampData)
end

function XDlcMultiMouseHunterCampResult:SetMouseCampData(data)
    if data then
        self._IsMouseCamp = true
        self._IsCatCamp = false
        self._PlayerId = data.PlayerId
        self._PlayerLevel = data.Level
        self._IsMvp = data.IsMvp or false
        self._Name = data.Name
        self._CharacterId = data.CharacterId
        self._TitleId = data.TitleId
        self._Score = data.Score
        self._Rank = data.Rank
        self._SurvivalTime = data.Param1
        self._IsSurvive = data.Param2 == 1
    end
end

function XDlcMultiMouseHunterCampResult:SetCatCampData(data)
    if data then
        self._IsCatCamp = true
        self._IsMouseCamp = false
        self._PlayerId = data.PlayerId
        self._PlayerLevel = data.Level
        self._IsMvp = data.IsMvp or false
        self._Name = data.Name
        self._CharacterId = data.CharacterId
        self._TitleId = data.TitleId
        self._Score = data.Score
        self._Rank = data.Rank
        self._EliminatePlayers = data.Param1
    end
end

function XDlcMultiMouseHunterCampResult:IsCatCamp()
    return self._IsCatCamp == true
end

function XDlcMultiMouseHunterCampResult:IsMouseCamp()
    return self._IsMouseCamp == true
end

function XDlcMultiMouseHunterCampResult:GetPlayerId()
    return self._PlayerId
end

function XDlcMultiMouseHunterCampResult:GetName()
    return self._Name
end

function XDlcMultiMouseHunterCampResult:GetPlayerLevel()
    return self._PlayerLevel or 0
end

function XDlcMultiMouseHunterCampResult:GetCharacterId()
    return self._CharacterId
end

function XDlcMultiMouseHunterCampResult:GetTitleId()
    return self._TitleId
end

function XDlcMultiMouseHunterCampResult:GetScore()
    return self._Score
end

function XDlcMultiMouseHunterCampResult:GetSurvivalTime()
    return self._SurvivalTime or 0
end

function XDlcMultiMouseHunterCampResult:GetIsSurvive()
    return self._IsSurvive or false
end

function XDlcMultiMouseHunterCampResult:GetEliminatePlayers()
    return self._EliminatePlayers or 0
end

function XDlcMultiMouseHunterCampResult:GetRank()
    return self._Rank
end

function XDlcMultiMouseHunterCampResult:GetIsMvp()
    return self._IsMvp
end

return XDlcMultiMouseHunterCampResult