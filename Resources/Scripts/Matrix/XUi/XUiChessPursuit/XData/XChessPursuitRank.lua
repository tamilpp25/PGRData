local XChessPursuitRankPlayer = require("XUi/XUiChessPursuit/XData/XChessPursuitRankPlayer")
local XChessPursuitRankScore = require("XUi/XUiChessPursuit/XData/XChessPursuitRankScore")

local type = type
local Default = {
    PlayerList = {},
    ScoreList = {},
}

local XChessPursuitRank = XClass(nil, "XChessPursuitRank")

function XChessPursuitRank:Ctor(groupId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.GroupId = groupId
end

function XChessPursuitRank:UpdateData(data)
    if not data then return end
    self:UpdatePlayerList(data.PlayerList)
    self:UpdateScoreList(data.ScoreList)
end

function XChessPursuitRank:UpdatePlayerList(playerList)
    self.PlayerList = {}
    for i, v in ipairs(playerList) do
        self.PlayerList[i] = XChessPursuitRankPlayer.New(v)
    end
end

function XChessPursuitRank:UpdateScoreList(scoreList)
    self.ScoreList = {}
    for i, v in ipairs(scoreList) do
        self.ScoreList[i] = XChessPursuitRankScore.New(v)
    end
end

function XChessPursuitRank:GetPlayerList()
    return self.PlayerList
end

function XChessPursuitRank:ScoreList()
    return self.ScoreList
end

return XChessPursuitRank