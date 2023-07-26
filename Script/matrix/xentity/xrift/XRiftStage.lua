-- 1个关卡库对应多个关卡(stage)
-- 不同的【Rift关卡cfg】可以配置同一个stageId
-- 且不同的关卡库可以配置相同的【Rift关卡cfg】Id
local XRiftStage = XClass(nil, "XRiftStage")

function XRiftStage:Ctor(config, index, parentStageGroup)
    self.Config = config
    self.StageId = config.StageId
    -- 服务端下发后确认的数据
    self.s_AllEntityMonsers = {}
    self.s_Passed = nil
    self.s_PassTime = 0
    self.s_ParentStageGroup = parentStageGroup
    self.s_Index = index
end

-- 向下建立关系
function XRiftStage:InitRelationshipChainDown(MonsterData)
    -- 初始化所有拥有的配置怪物（向下单向关系）
    for _, data in pairs(MonsterData) do
        local XMonster = XDataCenter.RiftManager.GetEntitytMonsterById(data.RiftMonsterId)
        XMonster:SyncAffixs(data.BuffIds) -- 至此最后一条关系建立完毕
        table.insert(self.s_AllEntityMonsers, XMonster)
    end
end

function XRiftStage:ClearRelationShipChainDown()
    self.s_AllEntityMonsers = {}
end

-- 【获取】Id
function XRiftStage:GetId()
    return self.Config.Id
end

-- 【获取】Config
function XRiftStage:GetConfig()
    return self.Config
end

-- 【获取】在父节点里的关卡列表里的下标
function XRiftStage:GetIndex()
    return self.s_Index
end

-- 【获取】父层
function XRiftStage:GetParent()
    return self.s_ParentStageGroup
end

-- 【检查】上锁
function XRiftStage:CheckHasLock()
    return false
end

-- 【获取】所有Monster实例
function XRiftStage:GetAllEntityMonsters()
    return self.s_AllEntityMonsers
end

-- 【设置】通过该关卡
function XRiftStage:SetHasPassed(value)
   self.s_Passed = value
end

-- 【检查】通过该关卡
function XRiftStage:CheckHasPassed()
    return self.s_Passed 
end

function XRiftStage:SetPassTime(value)
   self.s_PassTime = value
end

function XRiftStage:GetPassTime()
    return self.s_PassTime 
end

function XRiftStage:SyncData(data)
    self:SetHasPassed(data.IsPassed)
    self:SetPassTime(data.s_PassTime)
end

return XRiftStage