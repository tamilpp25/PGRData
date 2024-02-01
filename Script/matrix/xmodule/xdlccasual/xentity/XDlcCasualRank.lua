---@class XDlcCasualRank
local XDlcCasualRank = XClass(nil, "XDlcCasualRank")
local XDlcCasualPlayerRank = require("XModule/XDlcCasual/XEntity/XDlcCasualPlayerRank")

function XDlcCasualRank:Ctor(rankData)
    self:SetData(rankData)
end

function XDlcCasualRank:SetData(rankData)
    if not rankData then
        return
    end

    self._Id = rankData.Id
    self._Score = rankData.Score
    ---@type XDlcCasualPlayerRank[]
    self._PlayerRankList = self._PlayerRankList or {}

    local memberInfo = rankData.MemberInfo
    for i = 1, #memberInfo do
        local playerRank = self._PlayerRankList[i]

        if playerRank then
            playerRank:SetData(memberInfo[i])
        else
            playerRank = XDlcCasualPlayerRank.New(memberInfo[i])
            self._PlayerRankList[i] = playerRank
        end
    end
end

function XDlcCasualRank:GetId()
    return self._Id
end

function XDlcCasualRank:GetScore()
    return self._Score
end

---@return XDlcCasualPlayerRank
function XDlcCasualRank:GetPlayerList()
    return self._PlayerRankList
end

return XDlcCasualRank