local XUiLottoTanchuang = XLuaUiManager.Register(XLuaUi, "UiLottoTanchuang")
local XUiGridTicket = require("XUi/XUiLotto/XUiGridTicket")
local UseItemMax = 2

---@param data XLottoDrawEntity
function XUiLottoTanchuang:OnStart(data)
    self.DrawData = data
    self:SetButtonCallBack()
    self.UseItem = {}
    self.TargetItem = {}
    self.UseCard = {self.Card1,self.Card2}
end

function XUiLottoTanchuang:OnEnable()
    self:ShowPanel()
end

function XUiLottoTanchuang:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiLottoTanchuang:OnBtnCloseClick()
    self:Close()
end

function XUiLottoTanchuang:ShowPanel()
    local ruleCfg = XLottoConfigs.GetLottoBuyTicketRuleById(self.DrawData:GetBuyTicketRuleId())
    if not ruleCfg then
        self:Close()
        return
    end
    local itemIds = {}
    
    for key=1,UseItemMax do
        local itemId = ruleCfg.UseItemId[key]

        if XTool.IsNumberValid(itemId) then
            local useItemData = {}
            useItemData.ItemId = itemId
            useItemData.Sale = ruleCfg.Sale[key]
            useItemData.ItemCount = ruleCfg.UseItemCount[key]
            useItemData.ItemImg = ruleCfg.UseItemImg[key]
            self.UseItem[key] = XUiGridTicket.New(self.UseCard[key], useItemData, function()
                self:BuyTicket(self.DrawData:GetId(), self.DrawData:GetBuyTicketRuleId(), key)
            end)
            table.insert(itemIds, useItemData.ItemId)
        end
        
    end
    
    local targetItemData = {}
    targetItemData.ItemId = self.DrawData:GetConsumeId()
    targetItemData.ItemCount = ruleCfg.TargetItemCount
    targetItemData.ItemImg = ruleCfg.TargetItemImg
    self.TargetItem = XUiGridTicket.New(self.TargetCard, targetItemData)

    if not XTool.IsTableEmpty(itemIds) then
        XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            for _, v in pairs(self.UseItem) do
                v:ShowPanel()
            end
        end, self)
    end
end

function XUiLottoTanchuang:BuyTicket(lottoId, BuyTicketRuleId, ticketKey)
    XDataCenter.LottoManager.BuyTicket(lottoId, BuyTicketRuleId, ticketKey, function (rewardList)
        XUiManager.OpenUiObtain(rewardList, nil, function ()
            self:OnBtnCloseClick()
            XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET)
        end)
    end)
end