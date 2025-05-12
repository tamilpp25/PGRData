local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
---@class XUiDlcMultiPlayerGiftTaskGrid
local XUiDlcMultiPlayerGiftTaskGrid = XClass(XDynamicGridTask, "XUiDlcMultiPlayerGiftTaskGrid")

function XUiDlcMultiPlayerGiftTaskGrid:OnBtnFinishClick()
    if not self.RootUi or not self._Control then
        return
    end
    self._Control:RequestFinishAllBpTask(self._CurTaskType)
end

function XUiDlcMultiPlayerGiftTaskGrid:SetTaskType(taskType)
    self._CurTaskType = taskType
end

function XUiDlcMultiPlayerGiftTaskGrid:SetControl(control)
    self._Control = control
end

function XUiDlcMultiPlayerGiftTaskGrid:PlayAnimation()
end

function XUiDlcMultiPlayerGiftTaskGrid:AutoInitUi()
    self.Super.AutoInitUi(self)
    self.ImgInactive = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/ImgInactive", "RawImage")
end

function XUiDlcMultiPlayerGiftTaskGrid:UpdateProgress(data)
    self.Super.UpdateProgress(self, data)

    if self.Data.State == XDataCenter.TaskManager.TaskState.InActive then
        self.ImgInactive.gameObject:SetActiveEx(true)
        self.BtnFinish.gameObject:SetActive(false)
        self.BtnSkip.gameObject:SetActive(false)
        self.ImgComplete.gameObject:SetActive(false)
    else
        self.ImgInactive.gameObject:SetActiveEx(false)
    end
end

return XUiDlcMultiPlayerGiftTaskGrid