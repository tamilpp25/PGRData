local XAdventureDifficulty = XClass(nil, "XAdventureDifficulty")

function XAdventureDifficulty:Ctor(id)
    self.Config = XTheatreConfigs.GetTheatreDifficulty(id)
end

function XAdventureDifficulty:GetId()
    return self.Config.Id
end

-- 检查该难度是否开启
function XAdventureDifficulty:GetIsOpen(showTip)
    if self.Config.ConditionId <= 0 then
        return true
    end
    local isOk, desc = XConditionManager.CheckCondition(self.Config.ConditionId)
    if not isOk and showTip then
        XUiManager.TipMsg(desc)
    end
    return isOk
end

-- 获取该难度显示名称
function XAdventureDifficulty:GetName()
    return self.Config.Name
end

function XAdventureDifficulty:GetTitleIcon()
    return XTheatreConfigs.GetClientConfig("DifficultyTitleIcon", self.Config.Id)
end

function XAdventureDifficulty:GetTagIcon()
    return XTheatreConfigs.GetClientConfig("DifficultyButtonIcon", self.Config.Id)
end

function XAdventureDifficulty:GetTagTextIcon()
    return XTheatreConfigs.GetClientConfig("DifficultyButtonTextIcon", self.Config.Id)
end

-- 获得角色携带的buff
function XAdventureDifficulty:GetRoleBuffDatas()
    local result = {}
    for _, id in ipairs(self.Config.FightEventId) do
        table.insert(result, XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id))
    end
    return result
end

function XAdventureDifficulty:GetRoleBuffCount()
    return #self.Config.FightEventId
end

-- 获得敌人携带的buff
function XAdventureDifficulty:GetEnemyBuffDatas()
    local result = {}
    for _, id in ipairs(self.Config.EnemyBuff) do
        table.insert(result, XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id))
    end
    return result
end

function XAdventureDifficulty:GetAllBuffDatas()
    return appendArray(self:GetRoleBuffDatas(), self:GetEnemyBuffDatas())
end

function XAdventureDifficulty:GetRewardIds()
    return self.Config.ShowItemIds
end

function XAdventureDifficulty:GetRewardFactor()
    return self.Config.RewardFactor
end

function XAdventureDifficulty:GetReopenCount()
    return self.Config.ReopenCount
end

return XAdventureDifficulty