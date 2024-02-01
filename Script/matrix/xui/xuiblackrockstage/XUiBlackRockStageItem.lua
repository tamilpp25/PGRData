---@class XUiBlackRockStageItem:XUiNode
local XUiBlackRockStageItem = XClass(XUiFestivalStageItem, "XUiBlackRockStageItem")

function XUiBlackRockStageItem:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)
    if not self.IsLock then
        self.RImgFightActiveNor:SetRawImage(self.FStage:GetIcon())
    end
    if self.ImgStoryNor then
        local icon = self.FStage:GetIcon()
        self.ImgStoryNor:SetRawImage(icon)
    end
    self.TxtStageOrder.text = self.FStage:GetOrderName()
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end

return XUiBlackRockStageItem
