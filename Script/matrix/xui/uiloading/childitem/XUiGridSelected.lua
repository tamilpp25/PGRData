local XUiGridCG = XClass(nil, "XUiGridCG")
local Rect = CS.UnityEngine.Rect(1, 1, 1, 1)

function XUiGridCG:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridCG:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridCG:UpdateCg(chapter)
    if self.Chapter == chapter then return end
    self.Chapter = chapter

    self.CGImg.gameObject:SetActiveEx(chapter)
    self.PanelRemove.gameObject:SetActiveEx(chapter)
    self.PanelNone.gameObject:SetActiveEx(not chapter)

    if not chapter then return end

    if chapter:GetBg() and #chapter:GetBg() > 0 then
        self.CGImg:SetRawImage(chapter:GetBg())
    end
    Rect.x = chapter:GetBgOffSetX() / 100
    Rect.y = chapter:GetBgOffSetY() / 100
    self.CGImg.uvRect = Rect
    local width = chapter:GetBgWidth() ~= 0 and chapter:GetBgWidth() or 1
    local high = chapter:GetBgHigh() ~= 0 and chapter:GetBgHigh() or 1
    self.CGImgAspect.aspectRatio = width / high
end

return XUiGridCG