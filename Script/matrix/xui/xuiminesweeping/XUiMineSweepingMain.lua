local XUiMineSweepingMain = XLuaUiManager.Register(XLuaUi, "UiMineSweepingMain")

local XUiPanelAllGrid = require("XUi/XUiMineSweeping/XUiPanelAllGrid")
local XUiPanelCondition = require("XUi/XUiMineSweeping/XUiPanelCondition")
local XUiPanelPlay = require("XUi/XUiMineSweeping/XUiPanelPlay")
local XUiPanelSequence = require("XUi/XUiMineSweeping/XUiPanelSequence")
local XUiPanelSequenceWin = require("XUi/XUiMineSweeping/XUiPanelSequenceWin")
local XUiPanelSettlement = require("XUi/XUiMineSweeping/XUiPanelSettlement")
local XUiPanelStart = require("XUi/XUiMineSweeping/XUiPanelStart")
local CSTextManagerGetText = CS.XTextManager.GetText
local Disable = CS.UiButtonState.Disable
local Normal = CS.UiButtonState.Normal
function XUiMineSweepingMain:OnStart()
    self:SetButtonCallBack()
    self:Init()
end

function XUiMineSweepingMain:OnDestroy()
    
end

function XUiMineSweepingMain:OnEnable()
    self:CheckTime()
    self:CreatrTimer()
    self:CheckHitFaceHelp()
    self:UpdatePanel()
    
    XEventManager.AddEventListener(XEventId.EVENT_MINESWEEPING_STAGESTART, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MINESWEEPING_GRIDOPEN, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_MINESWEEPING_STORYPLAY, self.ShowRed, self)
end

function XUiMineSweepingMain:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer) 
    end
    if self.AllGridPanel:ResetEffect() then
        XLuaUiManager.SetMask(false)
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_MINESWEEPING_STAGESTART, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MINESWEEPING_GRIDOPEN, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MINESWEEPING_STORYPLAY, self.ShowRed, self)
end

function XUiMineSweepingMain:Init()
    self.SpecialState = {}
    
    self.AllGridPanel = XUiPanelAllGrid.New(self.PanelAllGrid, self)
    self.ConditionPanel = XUiPanelCondition.New(self.PanelCondition, self)
    self.PlayPanel = XUiPanelPlay.New(self.PanelPlay, self)
    self.SequencePanel = XUiPanelSequence.New(self.PanelSequence, self)
    self.SequenceWinPanel = XUiPanelSequenceWin.New(self.PanelSequenceWin, self)
    self.SettlementPanel = XUiPanelSettlement.New(self.PanelSettlement, self)
    self.StartPanel = XUiPanelStart.New(self.PanelStart, self)
     
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self)
    local itemId = XDataCenter.MineSweepingManager.GetMineSweepingCoinItemId()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
            self.AssetActivityPanel:Refresh({ itemId })
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({ itemId })
    self:InitChapterBtnGroup()
end

function XUiMineSweepingMain:CreatrTimer()
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function()
                self:CheckTime()
            end, XScheduleManager.SECOND , 0)
    end
end

function XUiMineSweepingMain:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    
    self:BindHelpBtn(self.BtnHelp, "MineSweepingGame")
end

function XUiMineSweepingMain:OnBtnBackClick()
    self:Close()
end

function XUiMineSweepingMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMineSweepingMain:InitChapterBtnGroup()
    local btnObj = self.PanelTag:GetObject("BtnTog")
    local btnGroup = self.PanelTag:GetObject("ChapterGroup")
    local index = XDataCenter.MineSweepingManager.GetNewChapterIndex()
    self.CurCharterIndex = index
    
    btnObj.gameObject:SetActiveEx(false)
    self.CharterBtnList = {}

    local chapterIds = XDataCenter.MineSweepingManager.GetChapterIds()
    
    for chapterIndex,_ in pairs(chapterIds) do
        local btn = CS.UnityEngine.Object.Instantiate(btnObj)
        btn.gameObject:SetActiveEx(true)
        btn.transform:SetParent(btnGroup.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(chapterIndex)
        local name = chapterEntity:GetName() or ""
        local nameEn = chapterEntity:GetNameEn() or ""
        btncs:SetNameByGroup(0, name)
        btncs:SetNameByGroup(1, nameEn)
        btncs:SetDisable(chapterEntity:IsLock())
        table.insert(self.CharterBtnList, btncs)
        self.SpecialState[chapterIndex] = XMineSweepingConfigs.SpecialState.None
    end
    btnGroup:Init(self.CharterBtnList, function(index) self:SelectTag(index) end)
    self.OldIndex = index
    if XTool.IsNumberValid(index) then
        btnGroup:SelectIndex(index)
    end
end

function XUiMineSweepingMain:SelectTag(index)
    if self.CharterBtnList[index].ButtonState == Disable then
        XUiManager.TipText("MineChapterLockHint")
        return
    end
    self.OldIndex = self.CurCharterIndex
    self.CurCharterIndex = index
    self:RetSetSpecialState(self.OldIndex)
    self:UpdatePanel()
    self.OldIndex = self.CurCharterIndex
end

function XUiMineSweepingMain:UpdatePanel()
    self:UpdateChapterBtnGroup()
    if not XTool.IsNumberValid(self.CurCharterIndex) then
        return
    end
    
    self.ConditionPanel:UpdatePanel(self.CurCharterIndex)
    self.StartPanel:UpdatePanel(self.CurCharterIndex)
    self.AllGridPanel:UpdatePanel(self.CurCharterIndex)
    self.SettlementPanel:UpdatePanel()
    self.SequenceWinPanel:UpdatePanel(self.CurCharterIndex)
    self.PlayPanel:UpdatePanel(self.CurCharterIndex)
    self.SequencePanel:UpdatePanel(self.CurCharterIndex)
    self:PanelShow()
    self:ShowRed()
end

function XUiMineSweepingMain:PanelShow()
    local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(self.CurCharterIndex)
    self.ConditionPanel:ShowPanel(chapterEntity:IsSweeping() and self:IsSpecialStateNone())
    self.StartPanel:ShowPanel((chapterEntity:IsPrepare() or chapterEntity:IsFailed()) and self:IsSpecialStateNone())
    self.AllGridPanel:ShowPanel(chapterEntity:IsSweeping() or self:IsSpecialStateStageWin() or self:IsSpecialStateChapterWin())
    self.SettlementPanel:ShowPanel(self:IsSpecialStateStageWin() or self:IsSpecialStateStageLose())
    self.SequenceWinPanel:ShowPanel(false)
    self.PlayPanel:ShowPanel(chapterEntity:IsFinish() and self:IsSpecialStateNone())
end

function XUiMineSweepingMain:UpdateChapterBtnGroup()
    for index,btn in pairs(self.CharterBtnList) do
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(index)
        if chapterEntity:IsLock() then
            btn:SetButtonState(Disable)
        else
            if btn.ButtonState == Disable then
                btn:SetButtonState(Normal)
            end
        end
    end
end

function XUiMineSweepingMain:CheckHitFaceHelp()
    local IsShowHelp = XDataCenter.MineSweepingManager.CheckShowHelp()
    if IsShowHelp then
        XUiManager.ShowHelpTip("MineSweepingGame")
    end
end

function XUiMineSweepingMain:CheckTime()
    self.TimeLeft = XDataCenter.MineSweepingManager.GetMineSweepingTimeLeft()
    self.PanelTitle:GetObject("TimeText").text = XUiHelper.GetTime(self.TimeLeft, XUiHelper.TimeFormatType.ACTIVITY)
    
    if self.TimeLeft <= 0 then
        XUiManager.TipText("MineSweepingOverTimeHint")
        self:OnBtnMainUiClick() 
    end
end

function XUiMineSweepingMain:SetSpecialState(state, chapterId, stageId)
    self.SpecialState[self.CurCharterIndex] = state
    self.SpecialStateChapterId = chapterId
    self.SpecialStateStageId = stageId
    
    self:UpdatePanel()
end

function XUiMineSweepingMain:RetSetSpecialState(index)
    self.SpecialState[index] = XMineSweepingConfigs.SpecialState.None
end

function XUiMineSweepingMain:IsChapterIndexChange()
    return self.CurCharterIndex ~= self.OldIndex
end

function XUiMineSweepingMain:IsSpecialStateNone()
    return self.SpecialState[self.CurCharterIndex] == XMineSweepingConfigs.SpecialState.None
end

function XUiMineSweepingMain:IsSpecialStateStageWin()
    return self.SpecialState[self.CurCharterIndex] == XMineSweepingConfigs.SpecialState.StageWin
end

function XUiMineSweepingMain:IsSpecialStateStageLose()
    return self.SpecialState[self.CurCharterIndex] == XMineSweepingConfigs.SpecialState.StageLose
end

function XUiMineSweepingMain:IsSpecialStateChapterWin()
    return self.SpecialState[self.CurCharterIndex] == XMineSweepingConfigs.SpecialState.ChapterWin
end

function XUiMineSweepingMain:GetSpecialStateStageId()
    return self.SpecialStateStageId
end

function XUiMineSweepingMain:GetSpecialStateChapterId()
    return self.SpecialStateChapterId
end

function XUiMineSweepingMain:ShowStageWinEffect()
    local IsFirst = false
    XLuaUiManager.SetMask(true)
    self.AllGridPanel:ShowEffect(function ()
            if not IsFirst then
                self.SequencePanel:CheckPlayGridAnime()
                IsFirst = true
                XLuaUiManager.SetMask(false)
            end
        end)
end

function XUiMineSweepingMain:SetFinishReward(rewardGoodsList)
    self.RewardGoodsList = rewardGoodsList
end

function XUiMineSweepingMain:ShowFinishReward()
    if self.RewardGoodsList and next(self.RewardGoodsList) then
        XUiManager.OpenUiObtain(self.RewardGoodsList, nil, function ()
                if self:IsSpecialStateStageWin() then
                    self.SettlementPanel:ShowWinPanel()
                end
                if self:IsSpecialStateChapterWin() then
                    self.SequenceWinPanel:ShowPanel(true)
                end
        end)
        self.RewardGoodsList = nil
    end
end

function XUiMineSweepingMain:ShowRed()
    local chapterIds = XDataCenter.MineSweepingManager.GetChapterIds()
    for index, id in pairs(chapterIds) do
        local IsShow = XDataCenter.MineSweepingManager.CheckHaveRedByChapterId(id)
        self.CharterBtnList[index]:ShowReddot(IsShow)
    end
end

