---@class XScoreTowerQueryRank
local XScoreTowerQueryRank = XClass(nil, "XScoreTowerQueryRank")

function XScoreTowerQueryRank:Ctor()
    -- 当前自己的排名
    self.SelfRank = 0
    -- 当前自己的信息
    ---@type XScoreTowerRankPlayer
    self.SelfRankPlayer = nil
    -- 排行榜总人数
    self.TotalCount = 0
    -- 排行榜玩家信息列表
    ---@type XScoreTowerRankPlayer[]
    self.RankPlayerInfos = {}
end

function XScoreTowerQueryRank:NotifyScoreTowerQueryRankData(data)
    self.SelfRank = data.SelfRank or 0
    self:UpdateSelfRankPlayer(data.SelfRankPlayer)
    self.TotalCount = data.TotalCount or 0
    self:UpdateRankPlayerInfos(data.RankPlayerInfos)
end

--region 数据更新

function XScoreTowerQueryRank:UpdateSelfRankPlayer(data)
    if not data then
        self.SelfRankPlayer = nil
        return
    end
    if not self.SelfRankPlayer then
        self.SelfRankPlayer = require("XModule/XScoreTower/XEntity/Data/XScoreTowerRankPlayer").New()
    end
    self.SelfRankPlayer:NotifyScoreTowerRankPlayerData(data)
end

function XScoreTowerQueryRank:UpdateRankPlayerInfos(data)
    if not data then
        self.RankPlayerInfos = {}
        return
    end
    for i, v in pairs(data) do
        if not self.RankPlayerInfos[i] then
            self.RankPlayerInfos[i] = require("XModule/XScoreTower/XEntity/Data/XScoreTowerRankPlayer").New()
        end
        self.RankPlayerInfos[i]:NotifyScoreTowerRankPlayerData(v)
    end
end

--endregion

--region 数据获取

function XScoreTowerQueryRank:GetSelfRank()
    return self.SelfRank
end

---@return XScoreTowerRankPlayer
function XScoreTowerQueryRank:GetSelfRankPlayer()
    return self.SelfRankPlayer
end

function XScoreTowerQueryRank:GetTotalCount()
    return self.TotalCount
end

---@return XScoreTowerRankPlayer[]
function XScoreTowerQueryRank:GetRankPlayerInfos()
    return self.RankPlayerInfos
end

--endregion

return XScoreTowerQueryRank
