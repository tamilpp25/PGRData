--组合小游戏主界面刷新面板UI控件
local XUiComposeGamePanelRefresh = XClass(nil, "XUiComposeGamePanelRefresh")
--================
--构造函数
--================
function XUiComposeGamePanelRefresh:Ctor(rootUi, game, ui)
    self.RootUi = rootUi
    self.Game = game
    XTool.InitUiObjectByUi(self, ui)
    self.BtnRefresh.CallBack = function() self:OnClick() end
end
--================
--设置刷新时间文本
--================
function XUiComposeGamePanelRefresh:SetRefreshTime(time)
    self.TxtTime.text = string.format("%s %s", time, CS.XTextManager.GetText("ComposeShopRefreshCountDown"))
end
--================
--设置招募次数文本
--================
function XUiComposeGamePanelRefresh:RefreshRecruitNumber()
    local canRefresh = self.Game:CheckCanRefresh()
    local canBuy = self.Game:CheckCanBuyRefresh()
    self.TxtNumber.gameObject:SetActiveEx(canRefresh or not canBuy)
    self.TxtBuy.gameObject:SetActiveEx((not canRefresh) and canBuy)
    if canRefresh or not canBuy then
        self.TxtNumber.text = self.Game:GetRefreshStr()
    else
        local price = self.Game:GetRefreshPrice()
        local currentCoin = XDataCenter.ItemManager.GetCoinsNum()
        if currentCoin and currentCoin < price then
            self.TxtBuy.text = CS.XTextManager.GetText("ComposeGameNoCoinBuyDraw", price)
        else
            self.TxtBuy.text = price
        end
    end
    self.TxtTime.gameObject:SetActiveEx(not self.Game:GetRefreshTimeIsMax())
end
--================
--点击刷新按钮时
--================
function XUiComposeGamePanelRefresh:OnClick()
    XDataCenter.ComposeGameManager.RefreshShop(self.Game:GetGameId())
end

return XUiComposeGamePanelRefresh