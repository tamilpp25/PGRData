local XSuperTowerPlugin = XClass(nil, "XSuperTowerPlugin")

function XSuperTowerPlugin:Ctor(id)
    self.Config = XSuperTowerConfigs.GetPluginCfgById(id)
    self.Count = 0
end

function XSuperTowerPlugin:InitWithServerData(data)
    self:UpdateCount(data.Count)
end

function XSuperTowerPlugin:UpdateWithServerData(data)
    self:UpdateCount(data.Count)
end

function XSuperTowerPlugin:GetCount()
    return self.Count
end

function XSuperTowerPlugin:UpdateCount(value)
    self.Count = value
end

function XSuperTowerPlugin:GetId()
    return self.Config.Id
end

function XSuperTowerPlugin:GetName()
    return self.Config.Name
end

function XSuperTowerPlugin:GetDesc()
    return self.Config.Description
end

function XSuperTowerPlugin:GetQualityIcon()
    return XSuperTowerConfigs.GetStarIconByQuality(self.Config.Quality) 
end

function XSuperTowerPlugin:GetQualityBg()
    return XSuperTowerConfigs.GetStarBgByQuality(self.Config.Quality)
end

function XSuperTowerPlugin:GetIcon()
    return self.Config.Icon
end

function XSuperTowerPlugin:GetFightEventId()
    return self.Config.FightEventId
end

function XSuperTowerPlugin:GetCharacterId()
    return self.Config.CharacterId
end

function XSuperTowerPlugin:GetCapacity()
    return self.Config.Capacity * self.Count
end

function XSuperTowerPlugin:GetStar()
    return self.Config.Quality
end

function XSuperTowerPlugin:GetQuality()
    return self.Config.Quality
end

function XSuperTowerPlugin:GetResolveId()
    return self.Config.ResolveId
end

function XSuperTowerPlugin:GetResolveCount()
    return self.Config.ResolveCount
end

function XSuperTowerPlugin:GetExp()
    return self.Config.Exp
end

function XSuperTowerPlugin:GetPriority()
    return self.Config.Priority
end

return XSuperTowerPlugin