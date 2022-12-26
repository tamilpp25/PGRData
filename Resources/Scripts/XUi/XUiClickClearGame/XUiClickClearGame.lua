local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiClickClearPanelGeneral = require("XUi/XUiClickClearGame/XUiClickClearPanelGeneral")
local XUiClickClearPanelGame = require("XUi/XUiClickClearGame/XUiClickClearPanelGame")
local XUiClickClearPanelCountdown = require("XUi/XUiClickClearGame/XUiClickClearPanelCountdown")

local FirstInGameStage = {
    First = 1,
    NotFirst = 2,
}

local XUiClickClearGame = XLuaUiManager.Register(XLuaUi, "UiClickClearGame")

function XUiClickClearGame:OnAwake()
    self.GeneralPanel = XUiClickClearPanelGeneral.New(self.PanelGeneral.gameObject, self)
    self.GamePanel = XUiClickClearPanelGame.New(self.PanelGame.gameObject, self)
    self.CountdownPanel = XUiClickClearPanelCountdown.New(self.PanelCountdown.gameObject, self)
end

function XUiClickClearGame:OnStart()
    self:AutoRegisterBtnListener()
    self:InitBtnGroup()
end

function XUiClickClearGame:OnEnable()
    local bool, remineDaysStr = XDataCenter.XClickClearGameManager.GetRemainDaysStr()
    if bool then
        self.TextRemainDays.text = remineDaysStr
    else
        self.TextRemainDays.text = CSXTextManagerGetText("EquipFunctionNotOpen")
    end

    XDataCenter.XClickClearGameManager.ResetGame()
    self:ResetUi()
    self:CheckHitFace()

    XRedPointManager.AddRedPointEvent(self.BtnTabSimple, self.OnCheckSimpleOpen, self, { XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_DIFFICULT_UNLOCK }, XDataCenter.XClickClearGameManager.GameDifficultys.Simple, true)
    XRedPointManager.AddRedPointEvent(self.BtnTabComplex, self.OnCheckComplexOpen, self, { XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_DIFFICULT_UNLOCK }, XDataCenter.XClickClearGameManager.GameDifficultys.Complex, true)
    XRedPointManager.AddRedPointEvent(self.BtnTabDifficult, self.OnCheckDifficultOpen, self, { XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_DIFFICULT_UNLOCK }, XDataCenter.XClickClearGameManager.GameDifficultys.Difficult, true)
    XRedPointManager.AddRedPointEvent(self.BtnTabHell, self.OnCheckHellOpen, self, { XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_DIFFICULT_UNLOCK }, XDataCenter.XClickClearGameManager.GameDifficultys.Hell, true)
    XRedPointManager.AddRedPointEvent(self.BtnTreasure, self.OnCheckRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_CLICKCLEARGAME_REWARD }, nil, true)
end

function XUiClickClearGame:OnDisable()
    
end

function XUiClickClearGame:OnDestroy()
    
end

function XUiClickClearGame:OnGetEvents()
    return {
        XEventId.EVENT_CLICKCLEARGAME_INIT_COMPLETE,
        XEventId.EVENT_CLICKCLEARGAME_GAME_ACCOUNT,
        XEventId.EVENT_CLICKCLEARGAME_HEAD_COUNT_CHANGED,
        XEventId.EVENT_CLICKCLEARGAME_GAME_PLAYING,
        XEventId.EVENT_CLICKCLEARGAME_GAME_PAUSE,
        XEventId.EVENT_CLICKCLEARGAME_GAME_RESET,
        XEventId.EVENT_CLICKCLEARGAME_GAME_PAGE_CHANGED,
        XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD,
    }
end

function XUiClickClearGame:OnNotify(evt, ...)
    if evt == XEventId.EVENT_CLICKCLEARGAME_INIT_COMPLETE then
        self:GameInitCompleteCallBack()
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_GAME_ACCOUNT then
        self:GameAccountCallBack(...)
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_HEAD_COUNT_CHANGED then
        self.GamePanel.TaskPanel:HeadDataHasChanged()
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_GAME_PLAYING then
        self.CountdownPanel:OnGamePlaying()
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_GAME_PAUSE then
        self.CountdownPanel:OnGamePause(...)
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_GAME_RESET then
        self:GameResetCallBack()
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_GAME_PAGE_CHANGED then
        self.GamePanel.BookMarkPanel:RefreshBookMark()
    elseif evt == XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD then
        self:RefreshUiReward()
    end
