local XNieRBoss = XClass(nil, "XNieRBoss")

function XNieRBoss:Ctor(data, chapterId)
    self:UpdateData(data, chapterId)
end

function XNieRBoss:UpdateData(data, chapterId)
    self.StageId = data.StageId
    self.LeftHp = data.LeftHp 
    self.Score = data.Score
    self.MaxHp = data.MaxHp
end

function XNieRBoss:GetLeftHp()
    return self.LeftHp
end

function XNieRBoss:GetScore()
    return self.Score
end

function XNieRBoss:GetMaxHp()
    return self.MaxHp
end

function XNieRBoss:IsBossDeath()
    return self.LeftHp <= 0
end

return XNieRBoss