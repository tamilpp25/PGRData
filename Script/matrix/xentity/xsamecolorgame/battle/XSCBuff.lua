local XSCBuff = XClass(nil, "XSCBuff")

function XSCBuff:Ctor(buffId, buffUId)
    self.BuffUId = buffUId
    self.BuffId = buffId
    self.CurCountDown = 0
    self.Config = XSameColorGameConfigs.GetBuffConfig(buffId)
end

function XSCBuff:GetBuffUId()
    return self.BuffUId
end

function XSCBuff:GetBuffId()
    return self.BuffId
end

function XSCBuff:SetCountDown()
    self.CurCountDown = self:GetDuration()
end


function XSCBuff:DoCountDown()
    if self.CurCountDown > 0 then
        self.CurCountDown = self.CurCountDown - 1
    end
end

function XSCBuff:GetCountDown()
    return self.CurCountDown
end
-------------------------------------配置--------------------------------

function XSCBuff:GetName()
    return self.Config.Name
end

function XSCBuff:GetIcon()
    return self.Config.Icon
end

function XSCBuff:GetDesc()
    return self.Config.Desc
end

function XSCBuff:GetDuration()--最大持续时间
    return self.Config.Duration
end

function XSCBuff:GetType()
    return self.Config.Type
end

function XSCBuff:GetTargetColorList()
    return self.Config.TargetColors
end

return XSCBuff