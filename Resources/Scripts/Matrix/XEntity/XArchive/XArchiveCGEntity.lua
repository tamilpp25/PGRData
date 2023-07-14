local XArchiveCGEntity = XClass(nil, "XArchiveCGEntity")

function XArchiveCGEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveCGEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveCGEntity:GetCfg()
    return XArchiveConfigs.GetArchiveCGDetailConfigById(self.Id)
end

function XArchiveCGEntity:GetId()
    return self.Id
end

function XArchiveCGEntity:GetIsLock()
    return self.IsLock
end

function XArchiveCGEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveCGEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveCGEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveCGEntity:GetName()
    return self:GetCfg().Name
end

function XArchiveCGEntity:GetDesc()
    return self:GetCfg().Desc
end

function XArchiveCGEntity:GetAuthor()
    return self:GetCfg().Author
end

function XArchiveCGEntity:GetBg()
    return self:GetCfg().Bg
end

function XArchiveCGEntity:GetSpineBg()
    return self:GetCfg().SpineBg
end

function XArchiveCGEntity:GetLockBg()
    return self:GetCfg().LockBg
end

function XArchiveCGEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

function XArchiveCGEntity:GetCondition()
    return self:GetCfg().Condition
end

function XArchiveCGEntity:GetIsShowRedPoint()
    return self:GetCfg().IsShowRedPoint
end

function XArchiveCGEntity:GetBgWidth()
    return self:GetCfg().BgWidth
end

function XArchiveCGEntity:GetBgHigh()
    return self:GetCfg().BgHigh
end

function XArchiveCGEntity:GetBgOffSetX()
    return self:GetCfg().BgOffSetX
end

function XArchiveCGEntity:GetBgOffSetY()
    return self:GetCfg().BgOffSetY
end

return XArchiveCGEntity