end

function XUiClickClearGame:OnCheckSimpleOpen(count)
    self.BtnTabSimple:ShowReddot(count>=0)
end

function XUiClickClearGame:OnCheckComplexOpen(count)
    self.BtnTabComplex:ShowReddot(count>=0)
end

function XUiClickClearGame:OnCheckDifficultOpen(count)
    self.BtnTabDifficult:ShowReddot(count>=0)
end

function XUiClickClearGame:OnCheckHellOpen(count)
    self.BtnTabHell:ShowReddot(count>=0)
end

function XUiClickClearGame:OnCheckRewardRedPoint(count)
    self.BtnTreasure:ShowReddot(count>=0)
end

function XUiClickClearGame:AutoRegisterBtnListener()
    self.BtnBack.CallBack = function () self.OnBtnBackClick() end
    self.BtnMainUi.CallBack = function () self.OnBtnMainClick() end
    self.BtnHelp.CallBack = function () self.OnBtnHelpClick() end
    self:BindHelpBtnOnly(self.BtnHelp)
    self.BtnTreasure.CallBack = function () self:OnBtnTreasureClick() end
end

function XUiClickClearGame.OnBtnBackClick()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    if gameInfo.CurGameState ~= XDataCenter.XClickClearGameManager.GameState.Playing then
        XLuaUiManager.Close("UiClickClearGame")
        return
    end

    XDataCenter.XClickClearGameManager.SetGameStatePause()
    XLuaUiManager.Open("UiDialog", "", CSXTextManagerGetText("ClickClearGameOutHint"), XUiManager.DialogType.Normal, function()
        XDataCenter.XClickClearGameManager.SetGameStatePlaying() end, function()
            XLuaUiManager.Close("UiClickClearGame") end)
end

function XUiClickClearGame.OnBtnMainClick()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    if gameInfo.CurGameState ~= XDataCenter.XClickClearGameManager.GameState.Playing then
        XLuaUiManager.RunMain()
        return
    end

    XDataCenter.XClickClearGameManager.SetGameStatePause()
    XLuaUiManager.Open("UiDialog", "", CSXTextManagerGetText("ClickClearGameOutHint"), XUiManager.DialogType.Normal, function()
        XDataCenter.XClickClearGameManager.SetGameStatePlaying() end, function()
            XLuaUiManager.RunMain() end)
end

function XUiClickClearGame.OnBtnHelpClick()
    local helpId = XDataCenter.XClickClearGameManager.GetHelpId()
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)

    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    if gameInfo.CurGameState == XDataCenter.XClickClearGameManager.GameState.Playing then
        XDataCenter.XClickClearGameManager.SetGameStatePause()
        XUiManager.ShowHelpTip(template.Function, function () XDataCenter.XClickClearGameManager.SetGameStatePlaying() end)
        return
    end

    XUiManager.ShowHelpTip(template.Function)
end

function XUiClickClearGame:OnBtnTreasureClick()
    self:OpenOneChildUi("UiClickClearReward", self)
end

function XUiClickClearGame:ResetUi()
    self.GamePanel:Hide()
    self.GeneralPanel:Hide()
    self.CountdownPanel:Hide()
    self.CoverAllPanel.gameObject:SetActiveEx(false)

    local curDifficulty = XDataCenter.XClickClearGameManager.GetCurGameDifficulty()
    if curDifficulty then
        self.DifficultyBtnGroup:SelectIndex(curDifficulty)
    else
        self.DifficultyBtnGroup:SelectIndex(XDataCenter.XClickClearGameManager.GameDifficultys.Simple)
    end
    self:RefreshBtnGroup()
    self:RefreshUiReward()
end

