local XUiGridRogueSimRoundStartSell = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimRoundStartSell")
---@class XUiPanelRogueSimRoundStartSell : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimRoundStartSell = XClass(XUiNode, "XUiPanelRogueSimRoundStartSell")

function XUiPanelRogueSimRoundStartSell:OnStart()
    self.GridTurnData.gameObject:SetActive(false)
    self.GridSell.gameObject:SetActive(false)
    self.TxtSellNone.gameObject:SetActive(false)
    self.ImgUp.gameObject:SetActive(false)
    self.ImgDown.gameObject:SetActive(false)
    ---@type UiObject[]
    self.GridTurnList = {}
    ---@type XUiGridRogueSimRoundStartSell[]
    self.GridSellList = {}
end

---@param turnNumber number 回合数
function XUiPanelRogueSimRoundStartSell:Refresh(turnNumber)
    self.TurnNumber = turnNumber
    self.SellResult = self._Control:GetSellResultByTurnNumber(self.TurnNumber)
    -- 是否为空
    local isEmpty = XTool.IsTableEmpty(self.SellResult)
    self.TxtSellNone.gameObject:SetActiveEx(isEmpty)
    self.PanelHistogram.gameObject:SetActiveEx(not isEmpty)
    self.PanelProfit.gameObject:SetActiveEx(not isEmpty)
    self.SellList.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        return
    end
    self:RefreshHistogram()
    self:RefreshSellList()
    self:RefreshTotalPrice()
end

-- 直方图(只显示三个)
function XUiPanelRogueSimRoundStartSell:RefreshHistogram()
    local recentSellResults, maxTotalPrice = self._Control:GetRecentSellResults(self.TurnNumber, 3)
    for index, info in pairs(recentSellResults) do
        local grid = self.GridTurnList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTurnData, self.TurnDataList)
            self.GridTurnList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtRoundNum").text = info.TurnNum
        grid:GetObject("ImgBar").fillAmount = XTool.IsNumberValid(maxTotalPrice) and info.TotalPrice / maxTotalPrice or 1
        local color = self._Control:GetClientConfig("RoundStartSellHistogramColor", info.TurnNum == self.TurnNumber and 2 or 1)
        grid:GetObject("ImgBar").color = XUiHelper.Hexcolor2Color(color)
    end
    for i = #recentSellResults + 1, #self.GridTurnList do
        self.GridTurnList[i].gameObject:SetActiveEx(false)
    end
end

-- 出售列表
function XUiPanelRogueSimRoundStartSell:RefreshSellList()
    local info = self.SellResult:GetDatas()
    for index, data in pairs(info) do
        local grid = self.GridSellList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSell, self.SellList)
            grid = XUiGridRogueSimRoundStartSell.New(go, self)
            self.GridSellList[index] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
    for i = #info + 1, #self.GridSellList do
        self.GridSellList[i]:Close()
    end
end

-- 总利润
function XUiPanelRogueSimRoundStartSell:RefreshTotalPrice()
    local totalPrice = self.SellResult:GetTotalSellAwardCount()
    self.TxtProfit.text = string.format("+%d", totalPrice)
    self.RImgCoin:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold))
    -- 相对之前是否增加
    local _, lastTotalPrice = self._Control:GetRecentSellResults(self.TurnNumber - 1, 1)
    self.ImgUp.gameObject:SetActiveEx(totalPrice > lastTotalPrice)
    self.ImgDown.gameObject:SetActiveEx(totalPrice < lastTotalPrice)
end

return XUiPanelRogueSimRoundStartSell
