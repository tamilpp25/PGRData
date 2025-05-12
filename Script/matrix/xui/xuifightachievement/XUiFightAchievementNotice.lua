local XUiFightAchievementNotice = XLuaUiManager.Register(XLuaUi, "UiFightAchievementNotice")

local AchievementGrid = require("XUi/XUiFightAchievement/XUiFightAchievementGrid")

function XUiFightAchievementNotice:OnAwake()
    self.ConfigAgency = XMVCA:GetAgency(ModuleId.XUiFightAchievement)
    self.ChildGrid = {}
end

function XUiFightAchievementNotice:OnDisable()
    for i, v in pairs(self.ChildGrid) do
        v:Dispose()
        self.ChildGrid[i] = nil
    end
end

function XUiFightAchievementNotice:Show(achievementId, configId)
    if self.ChildGrid[achievementId] then
        XLog.Debug("存在正在展示的相同成就Id:" .. achievementId)
        return
    end
    
    local config = self.ConfigAgency:GetConfig(configId)
    if not config then
        return
    end

    self.ChildGrid[achievementId] = AchievementGrid.New(self, achievementId, config)
end

function XUiFightAchievementNotice:Complete(achievementId)
    local grid = self.ChildGrid[achievementId]
    if grid then
        grid:Dispose()
        self.ChildGrid[achievementId] = nil
    end
end

return XUiFightAchievementNotice