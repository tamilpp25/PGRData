local XUiFubenPokerGuessing = XLuaUiManager.Register(XLuaUi,"UiFubenPokerGuessing")

function XUiFubenPokerGuessing:OnStart()
    self.PokerGuessing = XDataCenter.PokerGuessingManager.GetPokerGuessingData()
    self.IsFirstEnter = true
    self:RegisterButtonEvent()
    self:InitUiView()
    self:UpdateGameState()
    self.PanelTips.gameObject:SetActiveEx(false)
    self.BtnBig.ButtonType = CS.UiButtonType.Toggle
    self.BtnSmall.ButtonType = CS.UiButtonType.Toggle
    self.ItemIds = { XDataCenter.ItemManager.ItemId.PokerGuessingItemId }

    local endTime = XDataCenter.PokerGuessingManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.PokerGuessingManager.OnActivityEnd()
            return
end
        self.TxtTime.text = XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.ACTIVITY)
    end)
end

function XUiFubenPokerGuessing:OnEnable()
    self:UpdateScore()
    self.AssetActivityPanel:Refresh(self.ItemIds)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnCheckRedPoint, self)
    self:UpdateView()
end

function XUiFubenPokerGuessing:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnCheckRedPoint, self)
end

function XUiFubenPokerGuessing:OnGetEvents()
    return {
        XEventId.EVENT_POKER_GUESSING_UPDATE_SCORE,
        XEventId.EVENT_POKER_GUESSING_UPDATE_RESULT,
        XEventId.EVENT_POKER_GUESSING_UPDATE_STATE,
        XEventId.EVENT_POKER_GUESSING_ACTIVITY_END,
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiFubenPokerGuessing:OnNotify(event, ... )
    if event == XEventId.EVENT_POKER_GUESSING_UPDATE_STATE then
        self:UpdateGameState()
        self:UpdateScore()
    elseif event == XEventId.EVENT_POKER_GUESSING_UPDATE_RESULT then
    elseif event == XEventId.EVENT_POKER_GUESSING_UPDATE_SCORE then
    elseif event == XEventId.EVENT_POKER_GUESSING_ACTIVITY_END then
        XUiManager.TipText("PokerGuessingActivityEnd")
        XLuaUiManager.RunMain()
    elseif event == XEventId.EVENT_FINISH_TASK or
    event == XEventId.EVENT_TASK_SYNC then
        self:OnCheckRedPoint()
    end
end

function XUiFubenPokerGuessing:InitUiView()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PokerGuessingItemId, function()
        self.AssetActivityPanel:Refresh(self.ItemIds)
        self:OnCheckRedPoint()
        XDataCenter.PokerGuessingManager.MarkUnlockItemChange()
    end, self.AssetActivityPanel)
    --XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.Coin, function()
    --    self.AssetActivityPanel:Refresh(self.ItemIds)
    --end, self.AssetActivityPanel)
    --self.TxtCostItem.text = CS.XTextManager.GetText("PokerGuessingCostItemText",XDataCenter.PokerGuessingManager.GetCostItemName())
    self.TxtTitle.text = CS.XTextManager.GetText("PokerGuessingStraightWins")
    self.TxtCostNum.text = XDataCenter.PokerGuessingManager.GetCostItemCount()
    self.RImgCostIcon:SetRawImage(XDataCenter.PokerGuessingManager.GetCostItemIcon())
    self.BtnRecord:SetName(CS.XTextManager.GetText("PokerGuessingRecordTitle"))
    self.BtnNewGame:SetName(CS.XTextManager.GetText("PokerGuessingNewGame"))
    self.BtnTask:SetName(CS.XTextManager.GetText("PokerGuessingTask"))
    self.BtnShop:SetName(CS.XTextManager.GetText("PokerGuessingStory"))
    self:UpdateScore()
end

