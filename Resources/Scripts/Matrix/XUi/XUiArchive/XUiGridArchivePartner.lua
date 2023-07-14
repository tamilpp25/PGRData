local XUiGridArchivePartner = XClass(nil, "XUiGridArchivePartner")

local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")

function XUiGridArchivePartner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridArchivePartner:SetButtonCallBack()
    self.TemplateBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchivePartner:OnBtnSelect()
    if self.Chapter:GetIsArchiveLock() then
        XUiManager.TipText("ArchivePartnerLock")
        return
    end
    XLuaUiManager.Open("UiArchivePartnerDetail", self.ChapterList, self.CurIndex)
end

function XUiGridArchivePartner:UpdateGrid(chapterList, index)
    if chapterList and chapterList[index] then
        self.Chapter = chapterList[index]
        self.ChapterList = chapterList
        self:SetMonsterData(self.Chapter)
    end
    self.CurIndex = index
end

function XUiGridArchivePartner:SetMonsterData(chapter)
    if chapter:GetIsArchiveLock() then
        self.PartnerName.text = LockNameText
        if chapter:GetLockIcon() and #chapter:GetLockIcon() > 0 then
            self.PartnerImg:SetRawImage(chapter:GetLockIcon())
        end
    else
        self.PartnerName.text = chapter:GetOriginalName()
        if chapter:GetIcon() and #chapter:GetIcon() > 0 then
            self.PartnerImg:SetRawImage(chapter:GetIcon())
        end
    end
end

return XUiGridArchivePartner
