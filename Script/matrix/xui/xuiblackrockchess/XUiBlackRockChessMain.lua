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
    --提前请求排行榜
    self._Control:PreReqRank()
    self:PlayAnimation("Enable")
end

function XUiBlackRockChessMain:InitUi()
    self.BtnArchive.gameObject:SetActiveEx(self._Control:IsArchiveOpen())
end

function XUiBlackRockChessMain:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()

    self.BtnShop.CallBack = handler(self, self.OnBtnShopClick)
    self.BtnEasy.CallBack = handler(self, self.OnBtnChallengeClick)
    self.BtnArchive.CallBack = handler(self, self.OnBtnArchiveClick)
    self.BtnHandbook.CallBack = handler(self, self.OnBtnHandbookClick)
    self.BtnRank.CallBack = handler(self, self.OnBtnRankClick)
end

function XUiBlackRockChessMain:InitView()
    local endTime = self._Control:GetActivityStopTime()
    self.EndTime = endTime
    self:OnCheckActivity(false)
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
    
    self.PanelAsset = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetCurrencyIds(), self.PanelSpecialTool, self)
end

function XUiBlackRockChessMain:UpdateView()
    self.BtnEasy.gameObject:SetActiveEx(true)
    local normalValue = self._Control:GetChapterProgress() * 100
    self.TxtEasyProgress.text = string.format("%s%%", math.round(normalValue))
    local rewardDatas = XRewardManager.GetRewardList(self._Control:GetMainPanelRewardShowId())
    self:RefreshTemplateGrids(self.GridReward, rewardDatas, self.GridReward.parent, nil, "BlackRockChessMainRewardShow", function(grid, data)
        ---@type XUiGridCommon
        local reward = require("XUi/XUiObtain/XUiGridCommon").New(self, grid.GridReward)
        reward:Refresh(data)
    end)

    self.BtnEasy:ShowReddot(XMVCA.XBlackRockChess:CheckMainRedPoint())
    self._Control:ClearShopRedCache()
    self.BtnShop:ShowReddot(self._Control:CheckShopRedPoint())
end

function XUiBlackRockChessMain:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(self.EndTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiBlackRockChessMain:OnBtnChallengeClick()
    XLuaUiManager.Open("UiBlackRockChessChapter")
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

function XUiBlackRockChessMain:OnBtnRankClick()
    XLuaUiManager.Open("UiBlackRockChessRank")
end

--function XUiBlackRockChessMain:OnBtnContinueClick()
--    self._Control:ContinueStage()
--end

return XUiBlackRockChessMain