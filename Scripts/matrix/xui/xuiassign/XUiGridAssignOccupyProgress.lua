local XUiGridAssignOccupyProgress = XClass(nil, "XUiGridAssignOccupyProgress")

function XUiGridAssignOccupyProgress:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.Button, self.OnButtonClick)
end

function XUiGridAssignOccupyProgress:Refresh(chapterId)
    self.ChapterId = chapterId
    self.ChapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    self.TxtName.text = self.ChapterData:GetDesc()

    local chapterData = self.ChapterData
    local isOccupy = chapterData:IsOccupy()
    local isCanAssign = chapterData:CanAssign()
    local buffList = chapterData:GetBuffDescList()

    self.TxtBuff.text = buffList[1]
    self.PanelNormal.gameObject:SetActiveEx(isOccupy)
    self.PanelPlus.gameObject:SetActiveEx(isCanAssign and not isOccupy)
    self.PanelLock.gameObject:SetActiveEx(not isCanAssign)

    if isOccupy then
        self.RImgRole:SetRawImage(chapterData:GetOccupyCharSmallHeadIcon()) 
        self.ImgSkill:SetRawImage(chapterData:GetSkillIcon())
    end
end

function XUiGridAssignOccupyProgress:OnButtonClick()
    if not self.ChapterData:CanAssign() then
        return
    end

    XLuaUiManager.Open("UiAssignOccupy", self.ChapterId)
end

return XUiGridAssignOccupyProgress