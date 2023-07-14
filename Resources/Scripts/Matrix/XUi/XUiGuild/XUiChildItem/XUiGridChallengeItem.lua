local XUiGridChallengeItem = XClass(nil, "XUiGridChallengeItem")
local ShowTaskNum = 4
local blue = "#3582BF"
local black = "#000000"

function XUiGridChallengeItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridChallengeItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridChallengeItem:SetChallengeItem(data)
    -- 通用
    self.TxtTitleNor.text = data.Name
    self.TxtTitlePress.text = data.Name

    local isTaskChallenge = data.ChallengeType == XGuildConfig.GuildChallengeEnter.GuildTask
    self.PanelTaskNorBg.gameObject:SetActiveEx(isTaskChallenge)
    self.PanelTaskPressBg.gameObject:SetActiveEx(disTaskChallenge)
    self.PanelTask.gameObject:SetActiveEx(isTaskChallenge)
    if isTaskChallenge then
        self:HandleChallengeTask()
    end
    -- 敬请期待
    self.PanelCommon.gameObject:SetActiveEx(data.ChallengeType == XGuildConfig.GuildChallengeEnter.GuildBoss or data.ChallengeType == XGuildConfig.GuildChallengeEnter.GuildPet)
end

function XUiGridChallengeItem:HandleChallengeTask()
    local alltasks = XDataCenter.GuildManager.GetSortedGuildDailyTasks()
    local totalTaskCount = #alltasks
    local finishTaskCount = 0
    for i = 1, totalTaskCount do
        local task = alltasks[i]
        local isBlue = false

        if task.State == XDataCenter.TaskManager.TaskState.Finish or task.State == XDataCenter.TaskManager.TaskState.Invalid then
            finishTaskCount = finishTaskCount + 1
            isBlue = true
        elseif task.State == XDataCenter.TaskManager.TaskState.Achieved then
            isBlue = true
        end
        local txtColor = isBlue and blue or black
        local taskTemplate = XDataCenter.TaskManager.GetTaskTemplate(task.Id)
        if i <= ShowTaskNum then
            self[string.format("TxtTask%d", i)].text = string.format("<color=%s>%s</color>", txtColor, taskTemplate.Desc)
        end
    end
    self.TxtTaskNum.text = string.format("%d/%d", finishTaskCount, totalTaskCount)

    for i = totalTaskCount + 1, ShowTaskNum do
        self[string.format("TxtTask%d", i)].text = ""
    end
end

return XUiGridChallengeItem