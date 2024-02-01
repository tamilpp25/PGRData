---@class XDlcCasualResult
local XDlcCasualResult = XClass(nil, "XDlcCasualResult")
local XDlcCasualPlayerResult = require("XModule/XDlcCasual/XEntity/XDlcCasualPlayerResult")

function XDlcCasualResult:Ctor(resultData, playerResultData)
    self:SetData(resultData, playerResultData)
end

function XDlcCasualResult:SetData(resultData, playerResultData)
    if not resultData then
        return
    end

    self._WorldId = resultData.WorldId
    self._TeamScore = resultData.TeamScore
    self._IsPersonNewRecord = resultData.IsPersonNewRecord
    self._IsTeamNewRecord = resultData.IsTeamNewRecord
    ---@type XDlcCasualPlayerResult[]
    self._PlayerResultList = self._PlayerResultList or {}

    local players = resultData.Players
    for i = 1, #players do
        local playerResult = self._PlayerResultList[i]
        
        if playerResult then
            playerResult:SetData(players[i], playerResultData)
        else
            playerResult = XDlcCasualPlayerResult.New(players[i], playerResultData)
            self._PlayerResultList[i] = playerResult
        end
    end 
end

function XDlcCasualResult:GetWorldId()
    return self._WorldId
end

function XDlcCasualResult:GetTeamScore()
    return self._TeamScore
end

function XDlcCasualResult:IsPersonNewRecord()
    return self._IsPersonNewRecord
end

function XDlcCasualResult:IsTeamNewRecord()
    return self._IsTeamNewRecord
end

---@return XDlcCasualPlayerResult[]
function XDlcCasualResult:GetPlayerResultList()
    return self._PlayerResultList
end

function XDlcCasualResult:IsPlayerResultListEmpty()
    return self._PlayerResultList == nil
end

return XDlcCasualResult