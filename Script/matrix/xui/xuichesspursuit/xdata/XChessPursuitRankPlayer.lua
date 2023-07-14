local type = type

local Default = {
    PlayerId = 0,
    Name = "",
    Head = 0,   --头像
    Frame = 0,  --头像框
    Level = 0,
    Sign = "",  --签名
    Score = 0,
    CaptainIdList = {},
}

local XChessPursuitRankPlayer = XClass(nil, "XChessPursuitRankPlayer")

function XChessPursuitRankPlayer:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XChessPursuitRankPlayer:UpdateData(data)
    if not data then
        return
    end
    self.PlayerId = data.PlayerId
    self.Name = data.Name
    self.Head = data.Head
    self.Frame = data.Frame
    self.Level = data.Level
    self.Sign = data.Sign
    self.Score = data.Score
    self.CaptainIdList = data.CaptainIdList
end

function XChessPursuitRankPlayer:GetPlayerId()
    return self.PlayerId
end

function XChessPursuitRankPlayer:GetScore()
    return self.Score
end

function XChessPursuitRankPlayer:GetCaptainIdList()
    return self.CaptainIdList
end

function XChessPursuitRankPlayer:GetName()
    return self.Name
end

function XChessPursuitRankPlayer:GetHead()
    return self.Head
end

function XChessPursuitRankPlayer:GetFrame()
    return self.Frame
end

function XChessPursuitRankPlayer:GetLevel()
    return self.Level
end

function XChessPursuitRankPlayer:GetSign()
    return self.Sign
end

function XChessPursuitRankPlayer:IsCurPlayer(playerId)
    return self.PlayerId == playerId
end

function XChessPursuitRankPlayer:IsCaptain(index, characterId)
    return self.CaptainIdList and self.CaptainIdList[index] == characterId
end

return XChessPursuitRankPlayer