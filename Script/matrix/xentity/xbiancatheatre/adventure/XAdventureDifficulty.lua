local XAdventureDifficulty = XClass(nil, "XAdventureDifficulty")

function XAdventureDifficulty:Ctor(id)
    self.Config = XBiancaTheatreConfigs.GetTheatreDifficulty(id)
end

function XAdventureDifficulty:GetId()
    return self.Config.Id
end

-- 检查该难度是否开启
function XAdventureDifficulty:GetIsOpen(showTip)
    if self.Config.ConditionId <= 0 then
        return true
    end
    --local isOk, desc = XConditionManager.CheckCondition(self.Config.ConditionId)
    local isOk = XDataCenter.BiancaTheatreManager.CheckDifficultyUnlock(self.Config.Id)
    if not isOk and showTip then
        local desc = XConditionManager.GetConditionDescById(self.Config.ConditionId)
        XUiManager.TipMsg(desc)
    end
    return isOk
end

-- 获得该难度名称的图标
function XAdventureDifficulty:GetTitleIcon()
    return XBiancaTheatreConfigs.GetClientConfig("DifficultyTitleIcon", self:GetId())
end

-- 获取该难度显示名称
function XAdventureDifficulty:GetName()
    return self.Config.Name
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
    return self.Config.OutItemFactor
end

function XAdventureDifficulty:GetExpFactor()
    return self.Config.ExpFactor
end

function XAdventureDifficulty:GetTitle()
    return self.Config.Title
end

function XAdventureDifficulty:GetDesc()
    return self.Config.Desc
end

function XAdventureDifficulty:GetIcon()
    return self.Config.Icon
end

return XAdventureDifficulty