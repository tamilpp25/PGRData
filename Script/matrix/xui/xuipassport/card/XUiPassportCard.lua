local XUiPassportCardGrid = require("XUi/XUiPassport/Card/XUiPassportCardGrid")

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
    self.DynamicTable:SetProxy(XUiPassportCardGrid)
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
    local time = XPassportConfigs.GetPassportBuyPassPortEarlyEndTime()
    local timeDesc = time > 0 and XUiHelper.GetTimeDesc(time, 2) or 0 .. CSXTextManagerGetText("Second")
    timeDesc = string.gsub(timeDesc, " ", "")
    local buyCaptionDesc = CSXTextManagerGetText("PassportBuyCaptionDesc", timeDesc)
    self.TextBuyTime.text = buyCaptionDesc
end

function XUiPassportCard:InitBtnXqActive(passportId)
    local fashionId = XPassportConfigs.GetPassportBuyFashionShowFashionId(passportId)
    self.BtnXq.gameObject:SetActiveEx(XTool.IsNumberValid(fashionId))
end

function XUiPassportCard:Refresh()
    local passportId = self:GetPassportId()
    local isUnLock = XDataCenter.PassportManager.GetPassportInfos(passportId) and true or false
    self.BtnBuy:SetDisable(isUnLock, not isUnLock)

    local costItemId = XPassportConfigs.GetPassportTypeInfoCostItemId(passportId)
    local costItemCount = XPassportConfigs.GetPassportTypeInfoCostItemCount(passportId)
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
        local icon = XPassportConfigs.GetPassportBuyFashionShowIcon(passportId)
        self.RImgShow:SetRawImage(icon)
    end

    self.RImgShow.gameObject:SetActiveEx(isHavePassportId)
end

function XUiPassportCard:UpdateDesc(passportId)
    self.TxtName.text = XPassportConfigs.GetPassportTypeInfoName(passportId)

    local icon = XPassportConfigs.GetPassportTypeInfoIcon(passportId)
    self.RImgIcon:SetRawImage(icon)

    local buyDesc = XPassportConfigs.GetPassportTypeInfoBuyDesc(passportId)
    self.TxtMessage.text = string.gsub(buyDesc, "\\n", "\n")
end

function XUiPassportCard:UpdateDynamicTable(passportId)
    self.BuyRewardShowIdList = XPassportConfigs.GetBuyRewardShowIdList(passportId)
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
    local fashionId = XPassportConfigs.GetPassportBuyFashionShowFashionId(passportId)
    local isWeaponFahion = XPassportConfigs.IsPassportBuyFashionShowIsWeaponFahion(passportId)
    XLuaUiManager.Open("UiFashionDetail", fashionId, isWeaponFahion)
end

function XUiPassportCard:OnBtnBuyClick()
    local passportId = self:GetPassportId()
    local costItemId = XPassportConfigs.GetPassportTypeInfoCostItemId(passportId)
    local haveCostItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local costItemCount = XPassportConfigs.GetPassportTypeInfoCostItemCount(passportId)
    local passportName = XPassportConfigs.GetPassportTypeInfoName(passportId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local title = CSXTextManagerGetText("BuyConfirmTipsTitle")
    local desc = CSXTextManagerGetText("PassportBuyPassportTipsDesc", costItemCount, costItemName, passportName)
    local sureCallback = function()
        if haveCostItemCount < costItemCount then
            -- XUiManager.TipText("ShopItemHongKaNotEnough")
            if XUiHelper.CanBuyInOtherPlatformHongKa(costItemCount) then
                XUiHelper.BuyInOtherPlatformHongka()
                return
            end
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
            return
        end
        XDataCenter.PassportManager.RequestPassportBuyPassport(passportId, handler(self, self.Refresh))
    end

    XUiManager.DialogTip(title, desc, nil, nil, sureCallback)
end

function XUiPassportCard:GetPassportId()
    return self.PassportId
end