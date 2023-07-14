
local XUiMoeWarShopItem = XLuaUiManager.Register(XLuaUi, "UiMoeWarShopItem")
local MAX_COUNT = XMoeWarConfig.MAX_NAMEPLATE_BUY_COUNT --最大购买数
local ColorRed = CS.XGame.ClientConfig:GetString("ShopCanNotBuyColor")
local ColorBlack = CS.XGame.ClientConfig:GetString("ShopCanBuyColor")
local XUiGridMoeWarNameplate = require("XUi/XUiMoeWar/ChildItem/XUiGridMoeWarNameplate")

function XUiMoeWarShopItem:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiMoeWarShopItem:OnStart(data, cb)
    self.Data = data
    self.CallBack = cb
    
    self:InitView()
end 

function XUiMoeWarShopItem:InitUi()
    self.BtnMax:SetDisable(true)
    self.BtnAddSelect:SetDisable(true)
    self.BtnMinusSelect:SetDisable(true)
    self.TxtSelect.characterLimit = 4
    self.TxtSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
    
    
    self.PanelCostItem2.gameObject:SetActiveEx(false)
    self.PanelCostItem3.gameObject:SetActiveEx(false)
    self.Grid = XUiGridMoeWarNameplate.New(self.GridBuyCommon, self)
end

function XUiMoeWarShopItem:InitCb()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.TxtSelect.onValueChanged:AddListener(function() self:OnInputTextValueChange() end)
    self.BtnUse.CallBack = function() self:OnBtnUseClick() end
end 

function XUiMoeWarShopItem:InitView()
    self:RefreshCanBuy()
    self:RefreshCommon()
    self:RefreshPrice()
end 

function XUiMoeWarShopItem:RefreshCommon()
    self.RImgType.gameObject:SetActiveEx(false)
    self.Grid:Refresh(self.Data.Id)
end 

function XUiMoeWarShopItem:RefreshPrice()
    self.RImgCostIcon1:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(self.Data.CostItemId))
    self.TxtCostCount1.text = self.Data.CostItemCount
    local costHaveCount = XDataCenter.ItemManager.GetCount(self.Data.CostItemId)
    self.TxtCostCount1.color = costHaveCount >= tonumber(self.Data.CostItemCount) 
            and XUiHelper.Hexcolor2Color(ColorBlack) or XUiHelper.Hexcolor2Color(ColorRed)
end

function XUiMoeWarShopItem:RefreshCanBuy()
    local unlock = XDataCenter.MoeWarManager.CheckHaveNameplateById(self.Data.Id)
    self.TxtSelect.text = unlock and 0 or MAX_COUNT
    self.TxtCanBuy.text = unlock and 0 or MAX_COUNT
    local count = unlock and MAX_COUNT or 0
    self.TxtOwnCount.text = CS.XTextManager.GetText("CurrentlyHas", count)
end

function XUiMoeWarShopItem:OnInputTextValueChange()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        return
    end
    if self.TxtSelect.text == "0" then
        self.TxtSelect.text = 1
    end
    local tmp = tonumber(self.TxtSelect.text)
    local tmpMax = math.min(MAX_COUNT, tmp)
    if tmp > tmpMax then
        tmp = tmpMax
        self.TxtSelect.text = tmp
    end
end 

function XUiMoeWarShopItem:OnBtnUseClick()
    local unlock =  XDataCenter.MoeWarManager.CheckHaveNameplateById(self.Data.Id)
    if unlock then
        XUiManager.TipText("ShopHaveNotBuyCount")
        return
    end
    local costHaveCount = XDataCenter.ItemManager.GetCount(self.Data.CostItemId)
    if costHaveCount < tonumber(self.Data.CostItemCount) then
        XUiManager.TipText("BuyNeedItemInsufficient")
        return
    end
    
    XDataCenter.MoeWarManager.BuyNameplate(self.Data.Id, function()
        if self.CallBack then self.CallBack() end
        XUiManager.TipText("BuySuccess")
        XLuaUiManager.Remove("UiMoeWarShopItem")
    end)
    
end 