function XUiFubenPokerGuessing:RegisterButtonEvent()
    self.BtnMainUi.CallBack = function () XLuaUiManager.RunMain()  end
    self.BtnBack.CallBack = function () self:Close()  end
    self:BindHelpBtn(self.BtnHelp, "PokerGuessing")
    self.BtnRecord.CallBack = function ()
        XLuaUiManager.Open("UiFubenPokerGuessingCardRecorder")
    end
    self.BtnBig.CallBack = function()
        XDataCenter.PokerGuessingManager.GuessCompareRequest(XPokerGuessingConfig.GuessType.Greater, function()
            self.PanelBuff.gameObject:SetActiveEx(true)
            self.TxtTips.gameObject:SetActiveEx(false)
        end)
        self.BtnSmall:SetButtonState(CS.UiButtonState.Normal)
    end
    self.BtnSmall.CallBack = function()
        XDataCenter.PokerGuessingManager.GuessCompareRequest(XPokerGuessingConfig.GuessType.Less, function()
            self.PanelBuff.gameObject:SetActiveEx(true)
            self.TxtTips.gameObject:SetActiveEx(false)
        end)
        self.BtnBig:SetButtonState(CS.UiButtonState.Normal)
    end
    self.BtnNewGame.CallBack = function()
        XDataCenter.PokerGuessingManager.StartNewPokerGuessingRequest(function()
            self.TxtScore.text = 0
            self:PlayNewGameAnimation()
        end)
    end
    self.BtnShop.CallBack = function() self:OnBtnShopClick() end
    self.BtnTask.CallBack = function()
        XLuaUiManager.Open("UiFubenPokerGuessingTask")
    end
    
    self.BtnReplace.CallBack = function()
        self:OnOpenUiSelectRole()
    end
    if self.PanelHead then
        XUiHelper.RegisterClickEvent(self, self.PanelHead, handler(self, self.OnOpenUiSelectRole))
    end
    self.BtnTips.CallBack = function() self:OnBtnTipsClick() end
end

function XUiFubenPokerGuessing:UpdateView()
    
    self.TxtTime.text = XUiHelper.GetTime(XDataCenter.PokerGuessingManager.GetEndTime() - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.ACTIVITY)
    self:BindViewModelPropertyToObj(self.PokerGuessing, function(roleId)
        self.SelectRoleId = roleId
        self.RImgHeadIcon:SetRawImage(XPokerGuessingConfig.PokerRoleConfig:GetProperty(roleId, "Icon"))
    end, "_SelectRoleId")
    
    self:BindViewModelPropertiesToObj(self.PokerGuessing, function(count, progress)
        local maxCount = XDataCenter.PokerGuessingManager.GetMaxTipCount()
        local attachMax = maxCount <= count
        count = math.min(count, maxCount)
        self.ImgStars.fillAmount = XUiHelper.GetFillAmountValue(count, maxCount)
        local maxProgress = XDataCenter.PokerGuessingManager.GetMaxProgress()
        if attachMax then
            progress = maxProgress
        end
        self.ImgBuffUp.fillAmount = XUiHelper.GetFillAmountValue(progress, maxProgress)
        self.TxtNumber.text = count
        self.TxtNumberMax.text = "/" .. maxCount
    end, "_TipsCount", "_TipsProgress")

    self:OnCheckRedPoint()
end

