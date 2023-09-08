local XUiFubenDailyShop = XLuaUiManager.Register(XLuaUi, "UiFubenDailyShop")
local SuitIdRecordCache = -1

function XUiFubenDailyShop:OnAwake()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiFubenDailyShop:OnStart(shopId, defaultSuitId)
    self.ShopId = shopId

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self, true)

    self.SuitShopItemDic = {}
    self.ShopItemList = XShopManager.GetShopGoodsList(self.ShopId)
    for _, v in ipairs(self.ShopItemList) do
        local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(v.RewardGoods.TemplateId)
        if not self.SuitShopItemDic[suitId] then
            self.SuitShopItemDic[suitId] = {}
        end
        table.insert(self.SuitShopItemDic[suitId], v)
    end

    local isShopAvailable = #self.ShopItemList > 0
    if isShopAvailable then
        self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
        local suitId = next(self.SuitShopItemDic)
        
        local existFunc = function(id)
            if not XTool.IsNumberValid(id) then
                return false
            end
            for k, _ in pairs(self.SuitShopItemDic) do
                if k == id then
                    return true
                end
            end
            return false
        end
        
        if XTool.IsNumberValid(defaultSuitId) then
            local exist = existFunc(defaultSuitId)
            local tmpSuitId = defaultSuitId
            if not exist then
                local tips =  XUiHelper.GetText("TypeWafer")
                XUiManager.TipMsg(XUiHelper.GetText("EquipGuideShopNoEquipTip", tips))
                exist = existFunc(SuitIdRecordCache)
                tmpSuitId = exist and SuitIdRecordCache or suitId
            end
            self:SelectPage(tmpSuitId)
        else
            local tmpSuitId = existFunc(SuitIdRecordCache) and SuitIdRecordCache or suitId
            self:SelectPage(tmpSuitId)
        end
    end

    self.TxtDesc.gameObject:SetActiveEx(not isShopAvailable)
    self.WaferNameGroup.gameObject:SetActiveEx(isShopAvailable)
    self.PanelActivityAsset.gameObject:SetActiveEx(isShopAvailable)

    self:AddRedPointEvent(self.BtnSwitch, self.OnCheckShopNew, self, { XRedPointConditions.Types.CONDITION_FUBEN_DAILY_SHOP }, self.ShopItemList)
end

function XUiFubenDailyShop:InitComponent()
    self.BtnSwitch.CallBack = function() self:OnBtnSwitchClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiFubenDailyShop:InitDynamicTable()
    self.DynamicShopTable = XDynamicTableNormal.New(self.PanelItemList.gameObject)
    self.DynamicShopTable:SetDelegate(self)
    self.DynamicShopTable:SetProxy(XUiGridShop)
end

function XUiFubenDailyShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local shopItemList = self.SuitShopItemDic[self.CurSuitId]
        local data = shopItemList[index]
        if data then
            grid:UpdateData(data)
        end
    end
end

function XUiFubenDailyShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb)
end

function XUiFubenDailyShop:RefreshBuy()
    local shopItemList = self.SuitShopItemDic[self.CurSuitId]
    for index, data in ipairs(shopItemList) do
        local grid = self.DynamicShopTable:GetGridByIndex(index)
        if grid then
            grid:UpdateData(data)
        end
    end
    self:UpdateUI()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.ShopId))
end

function XUiFubenDailyShop:SelectPage(suitId)
    self:PlayAnimation("AnimQieHuan")
    if suitId then
        self.CurSuitId = suitId
        XShopManager.GetShopInfo(self.ShopId, function()
            self.CurPageShopItemList = self:GetShopItemListBySuitId(suitId)
            self:RefreshShopList()
            self:UpdateUI()
        end)
    end
end

function XUiFubenDailyShop:GetShopItemListBySuitId(suitId)
    return self.SuitShopItemDic[suitId]
end

function XUiFubenDailyShop:RefreshShopList()
    self.DynamicShopTable:SetDataSource(self.CurPageShopItemList)
    self.DynamicShopTable:ReloadDataASync()
end

function XUiFubenDailyShop:UpdateUI()
    local suitCfg = XEquipConfig.GetEquipSuitCfg(self.CurSuitId)

    if suitCfg == nil then
        XLog.Error("suitCfg == nil, suitId = " .. self.CurSuitId)
        return
    end

    self.WaferNameText.text = suitCfg.Name
    self.PropertyText.text = suitCfg.Description

    self.TxtDesc.gameObject:SetActiveEx(#self.ShopItemList == 0)
    self.TxtTitle.text = XShopManager.GetShopName(self.ShopId)
end

function XUiFubenDailyShop:GetCurShopId()
    return self.ShopId
end

function XUiFubenDailyShop:OnCheckShopNew(count)
    self.BtnSwitch:ShowReddot(count >= 0)
end

function XUiFubenDailyShop:OnBtnSwitchClick()
    local callBack = function(suitId)
        if suitId then
            self:SelectPage(suitId)
        end
    end
    XLuaUiManager.Open("UiWaferSelect", self.CurSuitId, self.ShopItemList, self.SuitShopItemDic, callBack)
end

function XUiFubenDailyShop:OnBtnBackClick()
    self:Close()
end

function XUiFubenDailyShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenDailyShop:OnDestroy()
    SuitIdRecordCache = self.CurSuitId
end