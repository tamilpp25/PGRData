local XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods")
local XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods")
---@class XUiSkyGardenShoppingStreetInsideBuildGoods : XUiNode
local XUiSkyGardenShoppingStreetInsideBuildGoods = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGoods")

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnStart()
    self._GoodsList = {}
    self._SelectGoodsDetailId = {}
    self._SelectGoodsId = {}
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    self._GoodsCfg = self._Control:GetShopGroceryConfigsByShopId(buildingId)

    local groceryData = shopAreaData:GetGroceryData()
    local shelfDatas
    if groceryData then
        shelfDatas = groceryData.ShelfDatas
    else
        shelfDatas = {}
    end

    self._TempGoods = {}
    for i = 1, self._GoodsCfg.ShelfNum do
        if not self._TempGoods[i] then
            local goodsData = shelfDatas[i]
            if goodsData then
                self._TempGoods[i] = {
                    id = goodsData.GoodsId,
                    num = goodsData.GoldCount,
                }
            else
                self._TempGoods[i] = {}
            end
        end
    end

    for _, v in ipairs(self._TempGoods) do
        if v.id then
            self._SelectGoodsId[v.id] = true
        end
    end

    XTool.UpdateDynamicItem(self._GoodsList, self._GoodsCfg.Goods, self.GridSmallGoods, XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods, self)
    XTool.UpdateDynamicItem(self._SelectGoodsDetailId, self._TempGoods, self.GirdGoods, XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods, self)
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnBtnSaveClick()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local list = {}
    for i = 1, #self._TempGoods do
        local goodsData = self._TempGoods[i]
        if goodsData.id then
            list[i] = {
                GoodsId = goodsData.id,
                GoldCount = goodsData.num,
            }
        else
            list[i] = {}
        end
    end
    self._Control:SgStreetShopSetupGroceryRequest(shopId, list)
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:IsSelectGoodId(goodId)
    return self._SelectGoodsId[goodId]
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnGoodsClick(index)
    local clickGoodId = self._TempGoods[index].id
    self._TempGoods[index].id = nil
    self._SelectGoodsDetailId[index]:Update(self._TempGoods[index])

    for index, goodId in pairs(self._GoodsCfg.Goods) do
        if goodId == clickGoodId then
            self._SelectGoodsId[goodId] = nil
            self._GoodsList[index]:SetSelect(false)
            break
        end
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnGridSmallGoodsClick(index, goodId)
    local cnt = 0
    for _, hasGood in pairs(self._SelectGoodsId) do
        if hasGood then
            cnt = cnt + 1 
        end
    end
    if not self._SelectGoodsId[goodId] and cnt >= self._GoodsCfg.ShelfNum then
        return
    end
    self._SelectGoodsId[goodId] = not self._SelectGoodsId[goodId]
    self._GoodsList[index]:SetSelect(self._SelectGoodsId[goodId])

    for paramsIndex, v in pairs(self._TempGoods) do
        if self._SelectGoodsId[goodId] then
            if not v.id then
                local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(goodId)
                self._TempGoods[paramsIndex].id = goodId
                self._TempGoods[paramsIndex].num = goodCfg.GoldInit
                self._SelectGoodsDetailId[paramsIndex]:Update(self._TempGoods[paramsIndex])
                break
            end
        else
            if v.id == goodId then
                self._TempGoods[paramsIndex].id = nil
                self._SelectGoodsDetailId[paramsIndex]:Update(self._TempGoods[paramsIndex])
                break
            end
        end
    end
end

return XUiSkyGardenShoppingStreetInsideBuildGoods
