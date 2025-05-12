local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveStory = require("XUi/XUiArchive/XUiGridArchiveStory")
local XUiGridArchiveStoryDetail = XClass(XUiNode, "XUiGridArchiveStoryDetail")

function XUiGridArchiveStoryDetail:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveStoryDetail:SetButtonCallBack()
    self.BtnTanchuang.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveStoryDetail:OnBtnSelect()
    if self.Chapter:GetIsLock() then
        XUiManager.TipError(self.Chapter:GetLockDesc())
        return
    end
    self.Base:UpdateCurGridIndex(self.GridIndex)
    XLuaUiManager.Open("UiArchiveStoryDialog", self.Chapter)
end

function XUiGridArchiveStoryDetail:UpdateGrid(chapter, base, gridIndex)
    self.Base = base
    self.Chapter = chapter
    self.GridIndex = gridIndex
    self:SetMonsterData(chapter)
end

function XUiGridArchiveStoryDetail:SetMonsterData(chapter)
    local btnStatus = chapter:GetIsLock() and CS.UiButtonState.Disable or CS.UiButtonState.Normal
    self.BtnTanchuang:SetButtonState(btnStatus)
    self.ChapterTitle.text = chapter:GetName()
    if chapter:GetSubName() then
        self.ChapterTitleNum.text = string.gsub(chapter:GetSubName(), "_", "-")
    end

    self.ChapterTitleNum.gameObject:SetActiveEx(chapter:GetSubName() and #chapter:GetSubName() > 0)
end

return XUiGridArchiveStoryDetail