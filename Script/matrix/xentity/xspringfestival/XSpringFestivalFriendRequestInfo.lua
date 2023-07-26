local XSpringFestivalFriendRequestInfo = XClass(nil, "XSpringFestivalFriendRequestInfo")

local Default = {
    RequesterId = 0,
    WordId = 0,
    RequestTime = 0,
    ExpireTime = 0,
    FromType = 0,
    HeadPortraitId = 0,
    HeadFrameId = 0,
    Level = 0,
    Name = "",
}

function XSpringFestivalFriendRequestInfo:Ctor(data)
    local temp = data or Default
    for k, v in pairs(temp) do
        self[k] = v
    end
end

function XSpringFestivalFriendRequestInfo:UpdateData(data)
    if not data then
        return
    end
    for k, v in pairs(data) do
        self[k] = v
    end
end

function XSpringFestivalFriendRequestInfo:GetRequesterId()
    return self.RequesterId
end

function XSpringFestivalFriendRequestInfo:GetWordId()
    return self.WordId
end

function XSpringFestivalFriendRequestInfo:GetRequestTime()
    return self.RequestTime
end

function XSpringFestivalFriendRequestInfo:GetExpireTime()
    return self.ExpireTime
end

function XSpringFestivalFriendRequestInfo:GetFromType()
    return self.FromType
end

function XSpringFestivalFriendRequestInfo:GetFriendIcon()
    return self.HeadPortraitId
end

function XSpringFestivalFriendRequestInfo:GetFriendHeadFrameId()
    return self.HeadFrameId
end

function XSpringFestivalFriendRequestInfo:IsExpire()
    local now = XTime.GetServerNowTimestamp()
    return now > self.ExpireTime
end

function XSpringFestivalFriendRequestInfo:IsOnline()
    return true
end

function XSpringFestivalFriendRequestInfo:GetRequesterName()
    return self.Name
end

function XSpringFestivalFriendRequestInfo:GetLastLoginTime()
    return 0
end

return XSpringFestivalFriendRequestInfo