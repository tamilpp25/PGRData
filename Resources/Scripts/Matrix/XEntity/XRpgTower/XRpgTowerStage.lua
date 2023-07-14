-- 兵法蓝图关卡对象
local XRpgTowerStage = XClass(nil, "XRpgTowerStage")
--================
--定义StageInfo
--================
local InitStageInfo = function(stageInfo)
    stageInfo.Type = XDataCenter.FubenManager.StageType.RpgTower
end
--================
--构造函数
--================
function XRpgTowerStage:Ctor(rStageId)
    self.RStageCfg = XRpgTowerConfig.GetRStageCfgById(rStageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.RStageCfg.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.RStageCfg.StageId)
    InitStageInfo(stageInfo)
end
--================
--获取关卡基础配置
--================
function XRpgTowerStage:GetStageCfg()
    return self.StageCfg
end
--================
--获取关卡名称
--================
function XRpgTowerStage:GetStageName()
    return self.StageCfg.Name
end
--================
--获取关卡Id
--================
function XRpgTowerStage:GetStageId()
    return self.StageCfg.StageId
end
--================
--获取关卡词缀
--================
function XRpgTowerStage:GetStageEvents()
    local events = {}
    local stageFightEvent = self.RStageCfg.NpcAffixId
    if stageFightEvent then
        for i, eventId in pairs(stageFightEvent) do
            events[i] = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
        end
    end
    return events
end
--================
--获取怪物模型ID
--================
function XRpgTowerStage:GetMonsters()
    return self.RStageCfg.MonsterId
end
--================
--获取关卡难易度
--================
function XRpgTowerStage:GetDifficulty()
    return self.RStageCfg.Difficulty
end
--================
--获取关卡所属活动ID
--================
function XRpgTowerStage:GetActivityId()
    return self.RStageCfg.ActivityId
end
--================
--获取关卡的环境描述
--================
function XRpgTowerStage:GetStageBuffDesc()
    return self.RStageCfg.StageBuffDesc
end
--================
--获取关卡序号
--================
function XRpgTowerStage:GetOrderId()
    return self.RStageCfg.OrderId
end
--================
--获取关卡名称
--================
function XRpgTowerStage:GetOrderName()
    return self.RStageCfg.OrderName
end
--================
--获取关卡推荐等级
--================
function XRpgTowerStage:GetRecommendLevel()
    return self.RStageCfg.RecommendLevel
end
--================
--获取关卡警告类型
--================
function XRpgTowerStage:GetStageWarningType()
    if self:GetRecommendLevel() > XDataCenter.RpgTowerManager.GetCurrentLevel() then
        return XDataCenter.RpgTowerManager.STAGE_WARNING_LEVEL.Danger
    else
        return XDataCenter.RpgTowerManager.STAGE_WARNING_LEVEL.NoWarning
    end
end
--================
--获取关卡是否通过
--================
function XRpgTowerStage:GetIsPass()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.RStageCfg.StageId)
    return stageInfo.Passed
end
--================
--获取关卡是否解锁
--================
function XRpgTowerStage:GetIsUnlock()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.RStageCfg.StageId)
    return stageInfo.Unlock
end
--================
--获取关卡奖励ID
--================
function XRpgTowerStage:GetStageRewardId()
    return self.StageCfg.FirstRewardId
end
--================
--重置关卡通过状态
--================
function XRpgTowerStage:Reset()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.RStageCfg.StageId)
    if self:GetOrderId() ~= 1 then stageInfo.Unlock = false end
    stageInfo.Passed = false
end
return XRpgTowerStage