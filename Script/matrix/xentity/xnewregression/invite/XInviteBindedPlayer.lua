local type = type

-- 邀请活动关联玩家数据
local XInviteBindedPlayer = XClass(nil, "XInviteBindedPlayer")

local Default = {
    _PlayerId = 0,      --玩家Id
    _DailyPoint = 0,    --当日积分
    _TotalPoint = 0,    --总积分
    _Name = "",         --名字
    _HeadPortraitId = 0,    --头像Id
    _HeadFrameId = 0,   --头像框Id
}

function XInviteBindedPlayer:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XInviteBindedPlayer:UpdateData(data)
    self._PlayerId = data.PlayerId
    self._DailyPoint = data.DailyPoint
    self._TotalPoint = data.TotalPoint
end

function XInviteBindedPlayer:UpdatePlayerData(data)
    self._Name = data.Name
    self._HeadPortraitId = data.CurrHeadPortraitId
    self._HeadFrameId = data.CurrHeadFrameId
end

function XInviteBindedPlayer:GetPlayerId()
    return self._PlayerId
end

function XInviteBindedPlayer:GetDailyPoint()
    return self._DailyPoint
end

function XInviteBindedPlayer:GetTotalPoint()
    return self._TotalPoint
end

function XInviteBindedPlayer:GetName()
    return self._Name
end

function XInviteBindedPlayer:GetHeadPortraitId()
    return self._HeadPortraitId
end

function XInviteBindedPlayer:GetHeadFrameId()
    return self._HeadFrameId
end

return XInviteBindedPlayer
