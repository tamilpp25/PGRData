local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiBuySecondConfirm = XLuaUiManager.Register(XLuaUi, "UiBuySecondConfirm")

function XUiBuySecondConfirm:OnAwake()
    self.Grid = XUiGridCommon.New(self, self.FurnitureBlueItem)
    self:AddOnClickListener()
end

function XUiBuySecondConfirm:OnStart(secondConfirmData)
    self.ConsumeId = secondConfirmData.ConsumeId
    self.ConsumeCount = secondConfirmData.ConsumeCount
    self.BuyCount = secondConfirmData.BuyCount
    self.TargetId = secondConfirmData.TargetId
    self.CancelCB = secondConfirmData.CancelCB
    self.ConfirmCB = secondConfirmData.ConfirmCB

    self:RefreshUi()
end

function XUiBuySecondConfirm:RefreshUi()
    -- 消耗的货币数量文本
    local consumeNum = self.ConsumeCount
    self.TxtConsumeCount.text = consumeNum
    -- 消耗的货币名称文本
    local consumeName = XDataCenter.ItemManager.GetItemName(self.ConsumeId)
    self.TxtConsumeName.text = consumeName
    -- 消耗的货币图标
    local consumeIconUrl = XDataCenter.ItemManager.GetItemIcon(self.ConsumeId)
    self.IconConsume:SetRawImage(consumeIconUrl)
    self.IconRemain:SetRawImage(consumeIconUrl)
    -- 剩下的货币数量文本
    local afterCoinNum = XShopManager.GetAfterSecondConfirmCoin(self.ConsumeId, self.ConsumeCount)
    self.AfterConfirmCount.text = afterCoinNum
    -- 购买的商品数量文本
    self.TxtTargetCount.text = XUiHelper.GetText("ShopGridCommonCount", self.BuyCount)
    -- 购买的商品名称文本
    self.TxtTargetName.text = XDataCenter.ItemManager.GetItemName(self.TargetId)
    -- 购买的商品图标
    self.Grid:Refresh(self.TargetId)
end

function XUiBuySecondConfirm:AddOnClickListener()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCancelClick)
end

-- 确认
function XUiBuySecondConfirm:OnBtnConfirmClick()
    self:Close()
    if self.ConfirmCB then
        self.ConfirmCB()
    end

    self.CancelCB = nil
    self.ConfirmCB = nil
end

-- 取消或关闭
function XUiBuySecondConfirm:OnBtnCancelClick()
    self:Close()
    if self.CancelCB then
        self.CancelCB()
    end

    self.CancelCB = nil
    self.ConfirmCB = nil
end