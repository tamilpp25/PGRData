local XUiGridAssignChapter = XClass(nil, "XUiGridAssignChapter")

function XUiGridAssignChapter:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridAssignChapter:InitComponent()
    CsXUiHelper.RegisterClickEvent(self.BtnAssignChapter, function() self:OnBtnChapterClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnOccupy, function() self:OnBtnOccupyClick() end)

    self.NormalRed.gameObject:SetActiveEx(false)
    self.NormalBlue.gameObject:SetActiveEx(false)
    self.PressRed.gameObject:SetActiveEx(false)
    self.PressBlue.gameObject:SetActiveEx(false)
    self.RoleImg.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
end

function XUiGridAssignChapter:OnBtnChapterClick()
    if not self.ChapterData then
        return
    end

    XDataCenter.FubenAssignManager.SelectChapterId = self.ChapterData:GetId()
    XLuaUiManager.Open("UiPanelAssignStage")
end

function XUiGridAssignChapter:OnBtnOccupyClick()
    if not self.ChapterData then
        return
    end
    XDataCenter.FubenAssignManager.SelectChapterId = self.ChapterData:GetId()
    XDataCenter.FubenAssignManager.SelectCharacterId = self.ChapterData:GetCharacterId()
    XLuaUiManager.Open("UiAssignOccupy")
end

function XUiGridAssignChapter:Refresh(chapterId)
    local data = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    self.ChapterData = data

    local icon = data:GetIcon()
    self.RegionIcon:SetRawImage(icon)

    local progressStr = data:GetProgressStr()
    self.TxtCourseNormalBlue.text = progressStr
    self.TxtCourseNormalRed.text = progressStr
    self.TxtCoursePressBlue.text = progressStr
    self.TxtCoursePressRed.text = progressStr

    local chapterName = data:GetDesc()
    self.TxtChapterNameNormalBlue.text = chapterName
    self.TxtChapterNameNormalRed.text = chapterName
    self.TxtChapterNamePressBlue.text = chapterName
    self.TxtChapterNamePressRed.text = chapterName


    local isCurrentChapter = XDataCenter.FubenAssignManager.IsCurrentChapter(chapterId)

    self.NormalRed.gameObject:SetActiveEx(isCurrentChapter)
    self.NormalBlue.gameObject:SetActiveEx(not isCurrentChapter)
    self.PressRed.gameObject:SetActiveEx(isCurrentChapter)
    self.PressBlue.gameObject:SetActiveEx(not isCurrentChapter)

    local isCanAssign = data:CanAssign()
    if isCanAssign then
        self.BtnOccupy.gameObject:SetActiveEx(true)
        local isOccupy = data:IsOccupy()
        local occupyState = isOccupy and CS.UiButtonState.Select or CS.UiButtonState.Normal
        self.BtnOccupy:SetButtonState(occupyState)
        if isOccupy then
            local characterIcon = data:GetOccupyCharacterIcon()
            self.RoleImg.gameObject:SetActiveEx(true)
            self.RoleImg:SetRawImage(characterIcon)
        else
            self.RoleImg.gameObject:SetActiveEx(false)
        end
    else
        self.BtnOccupy.gameObject:SetActiveEx(false)
    end

    self.Red.gameObject:SetActiveEx(data:CanReward())
end

return XUiGridAssignChapter
