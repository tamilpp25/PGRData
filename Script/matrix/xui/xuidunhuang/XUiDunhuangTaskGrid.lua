local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiDunhuangTaskGrid = XClass(XDynamicGridTask, "XUiDunhuangTaskGrid")

function XUiDunhuangTaskGrid:AutoInitUi()
    XDynamicGridTask.AutoInitUi(self)
    self.DunhuangImgBg1 = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/RawImage", "RawImage")
    self.DunhuangImgBg2 = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/RawImage2", "RawImage")
end

function XUiDunhuangTaskGrid:ResetData(data)
    XDynamicGridTask.ResetData(self, data)
    if data.ReceiveAll then
        if self.DunhuangImgBg2 then
            self.DunhuangImgBg1.gameObject:SetActiveEx(false)
            self.DunhuangImgBg2.gameObject:SetActiveEx(false)
        end
        return
    end
    if data.State == XDataCenter.TaskManager.TaskState.Finish then
        if self.DunhuangImgBg2 then
            self.DunhuangImgBg2.gameObject:SetActiveEx(true)
        end
        if self.DunhuangImgBg1 then
            self.DunhuangImgBg1.gameObject:SetActiveEx(false)
        end
    else
        if self.DunhuangImgBg2 then
            self.DunhuangImgBg2.gameObject:SetActiveEx(false)
        end
        if self.DunhuangImgBg1 then
            self.DunhuangImgBg1.gameObject:SetActiveEx(true)
        end
    end
end

return XUiDunhuangTaskGrid
