local XReformBuff = XClass(nil, "XReformBuff")

-- config : XReformConfigs.BuffConfig
function XReformBuff:Ctor(config)
    self.Config = config
    self.IsActive = false
    self.Id = self.Config.Id
end

function XReformBuff:GetReformType()
    return XReformConfigs.EvolvableGroupType.Buff
end

function XReformBuff:GetId()
    return self.Config.Id
end

-- 名称
function XReformBuff:GetName()
    return self.Config.Name
end

-- 星级
function XReformBuff:GetStarLevel()
    return self.Config.StarLevel
end

function XReformBuff:GetDes()
    return self.Config.Des
end

-- 图标
function XReformBuff:GetIcon()
    return self.Config.Icon
end

-- 积分
function XReformBuff:GetScore()
    return self.Config.SubScore
end

function XReformBuff:SetIsActive(value)
    self.IsActive = value
end

-- 是否已激活
function XReformBuff:GetIsActive()
    return self.IsActive
end

return XReformBuff