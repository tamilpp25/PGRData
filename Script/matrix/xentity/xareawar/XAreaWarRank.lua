local XAreaWarRankItem = require("XEntity/XAreaWar/XAreaWarRankItem")

local type = type
local pairs = pairs
local tableInsert = table.insert
local tableSort = table.sort
local tableRemove = table.remove

local Default = {
    _RankList = {}, --排行榜排名信息
    _MyRankItem = {} --我的排名信息
}

---@class XAreaWarRank 全境排行榜数据
---@field _MyRankItem XAreaWarRankItem
---@field _RankList XAreaWarRankItem[]
local XAreaWarRank = XClass(nil, "XAreaWarRank")

function XAreaWarRank:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._RankList = {}
    self._MyRankItem = XAreaWarRankItem.New()
end

function XAreaWarRank:UpdateData(rankList, myRankData)
    local myPlayerId = -1
    --我的排名信息
    if not XTool.IsTableEmpty(myRankData) then
        self._MyRankItem:UpdateData(myRankData)
        myPlayerId = self._MyRankItem:GetPlayerId()
    end
    --排行榜排名信息
    if not XTool.IsTableEmpty(rankList) then
        local serverCount = #rankList
        local clientCount = #self._RankList
        if clientCount > serverCount then
            for i = clientCount, serverCount + 1, -1 do
                tableRemove(self._RankList, i)
            end
        end
        for i, rankData in pairs(rankList) do
            local rank = self._RankList[i]
            if not rank then
                rank = XAreaWarRankItem.New()
                self._RankList[i] = rank
            end
            rank:UpdateData(rankData)
            -- 如果排行榜中有我的数据，使用myRankData进行覆盖
            -- myRankData在服务端更新频率高一点
            if myPlayerId > 0 and rank:GetPlayerId() == myPlayerId then
                rank:UpdateData(myRankData)
            end
        end
        tableSort(
            self._RankList,
            function(a, b)
                return a.Rank < b.Rank
            end
        )
    end
end

function XAreaWarRank:GetRankList()
    return self._RankList
end

function XAreaWarRank:GetMyRankItem()
    return self._MyRankItem
end

return XAreaWarRank
