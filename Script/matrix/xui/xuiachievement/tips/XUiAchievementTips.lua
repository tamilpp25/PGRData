
local XUiAchievementTips = XLuaUiManager.Register(XLuaUi, "UiAchievementTips")

local SHOW_TIME = 2000

function XUiAchievementTips:OnStart(achievementsList)
    XLog.Debug("AchievementGet!", achievementsList)
    self.ShowList = achievementsList
end

function XUiAchievementTips:OnEnable()
    self:StartShow()
end

function XUiAchievementTips:StartShow()
    if self.StartShowFlag then return end
    self:SetNext()
    self.ScheduleId = XScheduleManager.ScheduleForever(function()
                self:SetNext()
            end, SHOW_TIME)
    self.StartShowFlag = true
end

function XUiAchievementTips:SetNext()
    self.GameObject:SetActiveEx(false)
    local showAchievement = self.ShowList[1]
    if not showAchievement then self:StopShow() return end
    table.remove(self.ShowList, 1)
    local achievement = XDataCenter.AchievementManager.GetAchievementByTaskId(showAchievement.Id)
    local isShow = achievement and achievement:GetIsHidden()
    local isHide = achievement and achievement:GetShowTips() or 0
    if isHide == 0 then self:SetNext() return end
    local config = XDataCenter.TaskManager.GetTaskTemplate(showAchievement.Id)
    if not config then self:SetNext() return end
    self.TxtTitle.text = isHide and XUiHelper.GetText("HiddenAchievementTips") or XUiHelper.GetText("AchievementTips")
    self.TxtMedalName.text = config.Title
    self.GameObject:SetActiveEx(true)
end

function XUiAchievementTips:StopShow()
    if not self.StartShowFlag then return end
    self.StartShowFlag = false
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
    self:Close()
end