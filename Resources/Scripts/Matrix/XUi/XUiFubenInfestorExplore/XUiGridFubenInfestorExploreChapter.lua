local XUiGridFubenInfestorExploreChapter = XClass(nil, "XUiGridFubenInfestorExploreChapter")

function XUiGridFubenInfestorExploreChapter:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnClickBtnClick() end
end

function XUiGridFubenInfestorExploreChapter:Refresh(chapterId)
    self.ChapterId = chapterId

    local isHard = XDataCenter.FubenInfestorExploreManager.IsChapterRequireIsomer(chapterId)
    local name = XFubenInfestorExploreConfigs.GetChapterName(chapterId)

    if XDataCenter.FubenInfestorExploreManager.IsChapterUnlock(chapterId) then
        local icon = XFubenInfestorExploreConfigs.GetChapterIcon(chapterId)
        self.RImgChapterIcon:SetRawImage(icon)

        self.TxtChapterName.text = name

        self.ImgHard.gameObject:SetActiveEx(isHard)
        self.ImgEasy.gameObject:SetActiveEx(not isHard)

        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelDisable.gameObject:SetActiveEx(false)
    else
        self.TxtChapterNameDis.text = name

        self.ImgHardDis.gameObject:SetActiveEx(isHard)
        self.ImgEasyDis.gameObject:SetActiveEx(not isHard)

        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelDisable.gameObject:SetActiveEx(true)
    end

    self.ImgClear.gameObject:SetActiveEx(XDataCenter.FubenInfestorExploreManager.IsChapterPassed(chapterId))
end

function XUiGridFubenInfestorExploreChapter:OnClickBtnClick()
    local chapterId = self.ChapterId
    if XDataCenter.FubenInfestorExploreManager.IsChapterUnlock(chapterId) then
        if XDataCenter.FubenInfestorExploreManager.IsChapterPassed(chapterId) then
            XLuaUiManager.Open("UiInfestorExploreStage", chapterId)
        else
            self.ClickCb()
        end
    else
        XUiManager.TipText("InfestorExploreChapterLockTip")
    end
end

return XUiGridFubenInfestorExploreChapter