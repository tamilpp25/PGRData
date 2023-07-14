local XArchiveStoryDetailEntity = XClass(nil, "XArchiveStoryDetailEntity")

function XArchiveStoryDetailEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveStoryDetailEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveStoryDetailEntity:GetCfg()
    return XArchiveConfigs.GetArchiveStoryDetailConfigById(self.Id)
end

function XArchiveStoryDetailEntity:GetId()
    return self.Id
end

function XArchiveStoryDetailEntity:GetIsLock()
    return self.IsLock
end

function XArchiveStoryDetailEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveStoryDetailEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveStoryDetailEntity:GetChapterId()
    return self:GetCfg().ChapterId
end

function XArchiveStoryDetailEntity:GetName()
    return self:GetCfg().Name
end

function XArchiveStoryDetailEntity:GetSubName()
    return self:GetCfg().SubName
end

function XArchiveStoryDetailEntity:GetIcon()
    return self:GetCfg().Icon
end

function XArchiveStoryDetailEntity:GetDescTitle()
    return self:GetCfg().DescTitle
end

function XArchiveStoryDetailEntity:GetDesc()
    return self:GetCfg().Desc
end

function XArchiveStoryDetailEntity:GetCondition()
    return self:GetCfg().Condition
end

function XArchiveStoryDetailEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

function XArchiveStoryDetailEntity:GetStoryId(id)
    if id then
        return self:GetCfg().StoryId[id]
    else
        return self:GetCfg().StoryId
    end
end

return XArchiveStoryDetailEntity