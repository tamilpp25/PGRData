local XUiGridRogueSimProduce = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimProduce")
local XUiPanelRogueSimProfit = require("XUi/XUiRogueSim/Battle/Panel/XUiPanelRogueSimProfit")
---@class XUiPanelRogueSimProduce : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupRoundEnd
local XUiPanelRogueSimProduce = XClass(XUiNode, "XUiPanelRogueSimProduce")

function XUiPanelRogueSimProduce:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnBtnResettingClick)
    self.GridProduce.gameObject:SetActive(false)
    self:InitView()
    ---@type XUiGridRogueSimProduce[]
    self.GridProduceList = {}
end

function XUiPanelRogueSimProduce:InitView()
    -- 提示
    self.TxtTips.text = self._Control:GetClientConfig("ProduceContent")
end

function XUiPanelRogueSimProduce:Refresh()
    self:RefreshProduce()
    self:RefreshPopulation()
    self:RefreshTotalProfit()
end

-- 获取货物评分
function XUiPanelRogueSimProduce:GetProducePlanScore()
    local producePlanScore = {}
    for _, grid in pairs(self.GridProduceList) do
        producePlanScore[grid:GetCommodityId()] = grid:GetCommodityScore()
    end
    return producePlanScore
end

-- 刷新生产力
function XUiPanelRogueSimProduce:RefreshPopulation()
    local id = XEnumConst.RogueSim.ResourceId.Population
    -- 图片
    self.ImgIcon:SetSprite(self._Control.ResourceSubControl:GetResourceIcon(id))
    -- 总的生产力
    local totalCount = self._Control.ResourceSubControl:GetResourceOwnCount(id)
    -- 剩余生产力
    local remainingPopulation = self._Control:GetActualRemainingPopulation()
    self.TxtNum.text = string.format("%s/%s", remainingPopulation, totalCount)
    local color = self._Control:GetClientConfig("PopulationTextColor", remainingPopulation >= 0 and 1 or 2)
    self.TxtNum.color = XUiHelper.Hexcolor2Color(color)
    self.Parent:RefreshBtnEnd()
end

-- 刷新货物
function XUiPanelRogueSimProduce:RefreshProduce()
    local gridName = self.GridProduce.gameObject.name
    local produceIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(produceIds) do
        local grid = self.GridProduceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProduce, self.ListProduce)
            grid = XUiGridRogueSimProduce.New(go, self)
            self.GridProduceList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        -- 修改名称引导使用
        grid.GameObject.name = string.format("%s%s", gridName, index)
    end
    for i = #produceIds + 1, #self.GridProduceList do
        self.GridProduceList[i]:Close()
    end
end

-- 获取总利润
function XUiPanelRogueSimProduce:GetTotalProfit()
    local totalProfit = 0
    for _, grid in pairs(self.GridProduceList) do
        totalProfit = totalProfit + grid:GetCurCommodityProfit()
    end
    return totalProfit
end

-- 刷新预计总利润
function XUiPanelRogueSimProduce:RefreshTotalProfit(isAnim)
    if not self.PanelProfitUi then
        ---@type XUiPanelRogueSimProfit
        self.PanelProfitUi = XUiPanelRogueSimProfit.New(self.PanelTotalProfit, self)
    end
    self.PanelProfitUi:Open()
    local totalProfit = self:GetTotalProfit()
    self.PanelProfitUi:RefreshTotalProfit(totalProfit, isAnim)
end

-- 生产力变更需要刷新的部分
function XUiPanelRogueSimProduce:RefreshPopulationChange()
    for _, grid in pairs(self.GridProduceList) do
        grid:RefreshNum()
        grid:RefreshProfit()
        grid:RefreshPopulationBtn()
    end
    self:RefreshTotalProfit(true)
end

-- 重置
function XUiPanelRogueSimProduce:OnBtnResettingClick()
    -- 重置生产计划
    self._Control:ResetTempProducePlanCount()
    for _, grid in pairs(self.GridProduceList) do
        grid:ChangePopulationCount()
    end
    -- 刷新生产力
    self:RefreshPopulation()
    self:RefreshPopulationChange()
end

return XUiPanelRogueSimProduce
