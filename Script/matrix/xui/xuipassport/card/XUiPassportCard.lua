local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPassportCardGrid = require("XUi/XUiPassport/Card/XUiPassportCardGrid")

---@field _Control XPassportControl
---@class UiPassportCard:XLuaUi
local XUiPassportCard = XLuaUiManager.Register(XLuaUi, "UiPassportCard")

local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert

--购买通行证
function XUiPassportCard:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.HongKa)
    self:RegisterButtonEvent()

    self:InitTextBuyCaption()
end

function XUiPassportCard:OnStart(passportId, closeCb)
    self.PassportId = passportId
    self.CloseCb = closeCb

    self.DynamicTable = XDynamicTableNormal.New(self.PanelIconList.transform)
    self.DynamicTable:SetProxy(XUiPassportCardGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.PanelBagItem.gameObject:SetActive(false)
    self:UpdateDynamicTable(passportId)

    self:UpdateDesc(passportId)
    self:UpdateFashionShow(passportId)
    self:InitBtnXqActive(passportId)
end

function XUiPassportCard:OnEnable()
    self:Refresh()
end

function XUiPassportCard:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiPassportCard:InitTextBuyCaption()
    local time = self._Control:GetPassportBuyPassPortEarlyEndTime()
    local timeDesc = time > 0 and XUiHelper.GetTimeDesc(time, 2) or 0 .. CSXTextManagerGetText("Second")
    timeDesc = string.gsub(timeDesc, " ", "")
    local buyCaptionDesc = CSXTextManagerGetText("PassportBuyCaptionDesc", timeDesc)
    self.TextBuyTime.text = buyCaptionDesc
end

function XUiPassportCard:InitBtnXqActive(passportId)
    local fashionId = self._Control:GetPassportBuyFashionShowFashionId(passportId)
    self.BtnXq.gameObject:SetActiveEx(XTool.IsNumberValid(fashionId))
end

function XUiPassportCard:Refresh()
    local passportId = self:GetPassportId()
    local isUnLock = self._Control:GetPassportInfos(passportId) and true or false
    self.BtnBuy:SetDisable(isUnLock, not isUnLock)

    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local costItemName = ""     --策划需求，不显示道具名字
    local btnName = isUnLock and CSXTextManagerGetText("AlreadyBuy") or CSXTextManagerGetText("PassportBtnBuyPassportDesc", costItemCount, costItemName)
    self.BtnBuy:SetName(btnName)

    if self.IconBtnBuy then
        local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
        self.IconBtnBuy:SetRawImage(costItemIcon)
        self.IconBtnBuy.gameObject:SetActiveEx(not isUnLock)
    end
end

function XUiPassportCard:UpdateFashionShow(passportId)
    local isHavePassportId = XTool.IsNumberValid(passportId)
    if isHavePassportId then
        local icon = self._Control:GetPassportBuyFashionShowIcon(passportId)
        self.RImgShow:SetRawImage(icon)
    end

    self.RImgShow.gameObject:SetActiveEx(isHavePassportId)
end

function XUiPassportCard:UpdateDesc(passportId)
    self.TxtName.text = self._Control:GetPassportTypeInfoName(passportId)

    local icon = self._Control:GetPassportTypeInfoIcon(passportId)
    self.RImgIcon:SetRawImage(icon)

    local buyDesc = self._Control:GetPassportTypeInfoBuyDesc(passportId)
    self.TxtMessage.text = string.gsub(buyDesc, "\\n", "\n")
end

function XUiPassportCard:UpdateDynamicTable(passportId)
    self.BuyRewardShowIdList = self._Control:GetBuyRewardShowIdList(passportId)
    self.DynamicTable:SetDataSource(self.BuyRewardShowIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPassportCard:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local passportRewardId = self.BuyRewardShowIdList[index]
        grid:Refresh(passportRewardId)
    end
end

function XUiPassportCard:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnXq, self.OnBtnXqClick)
    self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
end

function XUiPassportCard:OnBtnXqClick()
    local passportId = self:GetPassportId()
    local fashionId = self._Control:GetPassportBuyFashionShowFashionId(passportId)
    local isWeaponFahion = self._Control:IsPassportBuyFashionShowIsWeaponFahion(passportId)
    XLuaUiManager.Open("UiFashionDetail", fashionId, isWeaponFahion)
end

function XUiPassportCard:OnBtnBuyClick()
    local passportId = self:GetPassportId()
    if not self._Control:CheckStopToBuyBeforeTheEnd() then
        return
    end
    
    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local haveCostItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local passportName = self._Control:GetPassportTypeInfoName(passportId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local title = CSXTextManagerGetText("BuyConfirmTipsTitle")
    local desc = CSXTextManagerGetText("PassportBuyPassportTipsDesc", costItemCount, costItemName, passportName)
    local sureCallback = function()
        if haveCostItemCount < costItemCount then
            -- XUiManager.TipText("ShopItemHongKaNotEnough")
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
            return
        end
        self._Control:RequestPassportBuyPassport(passportId, handler(self, self.Refresh))
    end

    XUiManager.DialogTip(title, desc, nil, nil, sureCallback)
end

function XUiPassportCard:GetPassportId()
    return self.PassportId
end