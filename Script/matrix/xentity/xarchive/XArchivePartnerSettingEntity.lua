local XArchivePartnerSettingEntity = XClass(nil, "XArchivePartnerSettingEntity")

function XArchivePartnerSettingEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
end

function XArchivePartnerSettingEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchivePartnerSettingEntity:GetCfg()
    return XMVCA.XArchive:GetPartnerSettingConfigById(self.Id)
end

function XArchivePartnerSettingEntity:GetId()
    return self.Id
end

function XArchivePartnerSettingEntity:GetIsLock()
    return self.IsLock
end

function XArchivePartnerSettingEntity:GetConditionDesc()
    local desc = ""
    local condition = self:GetCondition()
    if condition ~= 0 then
        desc = XConditionManager.GetConditionDescById(condition)
    end
    return desc
end

function XArchivePartnerSettingEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchivePartnerSettingEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchivePartnerSettingEntity:GetType()
    return self:GetCfg().Type
end

function XArchivePartnerSettingEntity:GetTitle()
    return self:GetCfg().Title
end

function XArchivePartnerSettingEntity:GetText()
    return self:GetCfg().Text
end

function XArchivePartnerSettingEntity:GetCondition()
    return self:GetCfg().Condition
end

return XArchivePartnerSettingEntity