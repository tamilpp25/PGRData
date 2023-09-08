
---@class XUiBlackRockChessMain : XLuaUi
---@field private _Control XBlackRockChessControl
local XUiBlackRockChessMain = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessMain")

function XUiBlackRockChessMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessMain:OnStart()
    self:InitView()
end

function XUiBlackRockChessMain:OnEnable()
    self:UpdateView()
end

function XUiBlackRockChessMain:InitUi()
    self.Bgcontinue = self.Transform:Find("SafeAreaContentPane/Bgcontinue")
end

function XUiBlackRockChessMain:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    
    self.BtnEasy.CallBack = function() 
        self:OnBtnChallengeClick(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE)
    end
    
    self.BtnHard.CallBack = function() 
        self:OnBtnChallengeClick(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO)
    end
    
    self.BtnContinue.CallBack = function() 
        self:OnBtnContinueClick()
    end
    
    self.BtnGiveUp.CallBack = function() 
        self:OnBtnGiveUpClick()
    end

    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnArchive, self.OnBtnArchiveClick)
    self:RegisterClickEvent(self.BtnHandbook,self.OnBtnHandbookClick)
end

function XUiBlackRockChessMain:InitView()
    local endTime = self._Control:GetActivityStopTime()
    self.EndTime = endTime
    self:OnCheckActivity(false)
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
    
    self.PanelAsset = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetCurrencyIds(), self.PanelSpecialTool, self)
end

function XUiBlackRockChessMain:UpdateView()
    local isInFight = self._Control:GetAgency():IsInFight()
    self.PanelContinue.gameObject:SetActiveEx(isInFight)
    self.BtnGiveUp.gameObject:SetActiveEx(isInFight)
    self.BtnContinue.gameObject:SetActiveEx(isInFight)
    if self.Bgcontinue then
        self.Bgcontinue.gameObject:SetActiveEx(isInFight)
    end
    self.BtnEasy.gameObject:SetActiveEx(not isInFight)
    self.BtnHard.gameObject:SetActiveEx(not isInFight)
    local normalValue = self._Control:GetChapterProgress(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE) * 100
    local hardValue = self._Control:GetChapterProgress(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO) * 100
    self.TxtEasyProgress.text = string.format("%s%%", math.round(normalValue))
    self.TxtHardProgress.text = string.format("%s%%", math.round(hardValue))
    local rewardDatas = XRewardManager.GetRewardList(self._Control:GetMainPanelRewardShowId())
    self:RefreshTemplateGrids(self.GridReward, rewardDatas, self.GridReward.parent, nil, "BlackRockChessMainRewardShow", function(grid, data)
        ---@type XUiGridCommon
        local reward = XUiGridCommon.New(self, grid.GridReward)
        reward:Refresh(data)
    end)
    self:CheckChapterEntrance()
    
    self.BtnEasy:ShowReddot(self._Control:CheckHardRedPoint(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE))
    self.BtnHard:ShowReddot(self._Control:CheckChapterTwoRedPoint() or self._Control:CheckHardRedPoint(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO))
end

function XUiBlackRockChessMain:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(self.EndTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    self:CheckChapterEntrance()
end

function XUiBlackRockChessMain:CheckChapterEntrance()
    self._IsChapterOneOpen, self._ChapterOneConditionDesc = self._Control:IsNormalOpen(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE)
    self._IsChapterTwoOpen, self._ChapterTwoConditionDesc = self._Control:IsNormalOpen(XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO)
    self.BtnEasy:SetButtonState(self._IsChapterOneOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnHard:SetButtonState(self._IsChapterTwoOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiBlackRockChessMain:OnBtnChallengeClick(chapterId)
    local isOne = chapterId == XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE
    local isTwo = chapterId == XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO
    if isOne and not self._IsChapterOneOpen then
        XUiManager.TipMsg(self._ChapterOneConditionDesc)
        return
    elseif isTwo and not self._IsChapterTwoOpen then
        XUiManager.TipMsg(self._ChapterTwoConditionDesc)
        return
    end
    if isTwo then
        self._Control:MarkChapterTwoRedPoint()
    end
    XLuaUiManager.Open("UiBlackRockChessChapter", chapterId, self._Control:IsNormalCache(chapterId))
end

function XUiBlackRockChessMain:OnBtnShopClick()
    self._Control:OpenShop()
end

function XUiBlackRockChessMain:OnBtnArchiveClick()
    XLuaUiManager.Open("UiBlackRockChessArchive")
end

function XUiBlackRockChessMain:OnBtnHandbookClick()
    XLuaUiManager.Open("UiBlackRockChessHandbook")
end

function XUiBlackRockChessMain:OnBtnContinueClick()
    self._Control:ContinueStage()
end

function XUiBlackRockChessMain:OnBtnGiveUpClick()
    self:PlayAnimation("BtnEasyHardEnable")
    self._Control:GiveUpStage(function() 
        self:UpdateView()
    end)
end