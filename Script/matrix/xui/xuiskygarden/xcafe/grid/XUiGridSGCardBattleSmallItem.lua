
---@class XUiGridSGCardBattleSmallItem
---@field _Control XSkyGardenCafeControl
---@field _Card XCafe.XCard
---@field Parent
local XUiGridSGCardBattleSmallItem = XClass(nil, "XUiGridSGCardBattleSmallItem")

local XUiPanelSGValueChange = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGValueChange")

function XUiGridSGCardBattleSmallItem:Ctor(card, control)
    XTool.InitUiObjectByUi(self, card.transform)
    self._Card = card
    self._Control = control
    if not self._Effect then
        self._Effect = self.Transform:Find("Effect")
    end
    
    self._PanelCoffee = XUiPanelSGValueChange.New(self.PanelSell)
    self._PanelReview = XUiPanelSGValueChange.New(self.PanelGood)
end

function XUiGridSGCardBattleSmallItem:Reclaim()
    self.PanelSell.gameObject:SetActiveEx(false)
    self.PanelGood.gameObject:SetActiveEx(false)
    self.RImgRole.gameObject:SetActiveEx(false)
    if self._Effect then
        self._Effect.gameObject:SetActiveEx(false)
    end
    self:StopTimer()
end

---@param card XSkyGardenCafeCardEntity
function XUiGridSGCardBattleSmallItem:Refresh(card)
    self.TxtNum.text = self._Card:GetDealIndex() + 1
    if not card or card:IsDisposed() then
        self.PanelSell.gameObject:SetActiveEx(false)
        self.PanelGood.gameObject:SetActiveEx(false)
        self.RImgRole.gameObject:SetActiveEx(false)
        if self._Effect then
            self._Effect.gameObject:SetActiveEx(false)
        end
        self:StopTimer()
        return
    end
    self.RImgRole.gameObject:SetActiveEx(true)
    self.PanelSell.gameObject:SetActiveEx(true)
    self.PanelGood.gameObject:SetActiveEx(true)
    
    local totalCoffee = card:GetTotalCoffee(false)
    local totalReview = card:GetTotalReview(false)

    self._PanelCoffee:RefreshViewWithTxtComponent(totalCoffee, self._Control:GetCustomerCoffee(card:GetCardId()), self.TxtSellNum)
    self._PanelReview:RefreshViewWithTxtComponent(totalReview, self._Control:GetCustomerReview(card:GetCardId()), self.TxtGoodNum)
    if not self._RunAsync then
        local playTime = asynTask(self.Enable.PlayTimelineAnimation, self.Enable)
        RunAsyn(function()
            asynWaitSecond(0.3)
            
            playTime()
            
            if self._Effect then
                self._Effect.gameObject:SetActiveEx(true)
                asynWaitSecond(1)
                self._Effect.gameObject:SetActiveEx(false)
            end
        end)
        self._RunAsync = true
    end
    self.RImgRole:SetRawImage(self._Control:GetCustomerIcon(card:GetCardId()))
end

function XUiGridSGCardBattleSmallItem:InitUi()
end

function XUiGridSGCardBattleSmallItem:InitCb()
end

function XUiGridSGCardBattleSmallItem:Open()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGridSGCardBattleSmallItem:Close()
    self:StopTimer()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(false)
end

function XUiGridSGCardBattleSmallItem:StopTimer()
    self._RunAsync = false
end

return XUiGridSGCardBattleSmallItem 