function XUiFubenPokerGuessing:UpdateGameState()
    local currGameStatus = XDataCenter.PokerGuessingManager.GetCurrGameStatus()
    self.RImgRightCard.gameObject:SetActiveEx(true)
    if currGameStatus == XPokerGuessingConfig.GameStatus.Initialize then 
        self.PanelNewGame.gameObject:SetActiveEx(true)
        self.PanelPlay.gameObject:SetActiveEx(false)
        self.RImgLeftCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
        self.RImgRightCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
        self.RImgRightCard.gameObject:SetActiveEx(false)
    --    if self.IsFirstEnter then self:PlayAnimationWithMask("RImgRightCard2Flip2") end
    elseif currGameStatus == XPokerGuessingConfig.GameStatus.Process then
        self.PanelNewGame.gameObject:SetActiveEx(false)
        self.PanelPlay.gameObject:SetActiveEx(true)
        self:PlayAnimation("RImgLeftCardRotate",function() XLuaUiManager.SetMask(false) end,function() XLuaUiManager.SetMask(true) end)
        self.RImgLeftCard:SetRawImage(XPokerGuessingConfig.GetCardFrontAssetPath(XDataCenter.PokerGuessingManager.GetDisplayCardId()))
        self.RImgRightCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
    elseif currGameStatus == XPokerGuessingConfig.GameStatus.Victory
    or currGameStatus == XPokerGuessingConfig.GameStatus.Failed
    or currGameStatus == XPokerGuessingConfig.GameStatus.Drawn then
        self.PanelNewGame.gameObject:SetActiveEx(false)
        self.PanelPlay.gameObject:SetActiveEx(true)
        self.RImgRightCard:SetRawImage(XPokerGuessingConfig.GetCardFrontAssetPath(XDataCenter.PokerGuessingManager.GetDisplayCardId()))
        if self.IsFirstEnter then
            if currGameStatus == XPokerGuessingConfig.GameStatus.Victory or currGameStatus == XPokerGuessingConfig.GameStatus.Drawn then
                self:PlayAnimation("RImgLeftCardRotate",function() XLuaUiManager.SetMask(false) end,function() XLuaUiManager.SetMask(true) end)
                self.RImgLeftCard:SetRawImage(XPokerGuessingConfig.GetCardFrontAssetPath(XDataCenter.PokerGuessingManager.GetDisplayCardId()))
                self.RImgRightCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
                self.BtnSmall:SetButtonState(CS.UiButtonState.Normal)
                self.BtnBig:SetButtonState(CS.UiButtonState.Normal)
            elseif currGameStatus == XPokerGuessingConfig.GameStatus.Failed then
                self.PanelNewGame.gameObject:SetActiveEx(true)
                self.PanelPlay.gameObject:SetActiveEx(false)
                self.RImgRightCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
                self.RImgLeftCard:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
                self.RImgRightCard.gameObject:SetActiveEx(false)
                --self:PlayAnimationWithMask("RImgRightCard2Flip2")
            end
        else
            self:ShowResultPanel(currGameStatus)
            self:PlayShowResultAnimation(currGameStatus == XPokerGuessingConfig.GameStatus.Victory)
            self:PlayAnimation("RImgRightCardRotate",function()
                XLuaUiManager.SetMask(false)
                if currGameStatus == XPokerGuessingConfig.GameStatus.Victory or currGameStatus == XPokerGuessingConfig.GameStatus.Drawn then
                    self:PlaySuccessAnimation()
                else
                    self:PlayFailedAnimation()
                end
            end,function() XLuaUiManager.SetMask(true)  end)
        end
    elseif currGameStatus == XPokerGuessingConfig.GameStatus.ScoreOutRange then
        XUiManager.TipText("PokerGuessingScoreOutRange")
        XDataCenter.PokerGuessingManager.IsContinueGuessRequest(false)
    elseif currGameStatus == XPokerGuessingConfig.GameStatus.LibraryEmpty then
        self.RImgRightCard:SetRawImage(XPokerGuessingConfig.GetCardFrontAssetPath(XDataCenter.PokerGuessingManager.GetDisplayCardId()))
        --牌局为空时，状态必然是胜利的
        --local result = XDataCenter.PokerGuessingManager.GetResult()
        self:ShowResultPanel(XPokerGuessingConfig.GameStatus.Victory)
        self:PlayShowResultAnimation(true)
        self:PlayAnimationWithMask("RImgRightCardRotate",function()
            XUiManager.TipText("PokerGuessingEmptyLibrayText")
            self:PlaySuccessAnimation()
            XDataCenter.PokerGuessingManager.IsContinueGuessRequest(false)
            --self:PlayLibraryEmptyAnimation()
        end)
    end
    self.IsFirstEnter = false
    local count = XDataCenter.PokerGuessingManager.GetCostItemCount()
    self.RImgCostIcon.gameObject:SetActiveEx(not XDataCenter.PokerGuessingManager.GetIsEnterCost() and count > 0)
    self.TxtCostNum.gameObject:SetActiveEx(not XDataCenter.PokerGuessingManager.GetIsEnterCost() and count > 0)
end

function XUiFubenPokerGuessing:UpdateScore()
    local currGameStatus = XDataCenter.PokerGuessingManager.GetCurrGameStatus()
    local score = currGameStatus == XPokerGuessingConfig.GameStatus.Failed 
            and XDataCenter.PokerGuessingManager.GetOldScore() 
            or XDataCenter.PokerGuessingManager.GetCurrentScore()
    self.TxtScore.text = score
end

function XUiFubenPokerGuessing:ShowResultPanel(gameStatus)
    if gameStatus == XPokerGuessingConfig.GameStatus.Victory then
        self.TxtResult1.text = CS.XTextManager.GetText("PokerGuessingVictory")
        self.TxtResult2.text = CS.XTextManager.GetText("PokerGuessingVictoryEng")
    elseif gameStatus == XPokerGuessingConfig.GameStatus.Failed then
        self.TxtResult1.text = CS.XTextManager.GetText("PokerGuessingFailed")
        self.TxtResult2.text = CS.XTextManager.GetText("PokerGuessingFailedEng")
    elseif gameStatus == XPokerGuessingConfig.GameStatus.Drawn then
        self.TxtResult1.text = CS.XTextManager.GetText("PokerGuessingDraw")
        self.TxtResult2.text = CS.XTextManager.GetText("PokerGuessingDrawEng")
    end
end

