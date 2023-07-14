XUiPanelBountyTask = XClass(nil, "XUiPanelBountyTask")

function XUiPanelBountyTask:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

--激活
function XUiPanelBountyTask:SetActiveEx(active)
    self.GameObject:SetActiveEx(active)
end

function XUiPanelBountyTask:SetupContent(taskData)
    self.PanelComplete.gameObject:SetActiveEx(false)
    self.PanelStart.gameObject:SetActiveEx(false)

    self.BountyTask = taskData

    if self.BountyTask == nil then
        return
    end


    local bountyTaskStatus = XDataCenter.BountyTaskManager.BountyTaskStatus
    --根据状态显示按钮状态
    if self.BountyTask.Status == bountyTaskStatus.AcceptReward or self.BountyTask.Status == bountyTaskStatus.Complete then
        self.PanelComplete.gameObject:SetActiveEx(true)
    else
        self.PanelStart.gameObject:SetActiveEx(true)
    end

    local taskConfig = XDataCenter.BountyTaskManager.GetBountyTaskConfig(self.BountyTask.Id)
    if not taskConfig then
        local path = XBountyTaskConfigs.GetBountyTaskPath()
        XLog.ErrorTableDataNotFound("XUiPanelTaskCard:SetupTaskCard", "taskConfig", path, "Id", tostring(self.BountyTask.Id))
        return
    end

    self.DifficultStageCfg = XDataCenter.BountyTaskManager.GetBountyTaskDifficultStageConfig(self.BountyTask.DifficultStageId)
    self.TxtLevel.text = string.format(taskConfig.TextColor, self.DifficultStageCfg.Name)
end

--设置任务数据
function XUiPanelBountyTask:SetupTask()
    if not self.BountyTask then
        return
    end

    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)
    self.PanelTask.gameObject:SetActiveEx(true)

    --根据状态显示按钮状态
    if self.BountyTask.Status == XDataCenter.BountyTaskManager.BountyTaskStatus.AcceptReward then
        self.PanelDone.gameObject:SetActiveEx(true)
    elseif self.BountyTask.Status == XDataCenter.BountyTaskManager.BountyTaskStatus.Complete then
        self.BtnGet.gameObject:SetActiveEx(true)
    else
        self.BtnGo.gameObject:SetActiveEx(true)
    end

    local taskConfig = XDataCenter.BountyTaskManager.GetBountyTaskConfig(self.BountyTask.Id)
    if not taskConfig then
        local path = XBountyTaskConfigs.GetBountyTaskPath()
        XLog.ErrorTableDataNotFound("XUiPanelTaskCard:SetupTaskCard", "taskConfig", path, "Id", tostring(self.BountyTask.Id))
        return
    end

    self.DifficultStageCfg = XDataCenter.BountyTaskManager.GetBountyTaskDifficultStageConfig(self.BountyTask.DifficultStageId)

    self.TxtLevel.text = self.DifficultStageCfg.Name
    self.Parent:SetUiSprite(self.ImgPic, taskConfig.MonsterIcon, function()
        self.ImgPic:SetNativeSize()
    end)
    self:SetupReward(self.BountyTask.RewardId)
end


-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelBountyTask:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelBountyTask:AutoInitUi()
    self.PanelStart = self.Transform:Find("PanelStart")
    self.BtnSkip = self.Transform:Find("PanelStart/BtnSkip"):GetComponent("Button")
    self.TxtLevel = self.Transform:Find("PanelStart/TxtLevel"):GetComponent("Text")
    self.PanelComplete = self.Transform:Find("PanelComplete")
    self.BtnBountyTask = self.Transform:Find("PanelComplete/BtnBountyTask"):GetComponent("Button")
end

function XUiPanelBountyTask:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelBountyTask:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelBountyTask:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelBountyTask:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBountyTask, self.OnBtnBountyTaskClick)
end
-- auto
--跳轉
function XUiPanelBountyTask:OnBtnSkipClick()
    if not self.BountyTask then
        return
    end

    XDataCenter.FubenManager.GoToCurrentMainLine(self.BountyTask.DifficultStageId)
end

--去任务界面
function XUiPanelBountyTask:OnBtnBountyTaskClick()
    if XDataCenter.MaintainerActionManager.IsStart()then
        XDataCenter.FunctionalSkipManager.OnOpenMaintainerAction()
    else
        XLuaUiManager.Open("UiMoneyReward") 
    end
end

return XUiPanelBountyTask