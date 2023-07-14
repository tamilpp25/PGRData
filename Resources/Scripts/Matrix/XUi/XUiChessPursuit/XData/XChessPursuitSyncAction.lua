local XChessPursuitSyncAction = XClass(nil, "XChessPursuitSyncAction")

function XChessPursuitSyncAction:Ctor(activeData)
    self.ActiveData = activeData
end

function XChessPursuitSyncAction:GetType()
    return self.ActiveData.Type
end

function XChessPursuitSyncAction:GetCardId()
    return self.ActiveData.CardId
end

function XChessPursuitSyncAction:GetCardEffectId()
    return self.ActiveData.CardEffectId
end

function XChessPursuitSyncAction:GetCoin()
    return self.ActiveData.Coin
end

--剩余持续次数
function XChessPursuitSyncAction:GetKeepCount()
    return self.ActiveData.KeepCount
end

--Boss需要移动到的位置
function XChessPursuitSyncAction:GetBoosPos()
    return self.ActiveData.BoosPos
end

--战斗完对Boss造成的伤害
function XChessPursuitSyncAction:GetBattleHurt()
    return self.ActiveData.BattleHurt
end

--战斗完对Boss造成的伤害积分
function XChessPursuitSyncAction:GetBattleScore()
    return self.ActiveData.BattleScore
end

--战斗完我方血量的积分
function XChessPursuitSyncAction:GetSelfScore()
    return self.ActiveData.SelfScore
end

--战斗完我方血量的百分比（整数）
function XChessPursuitSyncAction:GetSelfHp()
    return self.ActiveData.SelfHp
end

--战斗完的总积分
function XChessPursuitSyncAction:GetSumScore()
    return self.ActiveData.BattleScore + self.ActiveData.SelfScore
end

--卡牌播放完效果之后，BossHP
function XChessPursuitSyncAction:GetBossHp()
    return self.ActiveData.BossHp
end

--产生的FightEvent
function XChessPursuitSyncAction:GetFightEvents()
    return self.ActiveData.FightEvents
end

--boss身上加卡
function XChessPursuitSyncAction:GetAddBossCard()
    return self.ActiveData.AddBossCard
end

--战斗的持续时间
function XChessPursuitSyncAction:GetLeftTime()
    return math.abs(self.ActiveData.LeftTime)
end

--Boss朝向
function XChessPursuitSyncAction:GetBossMoveDirection()
    return self.ActiveData.BossMoveDirection
end

--战斗是否胜利
function XChessPursuitSyncAction:GetIsWin()
    return self.ActiveData.IsWin
end

--Boss伤害记录
function XChessPursuitSyncAction:GetHurtBoss()
    return self.ActiveData.HurtBoss
end

--强退
function XChessPursuitSyncAction:GetIsForceExit()
    return self.ActiveData.IsForceExit
end

return XChessPursuitSyncAction