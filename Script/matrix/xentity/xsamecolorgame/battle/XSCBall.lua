local XSCBall = XClass(nil, "XSCBall")

function XSCBall:Ctor(id)
    self.BallId = id
end

function XSCBall:GetBallId()
    return self.BallId
end

-------------------------------------配置--------------------------------
function XSCBall:GetCfg()
    return XSameColorGameConfigs.GetBallConfig(self.BallId)
end

function XSCBall:GetName()
    return self:GetCfg().Name
end

function XSCBall:GetColor()
    return self:GetCfg().Color
end

function XSCBall:GetScore()
    return self:GetCfg().Score
end

function XSCBall:GetIcon()
    return self:GetCfg().Icon
end

function XSCBall:GetBg()
    return self:GetCfg().Bg
end

return XSCBall