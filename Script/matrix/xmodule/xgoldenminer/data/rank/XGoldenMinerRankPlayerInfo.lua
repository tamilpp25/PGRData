--黄金矿工排行榜玩家信息
---@class XGoldenMinerRankPlayerInfo
local XGoldenMinerRankPlayerInfo = XClass(nil, "XGoldenMinerRankPlayerInfo")

function XGoldenMinerRankPlayerInfo:Ctor()
    self._Id = 0                --玩家Id
    self._Name = ""             --玩家名字
    self._HeadPortraitId = 0    --头像
    self._HeadFrameId = 0       --头像框
    self._Score = 0             --分数
    self._CharacterId = 0       --使用的角色
    self._Rank = 0              --排名（前端自定义）
    self._Hexes = {}            --使用的海克斯列表
end

function XGoldenMinerRankPlayerInfo:UpdateData(data)
    self._Id = data.Id
    self._Name = data.Name
    self._HeadPortraitId = data.HeadPortraitId
    self._HeadFrameId = data.HeadFrameId
    self._Score = data.Score
    self._CharacterId = data.CharacterId
    self._Rank = data.Rank
    self._Hexes = data.Hexes
end

function XGoldenMinerRankPlayerInfo:GetId()
    return self._Id
end

function XGoldenMinerRankPlayerInfo:GetName()
    return self._Name
end

function XGoldenMinerRankPlayerInfo:GetHeadPortraitId()
    return self._HeadPortraitId
end

function XGoldenMinerRankPlayerInfo:GetHeadFrameId()
    return self._HeadFrameId
end

function XGoldenMinerRankPlayerInfo:GetScore()
    return self._Score
end

function XGoldenMinerRankPlayerInfo:GetCharacterId()
    return self._CharacterId
end

function XGoldenMinerRankPlayerInfo:GetRank()
    return self._Rank
end

function XGoldenMinerRankPlayerInfo:GetHexes()
    return self._Hexes
end

return XGoldenMinerRankPlayerInfo