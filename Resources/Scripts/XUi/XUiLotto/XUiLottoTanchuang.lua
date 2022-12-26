local XUiLottoTanchuang = XLuaUiManager.Register(XLuaUi, "UiLottoTanchuang")
local XUiGridTicket = require("XUi/XUiLotto/XUiGridTicket")
local UseItemMax = 2
function XUiLottoTanchuang:OnStart(data, cb)
    self.DrawData = data
    self.CallBack = cb
    self:SetButtonCallBack()
    self.UseItem = {}
    self.TargetItem = {}
    self.UseCard = {self.Card1,self.Card2}
    self:ShowPanel()
end

function XUiLottoTanchuang:OnEnable()
    self:RefreshCount()
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
    
    for key=1,UseItemMax do
        local useItemData = {}
        useItemData.ItemId = ruleCfg.UseItemId[key]
        useItemData.Sale = ruleCfg.Sale[key]
        useItemData.ItemCount = ruleCfg.UseItemCount[key]
        useItemData.ItemImg = ruleCfg.UseItemImg[key]
        self.UseItem[key] = XUiGridTicket.New(self.UseCard[key], useItemData, function()
            -- if useItemData.ItemId and useItemData.ItemId == 3 then --这里的3是指黑卡
                self:BuyTicket(self.DrawData:GetId(), self.DrawData:GetBuyTicketRuleId(), key)
            -- else
                -- XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 1)
            -- end
                
        end)
    end
    
    local targetItemData = {}
    targetItemData.ItemId = self.DrawData:GetConsumeId()
    targetItemData.ItemCount = ruleCfg.TargetItemCount
    targetItemData.ItemImg = ruleCfg.TargetItemImg
    self.TargetItem = XUiGridTicket.New(self.TargetCard, targetItemData)
end

function XUiLottoTanchuang:RefreshCount() --海外修改，购买黑卡后刷新黑卡数量
    for key=1,UseItemMax do
        if self.UseItem and self.UseItem[key] then
            self.UseItem[key]:ShowPanel()
        end
    end
end

function XUiLottoTanchuang:BuyTicket(lottoId, BuyTicketRuleId, ticketKey)
    XDataCenter.LottoManager.BuyTicket(lottoId, BuyTicketRuleId, ticketKey, function (rewardList)
            XUiManager.OpenUiObtain(rewardList, nil, function ()
                    self:OnBtnCloseClick()
                    if self.CallBack then self.CallBack() end
                end)
    end)
end