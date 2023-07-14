--- 管理ChessPursuitMapBoss的服务端数据，只能通过Get方法获取内部数据

local XChessPursuitMapBoss = XClass(nil, "XChessPursuitMapBoss")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

function XChessPursuitMapBoss:Ctor(MapBoss)
    self.ChessPursuitMapBoss = MapBoss
    self.ChessPursuitBossTemplate = XChessPursuitConfig.GetChessPursuitBossTemplate(MapBoss.Id)
end

function XChessPursuitMapBoss:GetId()
    return self.ChessPursuitMapBoss.Id
end

function XChessPursuitMapBoss:GetInitHp()
    return self.ChessPursuitMapBoss.InitHp
end

function XChessPursuitMapBoss:GetChessPursuitBossTemplate()
    return self.ChessPursuitBossTemplate
end

--战斗结束打BOSS最高可获得的分数
function XChessPursuitMapBoss:GetBattleHurtMax()
    return self.ChessPursuitMapBoss.BattleHurtMax
end

--战斗结束我方血量最高可获得的分数
function XChessPursuitMapBoss:GetSelfHpMax()
    return self.ChessPursuitMapBoss.SelfHpMax
end

--策划配置的最大血量
function XChessPursuitMapBoss:GetMaxHpRatio()
    return self.ChessPursuitMapBoss.SubBossMaxHp / self.ChessPursuitMapBoss.InitHp
end

--策划配置的最小击杀次数
function XChessPursuitMapBoss:GetMinBossBattleCount()
    return self.ChessPursuitMapBoss.InitHp / self.ChessPursuitMapBoss.SubBossMaxHp
end

--BOSS随机移动的最小步
function XChessPursuitMapBoss:GetBossStepMin()
    return self.ChessPursuitMapBoss.BossStepMin
end

--BOSS随机移动的最小步
function XChessPursuitMapBoss:GetBossStepMax()
    return self.ChessPursuitMapBoss.BossStepMax
end

return XChessPursuitMapBoss