local XArchiveCommunicationEntity = XClass(nil, "XArchiveCommunicationEntity")

function XArchiveCommunicationEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
end

function XArchiveCommunicationEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveCommunicationEntity:GetCfg()
    return XMVCA.XArchive:GetArchiveCommunicationsConfigById(self.Id)
end

function XArchiveCommunicationEntity:GetId()
    return self.Id
end

function XArchiveCommunicationEntity:GetIsLock()
    return self.IsLock
end

function XArchiveCommunicationEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveCommunicationEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveCommunicationEntity:GetCommunicationId()
    return self:GetCfg().CommunicationId
end

function XArchiveCommunicationEntity:GetCommunicationType()
    return self:GetCfg().CommunicationType
end

function XArchiveCommunicationEntity:GetCommunicationIcon()
    return self:GetCfg().CommunicationIcon
end

function XArchiveCommunicationEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveCommunicationEntity:GetName()
    return self:GetCfg().Name
end

function XArchiveCommunicationEntity:GetCondition()
    return self:GetCfg().Condition
end

function XArchiveCommunicationEntity:GetUnLockTime()
    return self:GetCfg().UnLockTime
end

function XArchiveCommunicationEntity:GetBtnContent()
    return self:GetCfg().BtnContent
end

function XArchiveCommunicationEntity:GetNpcName()
    return self:GetCfg().NpcName
end

function XArchiveCommunicationEntity:GetNpcHandIcon()
    return self:GetCfg().NpcHandIcon
end

function XArchiveCommunicationEntity:GetNpcHalfIcon()
    return self:GetCfg().NpcHalfIcon
end

function XArchiveCommunicationEntity:GetContents(index)
    if index then
        return self:GetCfg().Contents[index]
    else
        return self:GetCfg().Contents
    end

end

function XArchiveCommunicationEntity:GetUiType()
    return self:GetCfg().UiType
end

return XArchiveCommunicationEntity