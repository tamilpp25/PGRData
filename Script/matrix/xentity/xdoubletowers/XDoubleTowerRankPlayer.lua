local type = type

--动作塔防排行榜的玩家信息
local XDoubleTowerRankPlayer = XClass(nil, "XDoubleTowerRankPlayer")

local Default = {
    _PlayerId = 0, --玩家Id
    _Name = "", --玩家名字
    _Head = 0, --头像
    _Frame = 0, --头像框
    _Level = 0, --等级
    _Sign = "", --自我介绍？
    _Score = 0, --分数
    _WinCount = 0,  --胜利次数
    _RoleId = 0, --使用的角色
    _Rank = 0, --排名（前端自定义）
}

function XDoubleTowerRankPlayer:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XDoubleTowerRankPlayer:UpdateData(data)
    self._PlayerId = data.PlayerId
    self._Name = data.Name
    self._Head = data.Head
    self._Frame = data.Frame
    self._Level = data.Level
    self._Sign = data.Sign
    self._WinCount = data.WinCount
    self._Score = data.Score
    self._RoleId = data.RoleId
    self._Rank = data.Rank
end

function XDoubleTowerRankPlayer:GetId()
    return self._PlayerId
end

function XDoubleTowerRankPlayer:GetName()
    return self._Name
end

function XDoubleTowerRankPlayer:GetHeadPortraitId()
    return self._Head
end

function XDoubleTowerRankPlayer:GetHeadFrameId()
    return self._Frame
end

function XDoubleTowerRankPlayer:GetScore()
    return self._Score
end

function XDoubleTowerRankPlayer:GetCharacterId()
    return self._RoleId
end

function XDoubleTowerRankPlayer:GetRank()
    return self._Rank
end

return XDoubleTowerRankPlayer