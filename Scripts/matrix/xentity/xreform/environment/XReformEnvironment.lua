local XReformEnvironment = XClass(nil, "XReformEnvironment")

-- XReformConfigs.EnvironmentConfig
function XReformEnvironment:Ctor(config)
    self.Config = config
    self.IsActive = false
    self.Id = self.Config.Id
end

function XReformEnvironment:GetReformType()
    return XReformConfigs.EvolvableGroupType.Environment
end

function XReformEnvironment:GetId()
    return self.Config.Id
end

-- 名称
function XReformEnvironment:GetName()
    return self.Config.Name
end

-- 描述
function XReformEnvironment:GetDes()
    return self.Config.Des
end

function XReformEnvironment:GetIcon()
    return self.Config.Icon
end

function XReformEnvironment:GetTextIcon()
    return self.Config.TextIcon
end

function XReformEnvironment:GetPreviewIcon()
    return self.Config.PreviewIcon
end

function XReformEnvironment:GetPreviewText()
    return self.Config.PreviewText
end

-- 积分
function XReformEnvironment:GetScore()
    return self.Config.AddScore
end

function XReformEnvironment:SetIsActive(value)
    self.IsActive = value
end

-- 是否已激活
function XReformEnvironment:GetIsActive()
    return self.IsActive
end

function XReformEnvironment:GetViewModel()
    if self.ViewModel == nil then
        self.ViewModel = {
            Icon = self:GetPreviewIcon(),
            Name = self:GetName(),
            Description = self:GetDes()
        }
    end
    return self.ViewModel
end

return XReformEnvironment