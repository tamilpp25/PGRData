local XReformEnemyTarget = XClass(nil, "XReformEnemyTarget")

-- config : XReformConfigs.EnemyTargetConfig
function XReformEnemyTarget:Ctor(config)
    self.Config = config
    -- XArchiveMonsterEntity
    self.MonsterEntity = nil
    self.SourceId = nil
    self.Id = self.Config.Id
end

function XReformEnemyTarget:UpdateSourceId(id)
    self.SourceId = id
end

function XReformEnemyTarget:GetSourceId()
    return self.SourceId
end

function XReformEnemyTarget:GetIsActive()
    return self.SourceId ~= nil and self.SourceId ~= 0
end

function XReformEnemyTarget:GetId()
    return self.Config.Id
end

function XReformEnemyTarget:GetIcon()
    return self.Config.HeadIcon
end

function XReformEnemyTarget:GetName()
    return self.Config.Name
end

function XReformEnemyTarget:GetLevel()
    return self.Config.Level
end

function XReformEnemyTarget:GetShowLevel()
    return self.Config.ShowLevel
end

function XReformEnemyTarget:GetScore()
    return self.Config.AddScore
end

function XReformEnemyTarget:GetBuffIds()
    return self.Config.BuffIds
end

function XReformEnemyTarget:GetBuffDetailViewModels()
    local result = {}
    local buffIdDic = {}
    for _, buffId in ipairs(self.Config.BuffIds) do
        if buffId ~= 0 then
            buffIdDic[buffId] = true
        end
    end
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
    return result
end

-- return : XArchiveMonsterEntity
function XReformEnemyTarget:GetMonsterEntity()
    if self.MonsterEntity == nil then
        self.MonsterEntity = XDataCenter.ArchiveManager.GetArchiveMonsterEntityByNpcId(self.Config.NpcId)
    end
    return self.MonsterEntity
end

return XReformEnemyTarget