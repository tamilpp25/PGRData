local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntChapterGrid
local XUiDlcHuntChapterGrid = XClass(nil, "XUiDlcHuntChapterGrid")

function XUiDlcHuntChapterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntChapterGrid:GetButton()
    return self.Transform:GetComponent("XUiButton")
end

---@param chapter XDlcHuntChapter
function XUiDlcHuntChapterGrid:Update(chapter)
    local button = self:GetButton()
    button:SetRawImage(chapter:GetIcon())

    if chapter:IsUnlock() then
        button:SetButtonState(CS.UiButtonState.Normal)
    else
        button:SetButtonState(CS.UiButtonState.Disable)
    end

    --region name
    local textName1 = XUiHelper.TryGetComponent(self.Transform, "Normal/TxtName", "Text")
    textName1.text = chapter:GetName()

    local textName2 = XUiHelper.TryGetComponent(self.Transform, "Press/TxtName", "Text")
    textName2.text = chapter:GetName()

    local textName3 = XUiHelper.TryGetComponent(self.Transform, "Select/TxtName", "Text")
    textName3.text = chapter:GetName()

    local textName4 = XUiHelper.TryGetComponent(self.Transform, "Disable/TxtName", "Text")
    textName4.text = chapter:GetName()
    --endregion name

    --region progress
    local progress = chapter:GetProgress()
    local maxProgress = chapter:GetMaxProgress()
    local textProgress1 = XUiHelper.TryGetComponent(self.Transform, "Normal/TxtPace", "Text")
    self:SetTextProgress(textProgress1, progress, maxProgress)

    local textProgress2 = XUiHelper.TryGetComponent(self.Transform, "Press/TxtPace", "Text")
    self:SetTextProgress(textProgress2, progress, maxProgress)

    local textProgress3 = XUiHelper.TryGetComponent(self.Transform, "Select/TxtPace", "Text")
    self:SetTextProgress(textProgress3, progress, maxProgress)
    
    local textProgress4 = XUiHelper.TryGetComponent(self.Transform, "Disable/TxtPace", "Text")
    self:SetTextProgress(textProgress4, progress, maxProgress)
    --endregion progress

    --region index
    local index = chapter:GetIndex()
    local textIndex1 = XUiHelper.TryGetComponent(self.Transform, "Normal/GridNum/TxtNum", "Text")
    self:SetTextIndex(textIndex1, index)

    local textIndex2 = XUiHelper.TryGetComponent(self.Transform, "Press/GridNum/TxtNum", "Text")
    self:SetTextIndex(textIndex2, index)

    local textIndex3 = XUiHelper.TryGetComponent(self.Transform, "Select/GridNum/TxtNum", "Text")
    self:SetTextIndex(textIndex3, index)

    local textIndex4 = XUiHelper.TryGetComponent(self.Transform, "Disable/GridNum/TxtNum", "Text")
    self:SetTextIndex(textIndex4, index)
    --endregion index
end

function XUiDlcHuntChapterGrid:SetTextProgress(uiText, progress, maxProgress)
    local str = string.format("%d/%d", progress, maxProgress)
    uiText.text = string.gsub(uiText.text, "%d/%d", str)
end

function XUiDlcHuntChapterGrid:SetTextIndex(uiText, index)
    XUiDlcHuntUtil.SetTextIndex(uiText, index)
end

return XUiDlcHuntChapterGrid
