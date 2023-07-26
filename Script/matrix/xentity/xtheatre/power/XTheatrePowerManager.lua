-- 势力和好感度管理
local XTheatrePowerManager = XClass(nil, "XTheatrePowerManager")

function XTheatrePowerManager:Ctor()
    self._UnlockPowerIds = {}  --已解锁的势力Id，存的是TheatrePowerCondition表的Id
    self._UnlockPowerFavorIds = {}  --已解锁的势力好感度，存的是TheatrePowerFavor表的Id（升级成功即解锁）
    self._EffectPowerFavorIds = {}  --已生效的势力好感度，存的是TheatrePowerFavor表的Id（领取奖励成功即生效）
    self._PowerIdToCurLvDic = {}   --已解锁的势力好感度对应的当前等级字典，解锁等级从0开始，计算满级或显示上需+1
end

function XTheatrePowerManager:UpdateData(data)
    local unlockPowerIds = data.UnlockPowerIds
    local unlockPowerFavorIds = data.UnlockPowerFavorIds
    local effectPowerFavorIds = data.EffectPowerFavorIds

    for _, unlockPowerId in ipairs(unlockPowerIds) do
        self._UnlockPowerIds[unlockPowerId] = true
    end

    self:UpdateUnlockPowerFavorIds(unlockPowerFavorIds)

    for _, effectPowerFavorId in ipairs(effectPowerFavorIds) do
        self._EffectPowerFavorIds[effectPowerFavorId] = true
    end
end

function XTheatrePowerManager:UpdateUnlockPowerFavorIds(unlockPowerFavorIds)
    local theatrePowerConditionId
    local lv
    for _, unlockPowerFavorId in ipairs(unlockPowerFavorIds or {}) do
        self._UnlockPowerFavorIds[unlockPowerFavorId] = true
        theatrePowerConditionId = XTheatreConfigs.GetPowerFavorPowerId(unlockPowerFavorId)
        lv = XTheatreConfigs.GetPowerFavorLv(unlockPowerFavorId)
        if not self._PowerIdToCurLvDic[theatrePowerConditionId] or self._PowerIdToCurLvDic[theatrePowerConditionId] < lv then
            self._PowerIdToCurLvDic[theatrePowerConditionId] = lv
        end
    end
end

function XTheatrePowerManager:IsUnlockPower(powerId)
    local conditionId = XTheatreConfigs.GetPowerConditionId(powerId)
    if not XTool.IsNumberValid(conditionId) then
        return true, ""
    end

    return XConditionManager.CheckCondition(conditionId)
end

function XTheatrePowerManager:IsUnlockPowerFavor(powerFavorId)
    return self._UnlockPowerFavorIds[powerFavorId] or false
end

function XTheatrePowerManager:IsEffectPowerFavor(powerFavorId)
    return self._EffectPowerFavorIds[powerFavorId] or false
end

--获得势力好感度已生效的当前等级
function XTheatrePowerManager:GetPowerCurLv(powerId)
    return powerId and self._PowerIdToCurLvDic[powerId] or 0
end

function XTheatrePowerManager:IsPowerMaxLv(powerId)
    local curLv = self:GetPowerCurLv(powerId)
    local maxLv = XTheatreConfigs.GetTheatrePowerMaxLv(powerId)
    return curLv >= maxLv
end

--势力好感度升级
--powerFavorId：发当前等级的TheatrePowerFavor表的ID
function XTheatrePowerManager:RequestTheatrePowerFavorUpgrade(powerFavorId, cb)
    XNetwork.Call("TheatrePowerFavorUpgradeRequest", { PowerFavorId = powerFavorId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        --升级成功设置下一级的TheatrePowerFavor表的ID
        local powerId = XTheatreConfigs.GetPowerFavorPowerId(powerFavorId)
        local curLevel = self:GetPowerCurLv(powerId)
        local theatrePowerFavorId = XTheatreConfigs.GetTheatrePowerIdAndLvToId(powerId, curLevel + 1)
        if theatrePowerFavorId then
            self:UpdateUnlockPowerFavorIds({theatrePowerFavorId})
            if cb then
                cb()
            end
        end
        XUiManager.TipText("TheatreUpLevelSuccess")
    end)
end

--领取势力好感度奖励
--powerFavorId：发TheatrePowerFavor表的ID
function XTheatrePowerManager:RequestTheatreGetPowerFavorReward(powerFavorId, cb)
    XNetwork.Call("TheatreGetPowerFavorRewardRequest", { PowerFavorId = powerFavorId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._EffectPowerFavorIds[powerFavorId] = true
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        else
            XUiManager.TipText("RewardSuccess")
        end

        if cb then
            cb()
        end
    end)
end

return XTheatrePowerManager