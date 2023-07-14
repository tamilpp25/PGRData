local XPartnerStory = XClass(nil, "XPartnerStory")

function XPartnerStory:Ctor(id, condition)
    self.Id = id
    self.IsLock = true
    self.Condition = condition
end

function XPartnerStory:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
    end
end

function XPartnerStory:GetId()
    return self.Id
end

function XPartnerStory:GetIsLock()
    return self.IsLock
end

function XPartnerStory:GetCondition()
    return self.Condition
end

function XPartnerStory:GetConditionDesc()
    local desc = ""
    if self.Condition ~= 0 then
        desc = XConditionManager.GetConditionDescById(self.Condition)
    end
    return desc
end

function XPartnerStory:GetCfg()

end

function XPartnerStory:GetTitle()
    return self:GetCfg().Title
end

function XPartnerStory:GetDesc()
    return self:GetCfg().Desc
end

return XPartnerStory