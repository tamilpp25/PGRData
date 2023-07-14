local type = type

local Default = {
    Score = 0,
    Count = 0,
}

local XChessPursuitRankScore = XClass(nil, "XChessPursuitRankScore")

function XChessPursuitRankScore:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:UpdateData(data)
end

function XChessPursuitRankScore:UpdateData(data)
    if not data then
        return
    end
    self.Score = data.Score
    self.Count = data.Count
end

function XChessPursuitRankScore:GetScore()
    return self.Score
end

function XChessPursuitRankScore:GetCount()
    return self.Count
end

return XChessPursuitRankScore