function XUiFubenPokerGuessing:PlayNewGameAnimation()
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("PanelPlayEnable")
    self:PlayAnimation("PanelNewGameDisable")
    self:PlayAnimation("RImgLeftCardRotate")
    self:PlayAnimation("RImgRightCard2Flip",function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiFubenPokerGuessing:PlayShowResultAnimation(isWin)
    local aniName = isWin and "PanelTipsVictoryEnable" or "PanelTipsLoseEnable"
    self.Victory.gameObject:SetActiveEx(isWin)
    self.Lose.gameObject:SetActiveEx(not isWin)
    self.PanelTips.gameObject:SetActiveEx(true)
    self:PlayAnimation(aniName,function()
        self:PlayAnimation("PanelTipsDisable",function()
            self.PanelTips.gameObject:SetActiveEx(false)
        end)
    end)
end

function XUiFubenPokerGuessing:PlaySuccessAnimation()
    XLuaUiManager.SetMask(true)
    local originPosition = self.RImgRightCard.transform.position
    XUiHelper.DoWorldMove(self.RImgRightCard.transform,self.RImgLeftCard.transform.position,0.5,XUiHelper.EaseType.Linear,function()
        if XTool.UObjIsNil(self.RImgRightCard) then
            XLuaUiManager.SetMask(false)
            return
        end
        self.RImgLeftCard:SetRawImage(XPokerGuessingConfig.GetCardFrontAssetPath(XDataCenter.PokerGuessingManager.GetDisplayCardId()))
        self.RImgRightCard.transform:GetComponent("CanvasGroup").alpha = 0
        self.RImgRightCard.transform.position = originPosition
        self:PlayAnimation("RImgRightCard2Flip",function()
            XLuaUiManager.SetMask(false)
            self.BtnSmall:SetButtonState(CS.UiButtonState.Normal)
            self.BtnBig:SetButtonState(CS.UiButtonState.Normal)
        end)
    end)
end

function XUiFubenPokerGuessing:PlayFailedAnimation()
    self.PanelNewGame.gameObject:SetActiveEx(true)
    self.PanelPlay.gameObject:SetActiveEx(false)
    self:PlayAnimation("PanelNewGameEnable")
    self:PlayAnimation("PanelPlayDisable")
    self:PlayAnimation("RImgLeftCardRotate2")
    self:PlayAnimation("RImgRightCardRotate2",function()
        self:PlayAnimation("RImgRightCard2Flip2",function()
            XLuaUiManager.SetMask(false)
            if XTool.UObjIsNil(self.RImgRightCard) then
                return
            end
            self.BtnSmall:SetButtonState(CS.UiButtonState.Normal)
            self.BtnBig:SetButtonState(CS.UiButtonState.Normal)
        end)
    end,function() XLuaUiManager.SetMask(true) end)
end

function XUiFubenPokerGuessing:PlayLibraryEmptyAnimation()
    self.PanelNewGame.gameObject:SetActiveEx(true)
    self.PanelPlay.gameObject:SetActiveEx(false)
    self:PlayAnimation("PanelNewGameEnable")
    self:PlayAnimation("PanelPlayDisable")
    self:PlayAnimation("RImgLeftCardRotate2")
    self:PlayAnimation("RImgRightCardRotate2",function()
        self:PlayAnimation("RImgRightCard2Flip2",function()
            XLuaUiManager.SetMask(false)
            if XTool.UObjIsNil(self.RImgRightCard) then
                return
            end
            self.BtnSmall:SetButtonState(CS.UiButtonState.Normal)
            self.BtnBig:SetButtonState(CS.UiButtonState.Normal)
        end)
    end,function() XLuaUiManager.SetMask(true) end)
end

function XUiFubenPokerGuessing:OnBtnTipsClick()
    local status = XDataCenter.PokerGuessingManager.GetCurrGameStatus()
    if status == XPokerGuessingConfig.GameStatus.Initialize
            or status == XPokerGuessingConfig.GameStatus.Failed then
        XUiManager.TipText("PokerGuessingGameNotStart")
        return
    end
    local count = self.PokerGuessing:GetProperty("_TipsCount")
    if count <= 0 then
        XUiManager.TipText("PokerGuessingTipsCountDeficiency")
        return
    end
    
    XDataCenter.PokerGuessingManager.UseTipsRequest(function() 
        local desc = self.PokerGuessing:GetTipsDesc()
        self.PanelBuff.gameObject:SetActiveEx(false)
        self.TxtTips.text = desc
        self.TxtTips.gameObject:SetActiveEx(true)
    end)
end

function XUiFubenPokerGuessing:OnBtnShopClick()
    --local skipId = XDataCenter.PokerGuessingManager.GetShopSkipId()
    --if skipId and skipId ~= 0 then
    --    XFunctionManager.SkipInterface(skipId)
    --end
    XLuaUiManager.Open("UiFubenPokerGuessingStory")
end

function XUiFubenPokerGuessing:OnOpenUiSelectRole()
    XLuaUiManager.Open("UiFubenPokerGuessingSelectRole", self.SelectRoleId)
end

function XUiFubenPokerGuessing:OnCheckRedPoint()
    self.BtnTask:ShowReddot(XDataCenter.PokerGuessingManager.CheckTaskRedPoint())
    self.BtnShop:ShowReddot(XDataCenter.PokerGuessingManager.CheckStoryRedPoint())
end

return XUiFubenPokerGuessing