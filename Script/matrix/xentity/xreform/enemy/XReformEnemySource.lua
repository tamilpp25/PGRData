local XReformEnemyTarget = require("XEntity/XReform/Enemy/XReformEnemyTarget")
local XReformEnemySource = XClass(nil, "XReformEnemySource")

-- config : XReformConfigs.EnemySourceConfig
function XReformEnemySource:Ctor(config)
    self.Config = config
    self.DefaultTarget = nil
    -- XReformEnemyTarget
    self.Targets = {}
    -- key : id value : XReformEnemyTarget
    self.TargetDic = {}
    self:InitTargets()
    -- XArchiveMonsterEntity
    self.MonsterEntity = nil
    self.TargetId = nil
    self.Id = self.Config.Id
end

function XReformEnemySource:GetReformType()
    return XReformConfigs.EvolvableGroupType.Enemy
end

function XReformEnemySource:UpdateTargetId(targetId)
    if targetId == 0 then targetId = nil end
    local target = self:GetTargetById(self.TargetId) 
    if target then
        target:UpdateSourceId(nil)
    end
    self.TargetId = targetId
    if self.TargetId ~= nil then
        target = self:GetTargetById(self.TargetId)
        target:UpdateSourceId(self:GetId())
    end
end

function XReformEnemySource:GetEntityType()
    if self:GetNpcId() == 0 then
        return XReformConfigs.EntityType.Add
    end
    return XReformConfigs.EntityType.Entity
end

function XReformEnemySource:GetTargetId()
    return self.TargetId
end

function XReformEnemySource:GetCurrentTarget()
    return self:GetTargetById(self.TargetId)
end

function XReformEnemySource:GetTargets()
    return self.Targets
end

function XReformEnemySource:GetTargetById(id)
    if id == nil then return nil end
    return self.TargetDic[id]
end

function XReformEnemySource:GetId()
    return self.Config.Id
end

function XReformEnemySource:GetIcon()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetIcon()
    end
    target = self:GetDefaultTarget()
    if target then
        return target:GetIcon()
    end
    return
end

function XReformEnemySource:GetIsActive()
    return self.TargetId ~= nil
end

function XReformEnemySource:GetName()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetName()
    end
    target = self:GetDefaultTarget()
    if target then
        return target:GetName()
    end
    return "unknow"
end

function XReformEnemySource:GetLevel()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetLevel()
    end
    if self.DefaultTarget then
        return self.DefaultTarget:GetLevel()
    end
    return 0
end

function XReformEnemySource:GetNpcId()
    if self.DefaultTarget then
        return self.DefaultTarget:GetNpcId()
    end
    return 0
end

function XReformEnemySource:GetShowLevel()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetShowLevel()
    end
    target = self:GetDefaultTarget()
    if target then
        return target:GetShowLevel()
    end
    return 0
end

function XReformEnemySource:GetBuffDetailViewModels()
    local result = {}
    local buffIdDic = {}
    -- -- 改造的不显示
    -- local target = self:GetCurrentTarget()
    -- if target then
    --     for _, buffId in ipairs(target:GetBuffIds()) do
    --         if buffId ~= 0 then
    --             buffIdDic[buffId] = true
    --         end
    --     end
    -- end
    -- if self.DefaultTarget then
    --     for _, buffId in ipairs(self.DefaultTarget:GetBuffIds()) do
    --         if buffId ~= 0 then
    --             buffIdDic[buffId] = true
    --         end
    --     end
    -- end
    local data = nil
    for buffId, _ in pairs(buffIdDic) do
        data = XReformConfigs.GetEnemyBuffDetail(buffId)
        if data then
            table.insert(result, {
                Name = data.Name,
                Icon = data.Icon,
                Description = data.Des
            })
        end
    end
    -- 敌人词缀改造的buff
    local target = self:GetCurrentTarget() or self.DefaultTarget
    if target then
        appendArray(result, target:GetReformBuffDetailViewModels())
    end
    return result
end

function XReformEnemySource:GetScore()
    return self.Config.AddScore
end

function XReformEnemySource:GetMaxTargetBuffScore()
    if self.__MaxTagerBuffScore == nil then
        self.__MaxTagerBuffScore = 0
        for _, target in ipairs(self.Targets) do
            self.__MaxTagerBuffScore = math.max( self.__MaxTagerBuffScore, target:GetMaxBuffScore() )
        end
        if self.DefaultTarget then
            self.__MaxTagerBuffScore = math.max( self.__MaxTagerBuffScore, self.DefaultTarget:GetMaxBuffScore())
        end
    end
    return self.__MaxTagerBuffScore
end

function XReformEnemySource:GetMaxTagerScore()
    if self.__MaxTagerScore == nil then
        self.__MaxTagerScore = 0
        for _, target in ipairs(self.Targets) do
            self.__MaxTagerScore = math.max( self.__MaxTagerScore, target:GetScore() )
        end
        self.__MaxTagerScore = self.__MaxTagerScore + self:GetScore()
    end
    return self.__MaxTagerScore
end

function XReformEnemySource:GetTargetScore()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetScore()
    end
    return 0
end

-- return : XArchiveMonsterEntity
function XReformEnemySource:GetMonsterEntity()
    local target = self:GetCurrentTarget()
    if target then
        return target:GetMonsterEntity()
    end
    if self.MonsterEntity == nil then
        self.MonsterEntity = XMVCA.XArchive:GetArchiveMonsterEntityByNpcId(self:GetNpcId())
    end
    return self.MonsterEntity
end

function XReformEnemySource:CheckIsCanReform()
    return #self.Targets > 0
end

function XReformEnemySource:CheckIsReformed()
    return self:GetCurrentTarget() ~= nil
end

function XReformEnemySource:GetDefaultTarget()
    return self.DefaultTarget
end

--######################## 私有方法 ########################

function XReformEnemySource:InitTargets()
    local config = nil
    local data = nil
    for _, targetId in ipairs(self.Config.TargetId) do
        config = XReformConfigs.GetEnemyTargetConfig(targetId)
        if config then
            data = XReformEnemyTarget.New(config)
            table.insert(self.Targets, data)
            self.TargetDic[data:GetId()] = data
        end
    end
    if self.Config.DefaultTargetId > 0 then
        config = XReformConfigs.GetEnemyTargetConfig(self.Config.DefaultTargetId)
        if config then
            self.DefaultTarget = XReformEnemyTarget.New(config)
        end
    end
end

return XReformEnemySource