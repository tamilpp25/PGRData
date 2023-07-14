local XReformEnemyBuffGroup = require("XEntity/XReform/Enemy/XReformEnemyBuffGroup")
local XReformEnemyTarget = XClass(nil, "XReformEnemyTarget")

-- config : XReformConfigs.EnemyTargetConfig
function XReformEnemyTarget:Ctor(config)
    self.Config = config
    -- XArchiveMonsterEntity
    self.MonsterEntity = nil
    self.SourceId = nil
    self.Id = self.Config.Id
    self.BuffGroup = nil
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
    -- -- 不显示配置的buff
    -- for _, buffId in ipairs(self.Config.BuffIds) do
    --     if buffId ~= 0 then
    --         buffIdDic[buffId] = true
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
    return result
end

function XReformEnemyTarget:GetReformBuffDetailViewModels()
    local result = {}
    -- 改造buff
    if self.BuffGroup then
        for _, buff in ipairs(self.BuffGroup:GetActiveBuffs()) do
            table.insert(result, {
                Name = buff:GetName(),
                Icon = buff:GetIcon(),
                Description = buff:GetDes(),
                Score = buff:GetScore(),
                Id = buff:GetId(),
            })
        end
    end    
    return result
end

function XReformEnemyTarget:GetAllReformBuffViewModels()
    local result = {}
    -- 改造buff
    if self.BuffGroup then
        for _, buff in ipairs(self.BuffGroup:GetAllBuffs()) do
            table.insert(result, {
                Name = buff:GetName(),
                Icon = buff:GetIcon(),
                Description = buff:GetDes(),
                Score = buff:GetScore(),
                Id = buff:GetId(),
                SimpleDes = buff:GetSimpleDes()
            })
        end
    end    
    return result
end

function XReformEnemyTarget:GetReformedBuffTotalScore()
    local result = 0
    if self.BuffGroup then
        for _, buff in ipairs(self.BuffGroup:GetActiveBuffs()) do
            result = result + buff:GetScore()
        end
    end  
    return result
end

function XReformEnemyTarget:GetMaxReformBuffCount()
    return self.Config.AffixMaxCount
end

-- return : XArchiveMonsterEntity
function XReformEnemyTarget:GetMonsterEntity()
    if self.MonsterEntity == nil then
        self.MonsterEntity = XDataCenter.ArchiveManager.GetArchiveMonsterEntityByNpcId(self.Config.NpcId)
    end
    return self.MonsterEntity
end

function XReformEnemyTarget:GetNpcId()
    return self.Config.NpcId
end

function XReformEnemyTarget:GetBuffGroup()
    if self.BuffGroup == nil then
        self.BuffGroup = XReformEnemyBuffGroup.New(self.Config.AffixGroupId)
    end
    return self.BuffGroup
end

function XReformEnemyTarget:GetMaxBuffScore()
    if self.__MaxBuffScore == nil then
        self.__MaxBuffScore = 0
        local buffGroup = self:GetBuffGroup()
        local maxBuffCount = self:GetMaxReformBuffCount()
        local buffs = buffGroup:GetAllBuffs()
        table.sort(buffs, function(buffA, buffB)
            return buffA:GetScore() > buffB:GetScore()
        end)
        for i = 1, maxBuffCount do
            self.__MaxBuffScore = self.__MaxBuffScore + buffs[i]:GetScore()
        end
    end
    return self.__MaxBuffScore
end

return XReformEnemyTarget