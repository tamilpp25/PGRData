local XUiButton = require("XUi/XUiCommon/XUiButton")

---@field _Control XReformControl
---@class XUiReform2ndPanelGroup:XUiNode
local XUiReform2ndPanelGroup = XClass(XUiNode, "XUiReform2ndPanelGroup")

function XUiReform2ndPanelGroup:OnStart(viewModel)
    ---@type XUiButtonLua[]
    self._BtnChapters = {}
    ---@type XViewModelReform2nd
    self.ViewModel = viewModel
    self.RedPointList = {}
    self:RegisterClickEvent()
    self.ViewModel:InitChapterList()
end

function XUiReform2ndPanelGroup:UpdateRedPoint()
    local totalNumber = self.ViewModel:GetChapterTotalNumber()

    local isSelectToggleHard = self._Control:GetViewModelList():IsSelectToggleHard()
    for i = 1, totalNumber do
        local button = self._BtnChapters[i]
        local chapter = self.ViewModel:GetChapterByIndex(i)
        button:ShowReddot(XMVCA.XReform:CheckChapterRedDifficulty(chapter, isSelectToggleHard))
    end
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

        local btn = CS.UnityEngine.Object.Instantiate(self.Btn1, self.Btn1.transform.parent)

        ---@type XUiComponent.XUiButton
        local button = btn:GetComponent("XUiButton")

        ---@type XUiButtonLua
        local uiButtonLua = XUiButton.New(button)

        self._BtnChapters[#self._BtnChapters + 1] = uiButtonLua
        btn.gameObject:SetActiveEx(true)

        XUiHelper.RegisterClickEvent(self, btn, function()
            self:OnBtnGridClick(i)
            self:CloseRedPoint(i)
            local isSelectToggleHard = self._Control:GetViewModelList():IsSelectToggleHard()
            XDataCenter.Reform2ndManager.SetChapterRedPointToLocal(chapterId, isSelectToggleHard)
        end)
        --XRedPointManager.CheckOnce(function(_, count)
        --    self._BtnChapters[i]:ShowReddot(count >= 0)
        --end, self, { XRedPointConditions.Types.CONDITION_REFORM_BASE_STAGE_OPEN }, chapter)

        local img, imgRed = self.ViewModel:GetChapterImageByIndex(i)
        button:SetRawImage(img)
        uiButtonLua:SetRawImage("Panel2/RImgDi", imgRed)
    end
    self.Btn1.gameObject:SetActiveEx(false)
end

function XUiReform2ndPanelGroup:RefreshBtnGrid()
    local viewModel = self.ViewModel
    local totalNumber = viewModel:GetChapterTotalNumber()
    local isSelectToggleHard = self._Control:GetViewModelList():IsSelectToggleHard()

    for i = 1, totalNumber do
        ---@type XReform2ndChapter
        local chapter = viewModel:GetChapterByIndex(i)
        local buttonLua = self._BtnChapters[i]
        local uiButton = buttonLua:GetUiButton()
        local isHasStageHard = self._Control:IsHasStageHard(chapter)
        local isUnlockStageHard = self._Control:IsChapterShowToggleHard(chapter)

        if isSelectToggleHard and not isHasStageHard then
            uiButton.gameObject:SetActive(false)
        else
            uiButton.gameObject:SetActive(true)
        end

        local isChapterFinish
        if isSelectToggleHard then
            isChapterFinish = self._Control:IsChapterStageFinished(chapter, true)
        else
            isChapterFinish = self._Control:IsChapterStageFinished(chapter, true)
                    or self._Control:IsChapterStageFinished(chapter, false)
        end
        --uiButton:ShowTag(isChapterFinish)
        local finish1 = uiButton.transform:Find("PanelBtn1/Finish1")
        local finish2 = uiButton.transform:Find("PanelBtn1/Finish2")
        if finish1 and finish2 then
            if isChapterFinish then
                if isSelectToggleHard then
                    finish1.gameObject:SetActiveEx(false)
                    finish2.gameObject:SetActiveEx(true)
                else
                    finish1.gameObject:SetActiveEx(true)
                    finish2.gameObject:SetActiveEx(false)
                end
            else
                finish1.gameObject:SetActiveEx(false)
                finish2.gameObject:SetActiveEx(false)
            end
        end

        uiButton:SetNameByGroup(0, self._Control:GetChapterName(chapter))
        uiButton:SetNameByGroup(1, self._Control:GetChapterStarDesc(chapter))--chapter:GetStarDesc(model)
        uiButton:SetNameByGroup(2, viewModel:GetChapterLockedTipByIndex(i))
        if isSelectToggleHard then
            if not isUnlockStageHard then
                uiButton:SetDisable(true)
            else
                uiButton:SetDisable(not viewModel:GetChapterIsUnlockedByIndex(i))
            end
        else
            uiButton:SetDisable(not viewModel:GetChapterIsUnlockedByIndex(i))
        end

        if isSelectToggleHard and isHasStageHard then
            buttonLua:SetActive("Panel1", false)
            buttonLua:SetActive("Panel2", true)
        else
            buttonLua:SetActive("Panel1", true)
            buttonLua:SetActive("Panel2", false)
        end
    end
    
    self:UpdateRedPoint()
end

function XUiReform2ndPanelGroup:OnBtnGridClick(index)
    local isUnlocked = self.ViewModel:GetChapterIsUnlockedByIndex(index)

    if isUnlocked then
        self.ViewModel:SetCurrentChapterIndex(index)
        self.Parent:OpenStagePanel()
    else
        XUiManager.TipMsg(self.ViewModel:GetChapterLockedTipByIndex(index))
    end
end

function XUiReform2ndPanelGroup:CloseRedPoint(index)
    self._BtnChapters[index]:ShowReddot(false)
end

function XUiReform2ndPanelGroup:GetBtnChapters()
    return self._BtnChapters
end

return XUiReform2ndPanelGroup
