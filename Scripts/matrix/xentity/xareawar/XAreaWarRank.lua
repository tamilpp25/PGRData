local XAreaWarRankItem = require("XEntity/XAreaWar/XAreaWarRankItem")

local type = type
local pairs = pairs
local tableInsert = table.insert
local tableSort = table.sort

local Default = {
    _RankList = {}, --排行榜排名信息
    _MyRankItem = {} --我的排名信息
}

local XAreaWarRank = XClass(nil, "XAreaWarRank")

function XAreaWarRank:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._MyRankItem = XAreaWarRankItem.New()
end

function XAreaWarRank:UpdateData(rankList, myRankData)
    --排行榜排名信息
    if not XTool.IsTableEmpty(rankList) then
        self._RankList = {}
        for _, rankData in pairs(rankList) do
            local rank = XAreaWarRankItem.New()
            rank:UpdateData(rankData)
            tableInsert(self._RankList, rank)
        end
        tableSort(
            self._RankList,
            function(a, b)
                return a.Rank < b.Rank
            end
        )
    end

    --我的排名信息
    if not XTool.IsTableEmpty(myRankData) then
        self._MyRankItem:UpdateData(myRankData)
    end
end

function XAreaWarRank:GetRankList()
    return self._RankList
end

function XAreaWarRank:GetMyRankItem()
    return self._MyRankItem
end

return XAreaWarRank
