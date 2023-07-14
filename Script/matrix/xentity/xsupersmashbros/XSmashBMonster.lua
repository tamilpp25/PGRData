--===========================
--超限乱斗怪物对象
--模块负责：吕天元
--===========================
local XSmashBMonster = XClass(nil, "XSmashBMonster")

function XSmashBMonster:Ctor(cfg)
    self:Reset()
    self.MonsterCfg = cfg
end

function XSmashBMonster:Reset()
    self.CurrentHpPercent = 100
end

function XSmashBMonster:GetId()
    return self.MonsterCfg and self.MonsterCfg.Id
end

function XSmashBMonster:GetMonsterId()
    return self.MonsterCfg and self.MonsterCfg.MonsterId or 0
end

function XSmashBMonster:GetFightEventList()
    return self.MonsterCfg and self.MonsterCfg.FightEventList
end

function XSmashBMonster:GetNum()
    return self.MonsterCfg and self.MonsterCfg.Num
end

function XSmashBMonster:GetLimitStageId()
    return self.MonsterCfg and self.MonsterCfg.LimitStageId
end

function XSmashBMonster:GetIcon()
    return self.MonsterCfg and self.MonsterCfg.Icon
end

function XSmashBMonster:GetName() 
    local infoData = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.MonsterInfoConfig, self:GetMonsterInfoId())
    return infoData and infoData.Name or "UnNamed"
end

function XSmashBMonster:GetMonsterModelName()
    local infoData = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.MonsterInfoConfig, self:GetMonsterInfoId())
    return infoData and infoData.ModelName
end

function XSmashBMonster:GetModelScale()
    return self.MonsterCfg and self.MonsterCfg.ModelScale or 1
end

function XSmashBMonster:GetMonsterType()
    return self.MonsterCfg and self.MonsterCfg.MonsterType
end

function XSmashBMonster:GetMonsterTypeName()
    local monsterType = self:GetMonsterType()
    if not monsterType or monsterType < 1 then
        return XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.MonsterTypeConfig, 1).Name
    end
    return XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.MonsterTypeConfig, monsterType).Name
end

function XSmashBMonster:GetMonsterInfoId()
    return self.MonsterCfg and self.MonsterCfg.MonsterInfoId
end

return XSmashBMonster