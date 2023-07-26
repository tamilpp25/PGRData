--===========================
--超级爬塔 爬塔关卡 实体
--模块负责：吕天元
--===========================
local XSuperTowerTierStage = XClass(nil, "XSuperTowerTierStage")

function XSuperTowerTierStage:Ctor(tierManager, cfg)
    self.TierManager = tierManager
    self.TierCfg = cfg
end

function XSuperTowerTierStage:InitStageInfo()
    local stageId = self:GetStageId()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo then
        stageInfo.Type = XDataCenter.FubenManager.StageType.SuperTower
    end
end
--=================
--获取配置表ID
--=================
function XSuperTowerTierStage:GetId()
    return self.TierCfg and self.TierCfg.Id
end
--=================
--获取关卡ID
--=================
function XSuperTowerTierStage:GetStageId()
    return self.TierCfg and self.TierCfg.StageId
end
--=================
--获取层数
--=================
function XSuperTowerTierStage:GetTier()
    return self.TierCfg and self.TierCfg.Tier
end
--=================
--获取对应主题ID
--=================
function XSuperTowerTierStage:GetMapId()
    return self.TierCfg and self.TierCfg.MapId
end
--=================
--获取插件掉落ID
--=================
function XSuperTowerTierStage:GetPluginDropId()
    return self.TierCfg and self.TierCfg.PluginDropId
end
--=================
--获取分数
--=================
function XSuperTowerTierStage:GetScore()
    return self.TierCfg and self.TierCfg.Score
end
--=================
--获取积分类型
--=================
function XSuperTowerTierStage:GetScoreByIndex(index)
    local score = self:GetScore()
    return score and score[index]
end

function XSuperTowerTierStage:GetMaxScore()
    if not self.MaxScore then
        self.MaxScore = 0
        local score = self:GetScore()
        for _, point in pairs(score) do
            self.MaxScore = self.MaxScore + point
        end
    end
    return self.MaxScore
end
return XSuperTowerTierStage