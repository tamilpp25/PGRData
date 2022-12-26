local XUiGridInfestorExploreCore = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreCore")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

local XUiGridInfestorExploreShopGoods = XClass(nil, "XUiGridInfestorExploreShopGoods")

function XUiGridInfestorExploreShopGoods:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)

    local icon = XDataCenter.FubenInfestorExploreManager.GetMoneyIcon()
    self.RImgPrice:SetRawImage(icon)
end

function XUiGridInfestorExploreShopGoods:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridInfestorExploreShopGoods:Refresh(goodsId)
    local cost = XFubenInfestorExploreConfigs.GetGoodsCost(goodsId)
    local isMoneyEnough = XDataCenter.FubenInfestorExploreManager.CheckMoneyEnough(cost)
    self.TxtPrice.text = cost
    self.TxtPrice.color = CONDITION_COLOR[isMoneyEnough]

    self.GridCore = self.GridCore or XUiGridInfestorExploreCore.New(self.GridInfestorExploreCore, self.RootUi)
    local coreId = XFubenInfestorExploreConfigs.GetGoodsCoreId(goodsId)
    local coreLevel = XFubenInfestorExploreConfigs.GetGoodsCoreLevel(goodsId)
    self.GridCore:Refresh(coreId, coreLevel)

    self.ImgSellOut.gameObject:SetActiveEx(XDataCenter.FubenInfestorExploreManager.IsGoodsSellOut(goodsId))
end

function XUiGridInfestorExploreShopGoods:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

return XUiGridInfestorExploreShopGoods