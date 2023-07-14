local XUiGridCommodityLine = XClass(nil,"XUiGridCommodityLine")

local XUiCommodity = require("XUi/XUiSpecialFashionShop/XUiCommodity")

function XUiGridCommodityLine:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform


    self.CommodityList = {}

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridCommodityLine:Init(parent)
    self.Parent = parent
end

function XUiGridCommodityLine:Refresh(commodityData)
    if #commodityData > XSpecialShopConfigs.MAX_COUNT then
        XLog.Error("XUiGridCommodityLine:Refresh函数错误，commodityData长度大于XSpecialShopConfigs.MAX_COUNT")
        return
    end

    self.CommodityData = commodityData

    if commodityData.First then
        self.PanelSeriesSymbol.gameObject:SetActiveEx(true)
        self.TxtSeries.text = XFashionConfigs.GetSeriesName(commodityData.SeriesId)
    else
        self.PanelSeriesSymbol.gameObject:SetActiveEx(false)
    end

    self.SymbolLayoutNode:SetDirty()
    self.LineLayoutNode:SetDirty()

    for i, commodity in pairs(self.CommodityList) do
        commodity:Refresh(commodityData[i])
    end
end

function XUiGridCommodityLine:OnRecycle()
    for _, commodity in pairs(self.CommodityList) do
        commodity:OnRecycle()
    end
end

function XUiGridCommodityLine:InitComponent()
    for i = 1, XSpecialShopConfigs.MAX_COUNT do
        local commodity = string.format("Commodity%s", tostring(i))
        self[commodity].gameObject:SetActiveEx(false)

        local commodityInst = XUiCommodity.New(self[commodity], self)
        self.CommodityList[i] = commodityInst
    end
end

function XUiGridCommodityLine:GetCurShopId()
    return self.Parent:GetCurShopId()
end

function XUiGridCommodityLine:RefreshBuy()
    self.Parent:RefreshBuy()
end

function XUiGridCommodityLine:RegisterTimerFun(id, fun)
    self.Parent:RegisterTimerFun(id, fun)
end

function XUiGridCommodityLine:RemoveTimerFun(id)
    self.Parent:RemoveTimerFun(id)
end

return XUiGridCommodityLine