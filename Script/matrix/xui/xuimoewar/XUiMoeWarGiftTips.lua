--赠送礼物弹窗
local XUiMoeWarGiftTips = XLuaUiManager.Register(XLuaUi, "UiMoeWarGiftTips")

function XUiMoeWarGiftTips:OnAwake()
    self:AddListener()
end

function XUiMoeWarGiftTips:OnStart(helperId, receiveChatHandlerCb)
    self.HelperId = helperId
    self.ReceiveChatHandlerCb = receiveChatHandlerCb

    local itemId = XDataCenter.ItemManager.ItemId.MoeWarCommunicateItemId
    local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    local showAddMood = XDataCenter.MoeWarManager.GetGiftAddMoodValue(helperId)
    self.RImgIcon:SetRawImage(icon)
    self.TxtNumber.text = XDataCenter.MoeWarManager.GetOnceGiftAmount()
    self.TxtDesc.text = XUiHelper.ReadTextWithNewLine("MoeWarGiftTipsDesc", showAddMood)

    --当前拥有的道具数量
    self.RImgIconByOwn:SetRawImage(icon)
    self.TxtNumberByOwn.text = XDataCenter.ItemManager.GetCount(itemId)
end

function XUiMoeWarGiftTips:AddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiMoeWarGiftTips:OnBtnConfirmClick()
    self:Close()
    XDataCenter.MoeWarManager.RequestMoeWarPreparationHelperSendGift(self.HelperId, self.ReceiveChatHandlerCb)
end