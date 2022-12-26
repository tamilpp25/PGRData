local XUiPanelBountyTaskInGrid = XClass(nil, "XUiPanelBountyTaskInGrid")

function XUiPanelBountyTaskInGrid:Ctor(ui, task)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Task = task
    self:InitAutoScript()
    self:Refresh()
end

function XUiPanelBountyTaskInGrid:Refresh()
    local task = self.Task
    local config = XDataCenter.BountyTaskManager.GetBountyTaskConfig(task.Id)
    self.RImgRole:SetRawImage(config.SmallRoleIcon)
    self.PanelKill.gameObject:SetActive(task.Status == XDataCenter.BountyTaskManager.BountyTaskStatus.Complete or task.Status == XDataCenter.BountyTaskManager.BountyTaskStatus.AcceptReward)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelBountyTaskInGrid:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelBountyTaskInGrid:AutoInitUi()
    self.PanelKill = self.Transform:Find("PanelKill")
    self.RImgRole = self.Transform:Find("ImageMask/RImgRole"):GetComponent("RawImage")
end

function XUiPanelBountyTaskInGrid:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelBountyTaskInGrid:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelBountyTaskInGrid:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelBountyTaskInGrid:AutoAddListener()
end
-- auto
return XUiPanelBountyTaskInGrid