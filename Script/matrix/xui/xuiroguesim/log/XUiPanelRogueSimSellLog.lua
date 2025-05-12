---@class XUiPanelRogueSimSellLog : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimSellLog = XClass(XUiNode, "XUiPanelRogueSimSellLog")

function XUiPanelRogueSimSellLog:OnStart()
    self.GridSell.gameObject:SetActiveEx(false)
    self.SellUiObjs = {}
end

function XUiPanelRogueSimSellLog:OnEnable()
    self:Refresh()
end

function XUiPanelRogueSimSellLog:Refresh()
    for _, uiObj in ipairs(self.SellUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local commodityIds = XEnumConst.RogueSim.CommodityIds
    local title = self._Control:GetClientConfig("BattleRoundNumDesc", 1)
    local goldIcon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)

    local curTurn = self._Control:GetCurTurnNumber()
    for i = curTurn - 1, 1, -1 do
        local uiObj = self.SellUiObjs[i]
        if not uiObj then
            local go = XUiHelper.Instantiate(self.GridSell, self.GridSell.transform.parent)
            uiObj = go:GetComponent("UiObject")
            self.SellUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)

        -- 商品销售记录
        local allProfit = 0
        local sellResult = self._Control:GetSellResultByTurnNumber(i)
        local produceResult = self._Control:GetProduceResultByTurnNumber(i)
        for commodityIndex, commodityId in ipairs(commodityIds) do
            local commodityUiObj = uiObj:GetObject("GridProduct" .. commodityIndex)
            ---@type XRogueSimCommoditySellResultItem
            local commodityData = sellResult and sellResult:GetDataById(commodityId)     -- 商品出售数据
            ---@type XRogueSimCommodityProduceResultItem
            local produceData = produceResult and produceResult:GetDataById(commodityId) -- 商品生产数据
            -- 商品
            local commodityIcon = self._Control.ResourceSubControl:GetCommodityIcon(commodityId)
            commodityUiObj:GetObject("GridResource"):GetObject("RawImage"):SetRawImage(commodityIcon)
            -- 市场价
            local price = commodityData and commodityData:GetPrice() or 0
            commodityUiObj:GetObject("RImgCoin"):SetRawImage(goldIcon)
            commodityUiObj:GetObject("TxtPrice").text = tostring(price)
            -- 利率
            local priceRate = commodityData and commodityData:GetPriceRate() / 100 or 0
            local isRateUp = priceRate > 0
            local isRateNormal = priceRate == 0
            local isRateDown = priceRate < 0
            local txtFluctuationsUp = commodityUiObj:GetObject("TxtFluctuationsUp")
            local txtFluctuationsNormal = commodityUiObj:GetObject("TxtFluctuationsNormal")
            local txtFluctuationsDown = commodityUiObj:GetObject("TxtFluctuationsDown")
            txtFluctuationsUp.gameObject:SetActiveEx(isRateUp)
            txtFluctuationsNormal.gameObject:SetActiveEx(isRateNormal)
            txtFluctuationsDown.gameObject:SetActiveEx(isRateDown)
            if isRateUp then
                txtFluctuationsUp.text = "+" .. tostring(priceRate) .. "%"
            elseif isRateNormal then
                txtFluctuationsNormal.text = "+0%"
            elseif isRateDown then
                txtFluctuationsDown.text = tostring(priceRate) .. "%"
            end
            -- 生产
            local produceCnt = produceData and produceData:GetProduceCount() or 0
            commodityUiObj:GetObject("TxtProduceNum").text = "X" .. tostring(produceCnt)
            local isProduceCritical = produceData and produceData:GetIsCritical() or false
            commodityUiObj:GetObject("RImgProduceBaoji").gameObject:SetActiveEx(isProduceCritical)
            -- 出售
            local sellCnt = commodityData and commodityData:GetSellCount() or 0
            commodityUiObj:GetObject("TxtSellNum").text = "X" .. tostring(sellCnt)
            -- 利润
            local sellAwardCnt = commodityData and commodityData:GetSellAwardCount() or 0
            commodityUiObj:GetObject("RImgProfitCoin"):SetRawImage(goldIcon)
            commodityUiObj:GetObject("TxtProfit").text = tostring(sellAwardCnt)
            local isProfitCritical = commodityData and commodityData:GetIsCritical() or false
            commodityUiObj:GetObject("RImglProfitBaoji").gameObject:SetActiveEx(isProfitCritical)
            allProfit = allProfit + sellAwardCnt
        end

        -- 总利润
        uiObj:GetObject("TxtRound").text = string.format(title, i)
        uiObj:GetObject("RImgCoin"):SetRawImage(goldIcon)
        uiObj:GetObject("TxtProfit").text = tostring(allProfit)
    end

    -- 无贸易记录
    local isFirstTurn = curTurn == 1
    self.PanelEmpty.gameObject:SetActiveEx(isFirstTurn)
end

return XUiPanelRogueSimSellLog
