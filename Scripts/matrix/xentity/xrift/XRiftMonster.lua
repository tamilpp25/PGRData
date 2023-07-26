-- 大秘境【怪物】实例。只提供客户端展示数据的接口，只与大秘境的monster表耦合
-- 怪物的词缀是每次随机同关卡库下发的
local XRiftMonster = XClass(nil, "XRiftMonster")

function XRiftMonster:Ctor(config)
    self.Config = config
    -- 服务端下发后确认的数据
    self.s_Affixs = {} -- XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id)
end

-- 【获取】Id
function XRiftMonster:GetId()
    return self.Config.Id
end

-- 【获取】Config
function XRiftMonster:GetConfig()
    return self.Config
end

-- 【获取】怪物Id
function XRiftMonster:GetMonsterNpcId()
    return self.Config.NpcId
end

-- 【获取】怪物头像
function XRiftMonster:GetMonsterHeadIcon()
    return self.Config.HeadIcon
end

-- 【获取】怪物词缀
function XRiftMonster:GetAllAffixs()
    return self.s_Affixs
end

-- 【同步】怪物词缀
function XRiftMonster:SyncAffixs(data)
    self.s_Affixs = data
end

function XRiftMonster:ClearAffixs()
    self.s_Affixs = {}
end

function XRiftMonster:SyncData()
end

return XRiftMonster