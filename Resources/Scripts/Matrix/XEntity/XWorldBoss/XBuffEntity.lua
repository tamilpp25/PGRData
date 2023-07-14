local XBuffEntity = XClass(nil, "XBuffEntity")
local CSXGameClientConfig = CS.XGame.ClientConfig
function XBuffEntity:Ctor(id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = self:GetInfoConditionText()
    self.LockDescColor = CSXGameClientConfig:GetString("WorldBossBuffLockColor")
    self.InfoTextColor = CSXGameClientConfig:GetString("WorldBossLockInfoColor")
end

function XBuffEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XBuffEntity:GetCfg()
    return XWorldBossConfigs.GetBuffTemplatesById(self.Id)
end

function XBuffEntity:GetId()
    return self.Id
end

function XBuffEntity:GetIsLock()
    return self.IsLock
end

function XBuffEntity:GetLockDesc()
    return self.LockDesc
end

function XBuffEntity:GetLockDescColor()
    return self.LockDescColor
end

function XBuffEntity:GetInfoTextColor()
    return self.InfoTextColor
end

function XBuffEntity:GetType()
    return self:GetCfg().Type
end

function XBuffEntity:GetPriority()
    return self:GetCfg().Priority
end

function XBuffEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XBuffEntity:GetName()
    return self:GetCfg().Name
end

function XBuffEntity:GetLevel()
    return self:GetCfg().Level
end

function XBuffEntity:GetCustomizeId()
    return self:GetCfg().CustomizeId
end

function XBuffEntity:GetInfoTitle()
    return self:GetCfg().InfoTitle
end

function XBuffEntity:GetInfoText()
    return self:GetCfg().InfoText
end

function XBuffEntity:GetInfoConditionText()
    return self:GetCfg().InfoConditionText
end

function XBuffEntity:GetHintText()
    return self:GetCfg().HintText
end

function XBuffEntity:GetIcon()
    return self:GetCfg().Icon
end

function XBuffEntity:GetIsNotShow()
    return self:GetCfg().IsNotShow
end

return XBuffEntity