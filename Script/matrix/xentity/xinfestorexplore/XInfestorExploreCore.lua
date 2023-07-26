local XInfestorExploreCore = XClass(nil, "XInfestorExploreCore")

--[[{
    // 玩家id
    public int Id;
    // 等级
    public int Level;
}]]
local Default = {
    Id = 0,
    Level = 0,
    WearingPos = 0,
}

function XInfestorExploreCore:Ctor()
    for key, value in pairs(Default) do
        self[key] = value
    end
end

function XInfestorExploreCore:UpdateData(data)
    for key, value in pairs(data) do
        self[key] = value
    end
end

function XInfestorExploreCore:GetId()
    return self.Id
end

function XInfestorExploreCore:SetLevel(newLevel)
    self.Level = newLevel
end

function XInfestorExploreCore:GetLevel()
    return self.Level
end

function XInfestorExploreCore:GetMaxLevel()
    return XFubenInfestorExploreConfigs.GetCoreMaxLevel(self.Id)
end

function XInfestorExploreCore:IsMaxLevel()
    local maxLevel = self:GetMaxLevel()
    return self.Level >= maxLevel
end

function XInfestorExploreCore:GetName()
    return XFubenInfestorExploreConfigs.GetCoreName(self.Id)
end

function XInfestorExploreCore:GetDecomposeMoney()
    return XFubenInfestorExploreConfigs.GetCoreDecomposeMoney(self.Id, self.Level)
end

function XInfestorExploreCore:PutOn(pos)
    self.WearingPos = pos
end

function XInfestorExploreCore:TakeOff()
    self.WearingPos = 0
end

function XInfestorExploreCore:IsWearing()
    return self.WearingPos > 0
end

return XInfestorExploreCore