local Panels = {
    PanelStages = require("XUi/XUiHitMouse/Panels/XUiHitMouseMainPanelStages"),
    PanelReward = require("XUi/XUiHitMouse/Panels/XUiHitMouseMainPanelReward"),
    PanelInformation = require("XUi/XUiHitMouse/Panels/XUiHitMouseMainPanelInfo")
}

--===============
--
--===============
local XUiHitMouseMain = XLuaUiManager.Register(XLuaUi, "UiHitMouseMain")

function XUiHitMouseMain:OnStart()
    self:InitBaseBtns()
    self:InitPanels()
    self:AddListeners()
end

function XUiHitMouseMain:InitBaseBtns()
    self.BtnMainUi.CallBack = handler(self, self.OnClickBtnMainUi)
    self.BtnBack.CallBack = handler(self, self.OnClickBtnBack)
    self:BindHelpBtn(self.BtnHelp, "HitMouseHelp")
end

function XUiHitMouseMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiHitMouseMain:OnClickBtnBack()
    self:Close()
end

--==============
--初始化各子面板
--==============
function XUiHitMouseMain:InitPanels()
    XUiHelper.NewPanelActivityAsset({XDataCenter.HitMouseManager.GetUnlockItemId()}, self.PanelActivityAsset)
    for _, panel in pairs(Panels) do
        if panel.Init then
            panel.Init(self)
        end
    end
end

function XUiHitMouseMain:OnEnable()
    for _, panel in pairs(Panels) do
        if panel.OnEnable then
            panel.OnEnable(self)
        end
    end
end

function XUiHitMouseMain:OnStageRefresh()
    Panels.PanelStages.Refresh(self)
    Panels.PanelReward.OnRewardRefresh(self)
end

function XUiHitMouseMain:OnRewardRefresh()
    Panels.PanelReward.OnRewardRefresh(self)
end

function XUiHitMouseMain:OnDestroy()
    for _, panel in pairs(Panels) do
        if panel.OnDestroy then
            panel.OnDestroy(self)
        end
    end
    self:RemoveListeners()
end
--==============
--设置活动关闭时处理
--==============
function XUiHitMouseMain:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.HitMouseManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.HitMouseManager.OnActivityEndHandler()
            end
        end)
end

function XUiHitMouseMain:OnActivityEnd()
    XDataCenter.HitMouseManager.OnActivityEndHandler()
end
--==============
--添加UI事件监听
--==============
function XUiHitMouseMain:AddListeners()
    XEventManager.AddEventListener(XEventId.EVENT_HIT_MOUSE_REWARD_REFRESH, self.OnRewardRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_HIT_MOUSE_STAGE_REFRESH, self.OnStageRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end
--==============
--移除UI事件监听
--==============
function XUiHitMouseMain:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_HIT_MOUSE_REWARD_REFRESH, self.OnRewardRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_HIT_MOUSE_STAGE_REFRESH, self.OnStageRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END, self.OnActivityEnd, self)
end