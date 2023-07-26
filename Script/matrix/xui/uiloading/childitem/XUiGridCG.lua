local XUiGridCG = XClass(nil, "XUiGridCG")
local Rect = CS.UnityEngine.Rect(1, 1, 1, 1)
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")
local LockCGIconAspectRatio = CS.XGame.ClientConfig:GetFloat("LockStoryIconAspectRatio")

function XUiGridCG:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiGridCG:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridCG:CheckSelectable()
    if self.Chapter:GetIsLock() then
        XUiManager.TipError(self.Chapter:GetLockDesc())
        return false
    end
    return true
end

function XUiGridCG:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

function XUiGridCG:UpdateCg(chapter)
    if self.Chapter == chapter then return end
    self.Chapter = chapter
    self.GridCG.gameObject:SetActiveEx(chapter)
    if self.PanelAdd then
        self.PanelAdd.gameObject:SetActiveEx(not chapter)
    end
    if not chapter then return end

    if chapter:GetIsLock() then
        if chapter:GetLockBg() and #chapter:GetLockBg() > 0 then
            self.CGImg:SetRawImage(chapter:GetLockBg())
        end
        self.CGTitle.text = LockNameText
        Rect.x = 0
        Rect.y = 0
        self.CGImg.uvRect = Rect
        self.CGImgAspect.aspectRatio = LockCGIconAspectRatio
        self.PanelLabelDynamic.gameObject:SetActiveEx(false)
    else
        local spineBg = chapter:GetSpineBg()
        if XLoadingConfig.GetCustomUseSpine() and not string.IsNilOrEmpty(spineBg) then
            self.PanelLabelDynamic.gameObject:SetActiveEx(true)
        else
            self.PanelLabelDynamic.gameObject:SetActiveEx(false)
        end
        if chapter:GetBg() and #chapter:GetBg() > 0 then
            self.CGImg:SetRawImage(chapter:GetBg())
        end
        self.CGTitle.text = chapter:GetName()
        Rect.x = chapter:GetBgOffSetX() / 100
        Rect.y = chapter:GetBgOffSetY() / 100
        self.CGImg.uvRect = Rect
        local width = chapter:GetBgWidth() ~= 0 and chapter:GetBgWidth() or 1
        local high = chapter:GetBgHigh() ~= 0 and chapter:GetBgHigh() or 1
        self.CGImgAspect.aspectRatio = width / high
    end
end

return XUiGridCG