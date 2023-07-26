-- 大秘境区域异常点(多队伍作战层)格子
local XUiGridRiftChapterOutliers = XClass(nil, "XUiGridRiftChapterOutliers")

function XUiGridRiftChapterOutliers:Ctor(ui, rootUi)
    self.RootUi2D = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridRiftChapterOutliers:UpdateData(xFightLayer)
    self.XFightLayer = xFightLayer
    local strName = nil
    -- 状态
    if self.XFightLayer:CheckHasLock() then
        self.GameObject:SetActiveEx(false)
        return
    elseif self.XFightLayer:CheckHasPassed() then
        strName = string.format("<color=#FFC200>%sKM</color>", xFightLayer:GetId())
    else
        strName = string.format("<color=#72C3FF>%sKM</color>", xFightLayer:GetId())
    end
    self.TxtNum.text = strName
    self.GameObject:SetActiveEx(true)
end

return XUiGridRiftChapterOutliers