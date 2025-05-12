---@class XArchiveMailEntity
local XArchiveMailEntity = XClass(nil, "XArchiveMailEntity")

function XArchiveMailEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveMailEntity:SetIsLock(isLock)
    self.IsLock = isLock
end

function XArchiveMailEntity:SetLockDesc(lockDesc)
    self.LockDesc = lockDesc
end

function XArchiveMailEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveMailEntity:GetCfg()
    return XMVCA.XArchive:GetArchiveMailsConfigById(self.Id)
end

function XArchiveMailEntity:GetId()
    return self.Id
end

function XArchiveMailEntity:GetIsLock()
    return self.IsLock
end

function XArchiveMailEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveMailEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveMailEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveMailEntity:GetCondition()
    return self:GetCfg().Condition
end

function XArchiveMailEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

function XArchiveMailEntity:GetTitle()
    return self:GetCfg().Title
end

function XArchiveMailEntity:GetSendName()
    return self:GetCfg().SendName
end

function XArchiveMailEntity:GetContent()
    return self:GetCfg().Content
end

function XArchiveMailEntity:GetNpcHandIcon()
    return self:GetCfg().NpcHandIcon
end

return XArchiveMailEntity