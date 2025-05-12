---@class XArchiveNpcEntity
local XArchiveNpcEntity = XClass(nil, "XArchiveNpcEntity")

function XArchiveNpcEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveNpcEntity:SetIsLock(isLock)
    self.IsLock = isLock
end

function XArchiveNpcEntity:SetLockDesc(lockDesc)
    self.LockDesc = lockDesc
end

function XArchiveNpcEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveNpcEntity:GetCfg()
    return XMVCA.XArchive:GetArchiveStoryNpcConfigById(self.Id)
end

function XArchiveNpcEntity:GetId()
    return self.Id
end

function XArchiveNpcEntity:GetIsLock()
    return self.IsLock
end

function XArchiveNpcEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveNpcEntity:GetPicSmall()
    return self:GetCfg().PicSmall
end

function XArchiveNpcEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveNpcEntity:GetName()
    return self:GetCfg().Name
end

function XArchiveNpcEntity:GetPicBig()
    return self:GetCfg().PicBig
end

function XArchiveNpcEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

function XArchiveNpcEntity:GetCondition()
    return self:GetCfg().Condition
end

return XArchiveNpcEntity