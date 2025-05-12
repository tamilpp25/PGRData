local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
---@class XUiTemple2TaskGrid
local XUiTemple2TaskGrid = XClass(XDynamicGridTask, "XUiTemple2TaskGrid")

function XUiTemple2TaskGrid:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then
        --显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNumQian then
                self.TxtTaskNumQian.text = string.format("<color=#b43589>%s</color>/%s", pair.Value, result)
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    end

    if not self:IsHasButton() then
        return
    end
    self.BtnFinish.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    if self.BtnReceiveHave then
        self.BtnReceiveHave.gameObject:SetActive(false)
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActive(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActive(true)

        if self.BtnSkip["SetButtonState"] then
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            if skipId == nil or skipId == 0 then
                self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
            else
                self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish then
        if self.BtnReceiveHave then
            self.BtnReceiveHave.gameObject:SetActive(true)
        end
    end
end

return XUiTemple2TaskGrid