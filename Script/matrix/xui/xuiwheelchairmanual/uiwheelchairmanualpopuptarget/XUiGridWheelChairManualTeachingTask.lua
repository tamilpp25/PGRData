local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelChairManualTeachingTask: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelChairManualTeachingTask = XClass(XUiNode, 'XUiGridWheelChairManualTeachingTask')

function XUiGridWheelChairManualTeachingTask:OnStart(data)
    self.BtnReceive.CallBack = handler(self, self.OnReceiveClickEvent)
    
    self:InitRewardsShow(data)
end

---@param data XTaskData
function XUiGridWheelChairManualTeachingTask:Refresh(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    
    ---@type XTableTask
    local template = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self.TxtTitle.text = template.Title
    self.TxtTaskDescribe.text = template.Desc
    
    self:UpdateProgress(data)
end

function XUiGridWheelChairManualTeachingTask:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        self.TxtTaskNumProgress.gameObject:SetActive(true)
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            self.TxtTaskNumProgress.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        self.TxtTaskNumProgress.gameObject:SetActive(false)
    end

    self.BtnReceive:SetButtonState(CS.UiButtonState.Normal)

    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnReceive.gameObject:SetActiveEx(true)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnReceive.gameObject:SetActiveEx(true)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
        self.BtnReceive:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnReceive.gameObject:SetActiveEx(false)
        self.ImgAlreadyReceived.gameObject:SetActiveEx(true)
    end
end

---@param data XTaskData
function XUiGridWheelChairManualTeachingTask:InitRewardsShow(data)
    ---@type XTableTask
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    local rewardGoodsList = XRewardManager.GetRewardList(config.RewardId)
    XUiHelper.RefreshCustomizedList(self.GridCommon.transform.parent, self.GridCommon, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
        local grid = XUiGridCommon.New(nil, go)
        grid:Refresh(rewardGoodsList[index])
    end)
end

function XUiGridWheelChairManualTeachingTask:OnReceiveClickEvent()
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil)
            self.Parent:Refresh()
        end)
    end
end

return XUiGridWheelChairManualTeachingTask