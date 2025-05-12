local XUiReform2ndStagePanel = XClass(nil, "XUiReform2ndStagePanel")
local XUiReform2ndStage = require("XUi/XUiReform2nd/MainPage/XUiReform2ndStage")
local XUiReform2ndCharacterIcon = require("XUi/XUiReform2nd/MainPage/XUiReform2ndCharacterIcon")

function XUiReform2ndStagePanel:Ctor(rootUi, uiPrefab, viewModel)
    self.RootUi = rootUi
    ---@type XViewModelReform2nd
    self.ViewModel = viewModel
    ---@type XUiReform2ndStage[]
    self.StageList = {}
    self.Data = nil

    XTool.InitUiObjectByUi(self, uiPrefab)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClicked)

    self:Init()
end

function XUiReform2ndStagePanel:SetViewModel(viewModel)
    self.ViewModel = viewModel
end

function XUiReform2ndStagePanel:Init()
    local chapterData = self.ViewModel:GetChapterData()
    local stageIdLength = chapterData.StageIdLength

    for i = 1, stageIdLength do
        self.StageList[i] = XUiReform2ndStage.New(self, self["GridReformStage0" .. i])
        self.StageList[i]:SetData(self.ViewModel:GetStageDataByIndex(i))
    end
end

function XUiReform2ndStagePanel:RefreshDetailPanel()
    local chapterData = self.ViewModel:GetChapterData()
    local smallIconList = chapterData.RecommendCharacterList

    self.TxtTitle.text = chapterData.Name
    self.TxtTheme.text = chapterData.Theme
    self.TxtNumber.text = self.ViewModel:GetCurrStageNumberText()
    self.TxtTarget.text = chapterData.SpecialGoal
    XUiHelper.RefreshCustomizedList(self.CharacterContent, self.CharacterGrid, #smallIconList, function(index, obj)
        local gridCommont = XUiReform2ndCharacterIcon.New(obj)

        gridCommont:SetIcon(smallIconList[index])
    end)
end

function XUiReform2ndStagePanel:RefreshStageGrid()
    for i = 1, #self.StageList do
        self.StageList[i]:SetData(self.ViewModel:GetStageDataByIndex(i))
        self.StageList[i]:RefreshStage()
    end
end

function XUiReform2ndStagePanel:RefreshLockedStageGrid()
    for i = 1, #self.StageList do
        if not self.StageList[i]:GetIsUnlocked() then
            self.StageList[i]:SetData(self.ViewModel:GetStageDataByIndex(i))
            self.StageList[i]:RefreshStage()
        end
    end
end

function XUiReform2ndStagePanel:PlayAnim()
    self.RootUi:PlayAnimation("QieHuan")
end

function XUiReform2ndStagePanel:CheckStageTimeOpen()
    for i = 1, #self.StageList do
        if self.ViewModel:CheckStageTimeOpenByIndex(i) then
            return true
        end
    end
    
    return false
end

function XUiReform2ndStagePanel:OnBtnEnterClicked()
    local viewModel = self.ViewModel
    local isUnlock, tip = viewModel:IsSelectStageUnlocked()

    if not isUnlock then
        XUiManager.TipMsg(tip)

        return
    end

    local stage = viewModel:GetCurrentStage()
    viewModel:SaveIndexToManager()
    XLuaUiManager.Open("UiReformList", stage)
end

function XUiReform2ndStagePanel:OnStageGridClick(stageIndex)
    self.ViewModel:SetCurrentStageIndex(stageIndex)

    for i = 1, #self.StageList do
        self.StageList[i]:SetStageSelect(stageIndex == i)
        self.ViewModel:SetStageSelectByIndex(i)
    end

    self:RefreshDetailPanel()
    self:RefreshLockedStageGrid()
end

return XUiReform2ndStagePanel
