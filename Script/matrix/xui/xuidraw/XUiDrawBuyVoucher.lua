local XUiDrawBuyVoucher = XLuaUiManager.Register(XLuaUi, "UiDrawBuyVoucher")


function XUiDrawBuyVoucher:OnAwake()
    self:InitAutoScript()
end

--voucherId 卡券Id
--ownAmount 拥有数量
--buyAmount 购买数量
--confirmCb 确定回调
function XUiDrawBuyVoucher:OnStart(voucherId, ownAmount, buyAmount, confirmCb)
    self.VoucherId = voucherId
    self.BuyAmount = buyAmount
    self.ConfirmCb = confirmCb
    local voucherTemplate = XDataCenter.ItemManager.GetItemTemplate(voucherId)
    local voucherName = voucherTemplate.Name
    local assetTemplate = XDataCenter.ItemManager.GetBuyAssetTemplate(voucherId, -1)
    local consumeCost = assetTemplate.ConsumeCount * buyAmount
    local consumeId = assetTemplate.ConsumeId
    local consumeTemplate = XDataCenter.ItemManager.GetItemTemplate(consumeId)
    local consumeName = consumeTemplate.Name
    self.ImgIcon:SetRawImage(voucherTemplate.Icon)
    self.TxtName.text = CS.XTextManager.GetText("DrawVoucherNotEnough", voucherName)
    self.TxtTip.text = CS.XTextManager.GetText("DrawBuyVoucherQuery", consumeCost, consumeName, buyAmount * assetTemplate.GainCount, voucherName)
    self.TxtCount.text = CS.XTextManager.GetText("DrawOwnVoucherAmount", ownAmount)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiDrawBuyVoucher:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiDrawBuyVoucher:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiDrawBuyVoucher:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiDrawBuyVoucher:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiDrawBuyVoucher:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end
-- auto
function XUiDrawBuyVoucher:OnBtnBackClick(...)
    self:OnBtnCancelClick(...)
end

function XUiDrawBuyVoucher:OnBtnCancelClick()
    self:Close()
end

function XUiDrawBuyVoucher:OnBtnBuyClick()
    self.ImgMask.gameObject:SetActive(true)
    XDataCenter.ItemManager.BuyAsset(self.VoucherId, function()
        self:Close()
        self.ConfirmCb()
    end, function()
        self.ImgMask.gameObject:SetActive(false)
    end, self.BuyAmount)
end