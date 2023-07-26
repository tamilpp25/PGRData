local type = type

--黄金矿工排行榜玩家信息
local XGoldenMinerRankPlayerInfo = XClass(nil, "XGoldenMinerRankPlayerInfo")

local Default = {
    _Id = 0, --玩家Id
    _Name = "", --玩家名字
    _HeadPortraitId = 0, --头像
    _HeadFrameId = 0, --头像框
    _Score = 0, --分数
    _CharacterId = 0, --使用的角色
    _Rank = 0, --排名（前端自定义）
}

function XGoldenMinerRankPlayerInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XGoldenMinerRankPlayerInfo:UpdateData(data)
    self._Id = data.Id
    self._Name = data.Name
    self._HeadPortraitId = data.HeadPortraitId
    self._HeadFrameId = data.HeadFrameId
    self._Score = data.Score
    self._CharacterId = data.CharacterId
    self._Rank = data.Rank
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

return XGoldenMinerRankPlayerInfo