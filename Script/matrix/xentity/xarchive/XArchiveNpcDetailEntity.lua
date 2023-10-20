local XArchiveNpcDetailEntity = XClass(nil, "XArchiveNpcDetailEntity")

function XArchiveNpcDetailEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveNpcDetailEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveNpcDetailEntity:GetCfg()
    return XMVCA.XArchive:GetArchiveStoryNpcSettingConfigById(self.Id)
end

function XArchiveNpcDetailEntity:GetId()
    return self.Id
end

function XArchiveNpcDetailEntity:GetIsLock()
    return self.IsLock
end

function XArchiveNpcDetailEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveNpcDetailEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveNpcDetailEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveNpcDetailEntity:GetType()
    return self:GetCfg().Type
end

function XArchiveNpcDetailEntity:GetTitle()
    return self:GetCfg().Title
end

function XArchiveNpcDetailEntity:GetText()
    return self:GetCfg().Text
end

function XArchiveNpcDetailEntity:GetCondition()
    return self:GetCfg().Condition
end

function XArchiveNpcDetailEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

return XArchiveNpcDetailEntity