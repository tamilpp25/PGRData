XUiGridArchiveStoryDetail = XClass(nil, "XUiGridArchiveStoryDetail")

function XUiGridArchiveStoryDetail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
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
    XLuaUiManager.Open("UiArchiveStoryDialog", self.Chapter)
end

function XUiGridArchiveStoryDetail:UpdateGrid(chapter, base)
    self.Base = base
    self.Chapter = chapter
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