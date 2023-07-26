--==============
--超限乱斗奖励页面
--==============
local XUiSuperSmashBrosReward = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosReward")

function XUiSuperSmashBrosReward:OnStart(onCloseCb)
    self.OnCloseCb = onCloseCb
    self:InitPanels()
    self:InitBtns()
end

function XUiSuperSmashBrosReward:InitPanels()
    self:InitTabs()
    self:InitScorePanel()
end

function XUiSuperSmashBrosReward:InitTabs()
    local script = require("XUi/XUiSuperSmashBros/Reward/Panels/XUiSSBRewardTabs")
    self.Tabs = script.New(self.PanelTab, self.GridTab, function(modeId) self:OnSelectTab(modeId) end)
end

function XUiSuperSmashBrosReward:OnSelectTab(modeId)
    self.TxtCurScore.text = XUiHelper.GetText("SSBCurrentScore", XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId):GetScore())
    self.ScorePanel:Refresh(modeId, self)
    self:PlayAnimation("QieHuan")
end

function XUiSuperSmashBrosReward:InitScorePanel()
    local script = require("XUi/XUiSuperSmashBros/Reward/Panels/XUiSSBRewardScorePanel")
    self.ScorePanel = script.New(self.PanelScoreContent, self.GridScore)
end

function XUiSuperSmashBrosReward:OnEnable()
    self.Tabs:SelectTab(XDataCenter.SuperSmashBrosManager.GetFirstModeHaveRewardGet():GetId())
end

function XUiSuperSmashBrosReward:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnClose() end
end

function XUiSuperSmashBrosReward:OnClickBtnClose()
    self:Close()
end

function XUiSuperSmashBrosReward:OnDestroy()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end