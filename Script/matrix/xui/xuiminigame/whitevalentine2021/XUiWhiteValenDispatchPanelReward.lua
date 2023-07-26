-- 
local XUiWhiteValenDispatchPanelReward = XClass(nil, "XUiWhiteValenDispatchPanelReward")

function XUiWhiteValenDispatchPanelReward:Ctor(rootUi, ui, place)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.Place = place
    self.GameController = XDataCenter.WhiteValentineManager.GetGameController()
    self:InitReward()
end

function XUiWhiteValenDispatchPanelReward:InitReward()
    self.TxtCostTime.text = CS.XTextManager.GetText("WhiteValentineCostTimeStr", self.Place:GetCostTime())
    self.TxtCostEnergy.text = self.Place:GetCostEnergy()
    self.TxtCutDownTime.text = ""
    if self.RImgEnergyIcon then
        self.RImgEnergyIcon:SetRawImage(self.GameController:GetEnergyIconPath())
    end
    local grid = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenItemGrid")
    self.ContributionGrid = grid.New(self.GridContribution, self.GameController:GetContributionItemId())
    self.CoinGrid = grid.New(self.GridCoin, self.GameController:GetCoinItemId())
    self.CoinGrid:SetCount(self.Place:GetRankCoinReward())
    self.ContributionGrid:SetCount(self.Place:GetRankContributionReward())
end

function XUiWhiteValenDispatchPanelReward:RefreshChara(chara)
    local isAttrActive = chara:GetAttrType() == self.Place:GetEventAttrType()
    self.TxtCutDownTime.text = isAttrActive and CS.XTextManager.GetText("WhiteValentinePercentMinus", chara:GetCutDownTime()) or ""
    self.ContributionGrid:SetContributionAdd(isAttrActive and chara:GetContributionBuff() or nil)
end

return XUiWhiteValenDispatchPanelReward