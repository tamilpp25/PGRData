--==============
--成就对象
--==============
local XAchievement = XClass(nil, "XAchievement")

function XAchievement:Ctor(achievementId)
    self.Id = achievementId or 0
end

function XAchievement:GetCfg()
    local cfg = XAchievementConfigs.GetCfgByIdKey(
            XAchievementConfigs.TableKey.Achievement,
            self:GetId(),
            true
        )
    if cfg then
        return cfg
    end
    return nil
end

function XAchievement:GetId()
    return self.Id or 0
end

function XAchievement:GetType()
    local cfg = self:GetCfg()
    if cfg then
        return cfg.AchievementTypeId
    end
    return 1
end

function XAchievement:GetTaskId()
    local cfg = self:GetCfg()
    if cfg then
        return cfg.TaskId
    end
    return 0
end

function XAchievement:GetQuality()
    local cfg = self:GetCfg()
    if cfg then
        return cfg.Quality
    end
    return 1
end

function XAchievement:GetIsHidden()
    local cfg = self:GetCfg()
    if cfg then
        return cfg.IsHiddenMode and cfg.IsHiddenMode > 0
    end
    return false
end

function XAchievement:GetShowTips()
    local cfg = self:GetCfg()
    if cfg then
        return cfg.ShowTips or 0
    end
    return 0
end

function XAchievement:GetTask()
    return XDataCenter.AchievementManager.GetTaskByTaskId(self:GetTaskId())
end

function XAchievement:GetTaskState()
    return XDataCenter.AchievementManager.GetTaskStateByTaskId(self:GetTaskId())
end

return XAchievement