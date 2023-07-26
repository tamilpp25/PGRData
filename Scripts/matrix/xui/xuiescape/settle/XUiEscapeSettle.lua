local XUiPanelSelfWinInfo = require("XUi/XUiEscape/Settle/XUiPanelSelfWinInfo")
local XUiPanelAllWinInfo = require("XUi/XUiEscape/Settle/XUiPanelAllWinInfo")

--大逃杀结算界面
local XUiEscapeSettle = XLuaUiManager.Register(XLuaUi, "UiEscapeSettle")

function XUiEscapeSettle:OnAwake()
    self:InitButtonCallBack()

    local leftClickCb = handler(self, self.Close)
    self.SelfWinInfoPanel = XUiPanelSelfWinInfo.New(self.PanelSelfWinInfo, leftClickCb)
    self.AllWinInfoPanel = XUiPanelAllWinInfo.New(self.PanelAllWinInfo, leftClickCb)
end

--isWin：阶段结算面板用
function XUiEscapeSettle:OnStart(showPanel, isWin, winData)
    local isShowSelfWinInfo = showPanel == XEscapeConfigs.ShowSettlePanel.SelfWinInfo
    local isShowAllWinInfo = showPanel == XEscapeConfigs.ShowSettlePanel.AllWinInfo
    self.SelfWinInfoPanel.GameObject:SetActiveEx(isShowSelfWinInfo)
    self.AllWinInfoPanel.GameObject:SetActiveEx(isShowAllWinInfo)
    if isShowSelfWinInfo then
        self.SelfWinInfoPanel:Refresh(winData)
    elseif isShowAllWinInfo then
        self.AllWinInfoPanel:Refresh(isWin)
    end
end

function XUiEscapeSettle:OnDestroy()
    self.SelfWinInfoPanel:RemoveEventListener()
end

function XUiEscapeSettle:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnLeft, self.Close)
end