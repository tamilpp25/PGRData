local XReformEnemyBuff = XClass(nil, "XReformEnemyBuff")

function XReformEnemyBuff:Ctor(id)
    self.Config = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformAffixSource, id)
    self.DefaultBuffConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self.Config.BuffIds[1])
end

function XReformEnemyBuff:GetId()
    return self.Config.Id
end

function XReformEnemyBuff:GetName()
    return self.Config.Name or self.DefaultBuffConfig.Name
end

function XReformEnemyBuff:GetIcon()
    return self.Config.Icon or self.DefaultBuffConfig.Icon
end

function XReformEnemyBuff:GetSimpleDes()
    return self.Config.SimpleDes
end

function XReformEnemyBuff:GetDes()
    return self.Config.Des or self.DefaultBuffConfig.Description
end

function XReformEnemyBuff:GetScore()
    return self.Config.AddScore
end

return XReformEnemyBuff