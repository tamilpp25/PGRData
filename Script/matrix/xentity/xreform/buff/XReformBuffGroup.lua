local XReformBuff = require("XEntity/XReform/Buff/XReformBuff")
local XReformBuffGroup = XClass(nil, "XReformBuffGroup")

-- config : XReformConfigs.BuffGroupConfig
function XReformBuffGroup:Ctor(config)
    self.Config = config
    -- XReformBuff
    self.Buffs = {}
    -- key : id, value : XReformBuff
    self.BuffDic = {}
    self:InitBuffs()
    self.CurrentChallengeScore = 0
end

-- 所有加成数据
function XReformBuffGroup:GetBuffs()
    return self.Buffs
end

function XReformBuffGroup:GetBuffById(id)
    return self.BuffDic[id]
end

function XReformBuffGroup:GetName()
    return CS.XTextManager.GetText("ReformEvolvableBuffNameText")
end

function XReformBuffGroup:UpdateChallengeScore(buffIds)
    local result = 0
    local buffConfig = nil
    for _, buffId in ipairs(buffIds) do
        buffConfig = XReformConfigs.GetBuffConfig(buffId)
        result = result - buffConfig.SubScore
    end
    self.CurrentChallengeScore = result
end

function XReformBuffGroup:GetChallengeScore()
    return self.CurrentChallengeScore
end

function XReformBuffGroup:GetMaxChallengeScore()
    if self.__MaxChallengeScore == nil then
        local result = 0
        for _, buff in ipairs(self.Buffs) do
            result = result - buff:GetScore()
        end
        self.__MaxChallengeScore = result
    end
    return self.__MaxChallengeScore
end

--######################## 私有方法 ########################

function XReformBuffGroup:InitBuffs()
    local config = nil
    local data = nil
    for _, id in ipairs(self.Config.SubId) do
        config = XReformConfigs.GetBuffConfig(id)
        if config then
            data = XReformBuff.New(config)
            table.insert(self.Buffs, data)
            self.BuffDic[data:GetId()] = data
        end
        
    end
end

return XReformBuffGroup