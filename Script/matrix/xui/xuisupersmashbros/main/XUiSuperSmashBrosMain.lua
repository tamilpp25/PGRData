local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local Panels = {
    PanelTitle = require("XUi/XUiSuperSmashBros/Main/Panels/XUiSSBMainPanelTitle"),
    PanelEntrance = require("XUi/XUiSuperSmashBros/Main/Panels/XUiSSBMainPanelEntrance"),
    PanelCore = require("XUi/XUiSuperSmashBros/Main/Panels/XUiSSBMainPanelCore"),
    PanelReward = require("XUi/XUiSuperSmashBros/Main/Panels/XUiSSBMainPanelReward")
}
--==============
--超限乱斗活动主页面
--==============
local XUiSuperSmashBrosMain = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosMain")

function XUiSuperSmashBrosMain:OnStart()
    self:InitBaseBtns() --注册基础按钮
    self:InitPanels() --初始化各子面板
    self:SetActivityTimeLimit() --设置活动关闭时处理
end
--==============
--注册基础按钮
--==============
function XUiSuperSmashBrosMain:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "SuperSmashBrosHelp")
end
--==============
--主界面按钮
--==============
function XUiSuperSmashBrosMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
--==============
--返回按钮
--==============
function XUiSuperSmashBrosMain:OnClickBtnBack()
    self:Close()
end
--==============
--初始化各子面板
--==============
function XUiSuperSmashBrosMain:InitPanels()
    for _, panel in pairs(Panels) do
        panel.Init(self)
    end
end
--==============
--界面显示时
--==============
function XUiSuperSmashBrosMain:OnEnable()
    XUiSuperSmashBrosMain.Super.OnEnable(self)
    for _, panel in pairs(Panels) do
        panel.OnEnable()
    end

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    local itemId = XDataCenter.SuperSmashBrosManager.GetLevelItem()
    self.AssetActivityPanel:Refresh({ itemId })
    local itemCount = XDataCenter.SuperSmashBrosManager.GetTeamItem()
    self.AssetActivityPanel.TxtSpecialTool1.text = itemCount  -- 兼容服务器发放该道具不走背包系统，而是直接发数字让客户端记录，所以背包索引该道具数量一定是0，同时兼容其他显示该物品的界面
    self.AssetActivityPanel.BtnClick1.CallBack = function () XLuaUiManager.Open("UiTip", itemId, self.HideSkipBtn, nil, nil, itemCount) end
end
--==============
--界面隐藏时
--==============
function XUiSuperSmashBrosMain:OnDisable()
    XUiSuperSmashBrosMain.Super.OnDisable(self)
    for _, panel in pairs(Panels) do
        panel.OnDisable()
    end
end

function XUiSuperSmashBrosMain:OnDestroy()
    for _, panel in pairs(Panels) do
        panel.OnDestroy()
    end
end
--==============
--设置活动关闭时处理
--==============
function XUiSuperSmashBrosMain:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperSmashBrosManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperSmashBrosManager.OnActivityEndHandler()
            end
        end)
end

function XUiSuperSmashBrosMain:UpdateRewardAndTeamLevel()
    Panels.PanelReward.UpdateDailyReward()
    Panels.PanelCore.Refresh()
end 