function XUiClickClearGame:RefreshUiReward()
    local rewardCount = XDataCenter.XClickClearGameManager.GetRewardCount()
    local rewardCanTakedCount = XDataCenter.XClickClearGameManager.GetRewardCanTakeCount()
    local rewardTakedCount = XDataCenter.XClickClearGameManager.GetRewardTakedCount()
    self.ImgJindu.fillAmount = rewardCanTakedCount/rewardCount
    self.TxtSinglePlayerFinishNum.text = CSXTextManagerGetText("ClickClearGameRewardProcess", rewardCanTakedCount, rewardCount)
    if rewardTakedCount == rewardCount then
        self.ImgLingqu.gameObject:SetActiveEx(true)
    else
        self.ImgLingqu.gameObject:SetActiveEx(false)
    end
end

function XUiClickClearGame:GameInitCompleteCallBack()
    self:ChangeCover(true) -- 打开难度按钮遮罩
    self.CoverAllPanel.gameObject:SetActiveEx(false)
    self.GeneralPanel:Hide()
    self.GamePanel:Show()
    self.CountdownPanel:Show()

    XDataCenter.XClickClearGameManager.SetGameStatePlaying()
end

function XUiClickClearGame:GameAccountCallBack(isWin)
    self.CountdownPanel:Hide()
    if isWin then
        self.GeneralPanel:Show(XDataCenter.XClickClearGameManager.GeneralPanelStates.Clearance)
    else
        self.GeneralPanel:Show(XDataCenter.XClickClearGameManager.GeneralPanelStates.Failure)
    end
    self.CoverAllPanel.gameObject:SetActiveEx(true)
    self:ChangeCover(false)
    self:RefreshBtnGroup()
    self:RefreshUiReward()
end

function XUiClickClearGame:GameResetCallBack()
    self:ChangeCover(false)
    self:ResetUi()
end

function XUiClickClearGame:InitBtnGroup()
    self.TabList = {
        self.BtnTabSimple,
        self.BtnTabComplex,
        self.BtnTabDifficult,
        self.BtnTabHell,
    }
    self.DifficultyBtnGroup:Init(self.TabList, function(index) self:OnSelectTabBtn(index) end)
    self:RefreshBtnGroup()
end

function XUiClickClearGame:RefreshBtnGroup()
    for i,v in ipairs(self.TabList) do
        local btnName, btnNameEn = XDataCenter.XClickClearGameManager.GetStageTagNameAndNameEnById(i)
        v:SetNameByGroup(0, btnName)
        v:SetNameByGroup(1, btnNameEn)
        local isOpen = XDataCenter.XClickClearGameManager.CheckTabBtnByLastDifficult(i)
        v:SetDisable(not isOpen)
    end
end

function XUiClickClearGame:OnSelectTabBtn(index)
    self.TabList[index]:ShowReddot(false) -- 取消红点显示
    XDataCenter.XClickClearGameManager.SetTakeDifficultyBtnRedPoint(index, true)
    
    self.GamePanel:Hide()
    self.CountdownPanel:Hide()
    local isOpen = XDataCenter.XClickClearGameManager.CheckTabBtnByLastDifficult(index)
    if isOpen then
        XDataCenter.XClickClearGameManager.ResetData()
        XDataCenter.XClickClearGameManager.SetCurGameDifficulty(index)
        self.CoverAllPanel.gameObject:SetActiveEx(false)
        self.GeneralPanel:Show(XDataCenter.XClickClearGameManager.GeneralPanelStates.Default)
    else
        local tipText = CSXTextManagerGetText("ClickClearGameUnlock"..(index-1))
        XUiManager.TipError(tipText)
    end
end

function XUiClickClearGame:ChangeCover(isCover)
    self.CoverPanel.gameObject:SetActiveEx(isCover)
end

function XUiClickClearGame:CheckHitFace()
    local firstInGameStage = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "IsFirstInClickClearGame"))
    if firstInGameStage and firstInGameStage == FirstInGameStage.NotFirst then
        return
    end

    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "IsFirstInClickClearGame"), FirstInGameStage.NotFirst)
    self.OnBtnHelpClick()
end