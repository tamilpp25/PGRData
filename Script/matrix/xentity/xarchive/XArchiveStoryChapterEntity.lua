local XArchiveStoryChapterEntity = XClass(nil, "XArchiveStoryChapterEntity")

function XArchiveStoryChapterEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveStoryChapterEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveStoryChapterEntity:GetCfg()
    return XMVCA.XArchive:GetArchiveStoryChapterConfigById(self.Id)
end

function XArchiveStoryChapterEntity:GetId()
    return self.Id
end

function XArchiveStoryChapterEntity:GetIsLock()
    return self.IsLock
end

function XArchiveStoryChapterEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveStoryChapterEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveStoryChapterEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveStoryChapterEntity:GetName()
    return self:GetCfg().Name
end

function XArchiveStoryChapterEntity:GetBg()
    return self:GetCfg().Bg
end

function XArchiveStoryChapterEntity:GetLockBg()
    return self:GetCfg().LockBg
end

function XArchiveStoryChapterEntity:GetBgWidth()
    return self:GetCfg().BgWidth
end

function XArchiveStoryChapterEntity:GetBgHigh()
    return self:GetCfg().BgHigh
end

function XArchiveStoryChapterEntity:GetBgOffSetX()
    return self:GetCfg().BgOffSetX
end

function XArchiveStoryChapterEntity:GetBgOffSetY()
    return self:GetCfg().BgOffSetY
end

return XArchiveStoryChapterEntity