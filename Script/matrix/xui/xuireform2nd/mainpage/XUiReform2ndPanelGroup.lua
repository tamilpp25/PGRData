local XUiReform2ndPanelGroup = XClass(nil, "XUiReform2ndPanelGroup")

function XUiReform2ndPanelGroup:Ctor(rootUi, uiPrefab, viewModel)
    XTool.InitUiObjectByUi(self, uiPrefab)

    self.RootUi = rootUi
    ---@type XViewModelReform2nd
    self.ViewModel = viewModel
    self.RedPointList = {}
    self:RegisterClickEvent()
    self.ViewModel:InitChapterList()
end

function XUiReform2ndPanelGroup:SetViewModel(viewModel)
    self.ViewModel = viewModel
end

function XUiReform2ndPanelGroup:RegisterClickEvent()
    local totalNumber = self.ViewModel:GetChapterTotalNumber()

    for i = 1, totalNumber do
        local chapter = self.ViewModel:GetChapterByIndex(i)
        local preChapter = nil
        local chapterId = chapter:GetId()

        if i > 1 then
            preChapter = self.ViewModel:GetChapterByIndex(i - 1)
        end

        XUiHelper.RegisterClickEvent(self, self["Btn" .. i], function()
            self:OnBtnGridClick(i)
            self:CloseRedPoint(i)
            XDataCenter.Reform2ndManager.SetChapterRedPointToLocal(chapterId)
        end)
        XRedPointManager.CheckOnce(function(_, count)
            self["Btn" .. i]:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.CONDITION_REFORM_BASE_STAGE_OPEN }, { Chapter = chapter, PreChapter = preChapter })
    end
end

function XUiReform2ndPanelGroup:RefreshBtnGrid()
    local viewModel = self.ViewModel
    local totalNumber = viewModel:GetChapterTotalNumber()

    for i = 1, totalNumber do
        ---@type XReform2ndChapter
        local chapter = viewModel:GetChapterByIndex(i)
        local XUiButtonComponent = self["Btn" .. i]

        XUiButtonComponent:ShowTag(chapter:IsFinished())
        XUiButtonComponent:SetNameByGroup(0, chapter:GetName())
        XUiButtonComponent:SetNameByGroup(1, chapter:GetStarDesc())
        XUiButtonComponent:SetNameByGroup(2, viewModel:GetChapterLockedTipByIndex(i))
        XUiButtonComponent:SetDisable(not viewModel:GetChapterIsUnlockedByIndex(i))
    end
end

function XUiReform2ndPanelGroup:OnBtnGridClick(index)
    local isUnlocked = self.ViewModel:GetChapterIsUnlockedByIndex(index)

    if isUnlocked then
        self.ViewModel:SetCurrentChapterIndex(index)
        self.RootUi:OpenStagePanel()
    else
        XUiManager.TipMsg(self.ViewModel:GetChapterLockedTipByIndex(index))
    end
end

function XUiReform2ndPanelGroup:CloseRedPoint(index)
    self["Btn" .. index]:ShowReddot(false)
end

return XUiReform2ndPanelGroup
