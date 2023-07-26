local XReformStageTime = XClass(nil, "XReformStageTime")

function XReformStageTime:Ctor(id)
    self.Config = XReformConfigs.GetCfgByIdKey(XReformConfigs.TableKey.ReformTimeEnvSource, id)
    self.IsActive = false
end

function XReformStageTime:GetReformType()
    return XReformConfigs.EvolvableGroupType.StageTime
end

function XReformStageTime:GetId()
    return self.Config.Id
end

function XReformStageTime:GetIcon()
    return self.Config.Icon
end

function XReformStageTime:GetPreviewIcon()
    return self.Config.PreviewIcon
end

function XReformStageTime:GetStageTimeLimit()
    return self.Config.StageTimeLimit
end

function XReformStageTime:GetTextIcon()
    return self.Config.TextIcon
end

function XReformStageTime:GetDes()
    return self.Config.Desc
end

function XReformStageTime:GetScore()
    return self.Config.AddScore
end

function XReformStageTime:SetIsActive(value)
    self.IsActive = value
end

-- 是否已激活
function XReformStageTime:GetIsActive()
    return self.IsActive
end

return XReformStageTime