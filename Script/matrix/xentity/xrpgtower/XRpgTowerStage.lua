-- 兵法蓝图关卡对象
local XRpgTowerStage = XClass(nil, "XRpgTowerStage")
--================
--定义StageInfo
--================
function XRpgTowerStage:InitStageInfo()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.RStageCfg.StageId)
    stageInfo.Type = XDataCenter.FubenManager.StageType.RpgTower
end
--================
--构造函数
--================
function XRpgTowerStage:Ctor(rStageId)
    self.RStageCfg = XRpgTowerConfig.GetRStageCfgById(rStageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.RStageCfg.StageId)
    self:InitStageInfo()
end

function XRpgTowerStage:RefreshData(data)
    self.IsPass = true
    if data.Score > self:GetScore() then
        self.Score = data.Score
        self:SetNewTrigger()
    end
end

function XRpgTowerStage:SetNewTrigger()
    self.IsNewRecordTrigger = true
end

function XRpgTowerStage:GetNewTrigger()
    if self.IsNewRecordTrigger then
        self.IsNewRecordTrigger = nil
        return true
    end
    return false
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
    return self.IsPass
end
--================
--获取关卡是否解锁
--================
function XRpgTowerStage:GetIsUnlock()
    if self:GetOrderId() > 1 then
        local preStage = XDataCenter.RpgTowerManager.GetRStageByChapterNOrderId(self:GetActivityId(), self:GetOrderId())
        if preStage then
            return preStage:GetIsPass()
        end
    else
        return true
    end
    return false
end
--================
--获取关卡奖励ID
--================
function XRpgTowerStage:GetStageRewardId()
    return self.StageCfg.FirstRewardId
end
--================
--获取是否显示关卡分数
--================
function XRpgTowerStage:GetIsShowScore()
    return self.RStageCfg.IsShowScore >= 1
end
--================
--获取关卡分数
--================
function XRpgTowerStage:GetScore()
    return self.Score or 0 
end
--================
--重置关卡通过状态
--================
function XRpgTowerStage:Reset()
    self.IsPass = false
    self.Score = 0
end
return XRpgTowerStage