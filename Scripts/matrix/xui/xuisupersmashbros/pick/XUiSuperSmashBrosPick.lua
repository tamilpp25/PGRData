local Panels = {
    PanelPick = require("XUi/XUiSuperSmashBros/Pick/Sub/XUiSSBPickPanelPick"),
    PanelHead = require("XUi/XUiSuperSmashBros/Pick/Sub/XUiSSBPickPanelHead"),
}
--==============
--超限乱斗选人页面
--==============
local XUiSuperSmashBrosPick = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosPick")

function XUiSuperSmashBrosPick:OnStart(mode, selectEnvironment, selectScene, isChangeMonsterOnFighting)
    ---@type XSmashBMode
    self.Mode = mode
    self.Page = XSuperSmashBrosConfig.PickPage.Pick
    if isChangeMonsterOnFighting then
        self.Page = XSuperSmashBrosConfig.PickPage.Select
    end
    self.IsChangeMonsterOnFighting = isChangeMonsterOnFighting
    self.Scene = selectScene
    self.Environment = selectEnvironment
    self.FirstIn = true
    self:InitBaseBtns() --注册基础按钮
    self:InitPanels() --初始化各子面板
    self:SetActivityTimeLimit() --设置活动关闭时处理
end
--==============
--注册基础按钮
--==============
function XUiSuperSmashBrosPick:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosPick:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosPick:OnClickBtnBack()
    if self.IsChangeMonsterOnFighting then
        self:Close()
        return
    end
    if self.Page == XSuperSmashBrosConfig.PickPage.Select then
        self.Page = XSuperSmashBrosConfig.PickPage.Pick
        self.HeadPanel:HidePanel()
        self.PickPanel:ShowPanel()
        return
    end
    self:Close()
end
--==============
--初始化各子面板
--==============
function XUiSuperSmashBrosPick:InitPanels()
    self.PickPanel = Panels.PanelPick.New(self)
    self.HeadPanel = Panels.PanelHead.New(self, self.IsChangeMonsterOnFighting)
end
--==============
--界面显示时
--==============
function XUiSuperSmashBrosPick:OnEnable()
    XUiSuperSmashBrosPick.Super.OnEnable(self)
    if self.FirstIn then
        self.FirstIn = false
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
                XLuaUiManager.SetMask(false)
            end, 1200) --开始进入界面时等待一下动画结束
    else
        if self.PanelPickEnable then self.PanelPickEnable:Play() end
    end
    if self.Page == XSuperSmashBrosConfig.PickPage.Pick then
        self.HeadPanel:HidePanel()
        self.PickPanel:ShowPanel()
    elseif self.Page == XSuperSmashBrosConfig.PickPage.Select then
        self.PickPanel:HidePanel()
        if self.IsChangeMonsterOnFighting then
            self.HeadPanel:ShowPanel(XSuperSmashBrosConfig.RoleType.Monster, {})
        else
            self.HeadPanel:ShowPanel()
        end
    end
end
--==============
--界面隐藏时
--==============
function XUiSuperSmashBrosPick:OnDisable()
    XUiSuperSmashBrosPick.Super.OnDisable(self)
    self.PickPanel:OnDisable()
    self.HeadPanel:OnDisable()
end

function XUiSuperSmashBrosPick:OnDestroy()
    self.PickPanel:OnDestroy()
    self.HeadPanel:OnDestroy()
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosPick:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end
--==============
--切换页面
--==============
function XUiSuperSmashBrosPick:SwitchPage(switchPage, ...)
    if not switchPage then return end
    self.Page = switchPage
    if self.Page == XSuperSmashBrosConfig.PickPage.Pick then
        self.HeadPanel:HidePanel()
        self.PickPanel:ShowPanel(...)
    elseif self.Page == XSuperSmashBrosConfig.PickPage.Select then
        self.PickPanel:HidePanel()
        self.HeadPanel:ShowPanel(...)
    end
end
--==============
--在进入准备作战界面后要从UI堆栈去除这个界面和选择场景界面
--==============
function XUiSuperSmashBrosPick:RemovePickScenes()
    XLuaUiManager.Remove("UiSuperSmashBrosSelectStage")
    XLuaUiManager.Remove("UiSuperSmashBrosPick")
end
