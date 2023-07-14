
local XUiSuperSmashBrosRanking = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosRanking")

function XUiSuperSmashBrosRanking:OnStart()
    self:InitBaseBtns() --注册基础按钮
    self:InitPanels() --初始化各子面板
    self:SetActivityTimeLimit() --设置活动关闭时处理
end

function XUiSuperSmashBrosRanking:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
    self.BtnRecord.CallBack = handler(self, self.OnClickBtnRecord)
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosRanking:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosRanking:OnClickBtnBack()
    self:Close()
end

function XUiSuperSmashBrosRanking:OnClickBtnRecord()
    XLuaUiManager.Open("UiSuperSmashBrosClearTime")
end

function XUiSuperSmashBrosRanking:InitPanels()
    self:InitDTablePlayerRank()
    self:InitMyRankPanel()
    self.TxtAndroid.gameObject:SetActive(false) --排行榜没有分安卓苹果，这里先隐藏
end

function XUiSuperSmashBrosRanking:InitDTablePlayerRank()
    local script = require("XUi/XUiSuperSmashBros/Ranking/XUiSSBRankingDTable")
    self.RankingList = script.New(self.PlayerRankList, self.PlayerRank, self.PanelNoRank)
end

function XUiSuperSmashBrosRanking:InitMyRankPanel()
    local script = require("XUi/XUiSuperSmashBros/Ranking/XUiSSBRankingGrid")
    self.MyRank = script.New(self.PanelMyRank)
end

function XUiSuperSmashBrosRanking:OnEnable()
    XUiSuperSmashBrosRanking.Super.OnEnable(self)
    XDataCenter.SuperSmashBrosManager.GetRankingList(function(rankingList)
            self.RankingList:Refresh(rankingList)
            self.MyRank:Refresh(true)
        end)

end

--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosRanking:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end