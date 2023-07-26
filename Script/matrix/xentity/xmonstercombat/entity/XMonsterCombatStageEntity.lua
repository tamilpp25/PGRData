---@class XMonsterCombatStageEntity
local XMonsterCombatStageEntity = XClass(nil, "XMonsterCombatStageEntity")

function XMonsterCombatStageEntity:Ctor(stageId)
    self:UpdateStageId(stageId)
end

function XMonsterCombatStageEntity:UpdateStageId(stageId)
    self.StageId = stageId
    self.Config = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatStage, stageId)
    self.ConfigDetail = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatStageDetail, stageId)
end

function XMonsterCombatStageEntity:GetType()
    return self.Config.Type or 1
end
-- 解锁怪物id列表
function XMonsterCombatStageEntity:GetUnlockMonsterIds()
    return self.Config.UnlockMonsterIds or {}
end
-- 积分参数
function XMonsterCombatStageEntity:GetScoreParams()
    return self.Config.ScoreParams or {}
end
-- 分数上限
function XMonsterCombatStageEntity:GetScoreLimit()
    return self.Config.ScoreLimit or 0
end
-- 关卡推荐怪物列表
function XMonsterCombatStageEntity:GetRecommendMonsters()
    return self.Config.RecommendMonsters or {}
end

--region 详情信息

-- 关卡描述 关卡详情里使用
function XMonsterCombatStageEntity:GetDescription()
    return self.ConfigDetail.Description or {}
end

--endregion

-- 获取关卡最大分数
function XMonsterCombatStageEntity:GetStageMaxScore()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return 0
    end
    return viewModel:GetStageMaxScore(self.StageId)
end

-- 检查是否是刷分模式
function XMonsterCombatStageEntity:CheckIsScoreModel()
    return self:GetType() > XMonsterCombatConfigs.StageType.Challenge
end

-- 检查是否是挑战关卡
function XMonsterCombatStageEntity:CheckIsChallengeModel()
    return self:GetType() == XMonsterCombatConfigs.StageType.Challenge
end

-- 检查关卡是否通关
function XMonsterCombatStageEntity:CheckIsPass()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return false
    end
    return viewModel:CheckStagePass(self.StageId)
end

-- 检查关卡是否解锁
function XMonsterCombatStageEntity:CheckIsUnlock()
    local viewModel = XDataCenter.MonsterCombatManager.GetViewModel()
    if not viewModel then
        return false
    end
    local unlock = true
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
        unlock = false
    end
    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
        if preStageId > 0 then
            if not viewModel:CheckStagePass(preStageId) then
                unlock = false
                break
            end
        end
    end
    return unlock
end

return XMonsterCombatStageEntity