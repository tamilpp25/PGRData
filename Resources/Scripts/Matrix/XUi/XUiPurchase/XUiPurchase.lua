local Object = CS.UnityEngine.Object
local Next = _G.next
local XUiPurchase = XLuaUiManager.Register(XLuaUi, "UiPurchase")
-- local TabsConfig
local PanelNameConfig
local PanelExNameConfig
local LBUiTypes
local YKUiTypes

local TabExConfig
local UITypeCfg = {}
local XUiPurchasePay = require("XUi/XUiPurchase/XUiPurchasePay")
local XUiPurchasePayAdd = require("XUi/XUiPurchase/XUiPurchasePayAdd")
local XUiPurchaseLB = require("XUi/XUiPurchase/XUiPurchaseLB")
local XUiPurchaseYK = require("XUi/XUiPurchase/XUiPurchaseYK")
-- local XUiPurchaseHK = require("XUi/XUiPurchase/XUiPurchaseHK")
local XUiPurchaseHKShop = require("XUi/XUiPurchase/XUiPurchaseHKShop")
local XUiPurchaseHKExchange = require("XUi/XUiPurchase/XUiPurchaseHKExchange")
local XUiPurchaseCoatingLB = require("XUi/XUiPurchase/XUiPurchaseCoatingLB")
local XUiPurchaseDetail = require("XUi/XUiPurchase/XUiPurchaseDetail")

local lastTab = nil;

-- BtnLzcj = 累计充值、LB = 礼包、YK = 月卡、HK = 虹卡

local YKUiType = 3

function XUiPurchase:OnAwake()
    -- TabsConfig = XPurchaseConfigs.TabsConfig
    PanelNameConfig = XPurchaseConfigs.PanelNameConfig
    PanelExNameConfig = XPurchaseConfigs.PanelExNameConfig
    -- TabExConfig = XPurchaseConfigs.TabExConfig
    self:GetLBUiTypesList()
    self:GetYKUiTypesList()
    UITypeCfg = XPurchaseConfigs.GetTabControlUiTypeConfig()
    self:InitUi()
    XRedPointManager.AddRedPointEvent(self.GameObject, self.LBRedPoint, self, {XRedPointConditions.Types.CONDITION_PURCHASE_LB_RED})
    XRedPointManager.AddRedPointEvent(self.GameObject, self.AccumulateRedPoint, self, {XRedPointConditions.Types.CONDITION_ACCUMULATE_PAY_RED})
end

function XUiPurchase:OnEnable()
    if self.CurUiView then
        self.CurUiView:ShowPanel()
    end
    XEventManager.AddEventListener(XEventId.EVENT_ACCUMULATED_UPDATE,self.OnAccumulatedUpdate,self)
    XEventManager.AddEventListener(XEventId.EVENT_ACCUMULATED_REWARD,self.OnAccumulatedGeted,self)
end

function XUiPurchase:GetYKUiTypesList()
    local t = XPurchaseConfigs.GetYKUiTypes()
    YKUiTypes = {}
    for _,v in pairs(t)do
        YKUiTypes[v] = v
    end
end

function XUiPurchase:OnStart(tab, isClearData, childTabIndex)
    self.IsClearData = isClearData
    if isClearData == nil then
        self.IsClearData = true
    end

    self.ChildTabIndex = childTabIndex or 1

    XDataCenter.PurchaseManager.GetPurchaseListRequest(XPurchaseConfigs.GetLBUiTypesList())
    local t = tab or 1
    self:OnStartSelTab(t)

    local flag = XDataCenter.PurchaseManager.IsAccumulateEnterOpen()
    self.BtnLjcz.gameObject:SetActive(flag)
    if flag then
        local f = XDataCenter.PurchaseManager.AccumulatePayRedPoint()
        self.BtnLjcz:ShowReddot(f)
    end
end

function XUiPurchase:AddListener()
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClick)
    self:RegisterClickEvent(self.BtnLjcz, self.OnBtnPayAddClick)
    self.BtnDetail.CallBack = function()
        self:OnBtnDetailClick()
    end
    self:RegisterClickEvent(self.BtnLaw1, self.OnBtnLaw1)
    self:RegisterClickEvent(self.BtnLaw2, self.OnBtnLaw2)
end

function XUiPurchase:OnBtnLaw1()
    local lawTxt = CS.XTextManager.GetText("Capitaldecisionmethod")
    local lawTitle = CS.XTextManager.GetText("CapitaldecisionmethodTitle")
    XLuaUiManager.Open("UiFubenDialog", lawTitle, lawTxt)
end

function XUiPurchase:OnEnable()
    if self.CurUiView then
        self.CurUiView:ShowPanel()
    end
    XEventManager.AddEventListener(XEventId.EVENT_ACCUMULATED_UPDATE,self.OnAccumulatedUpdate,self)
    XEventManager.AddEventListener(XEventId.EVENT_ACCUMULATED_REWARD,self.OnAccumulatedGeted,self)
end

function XUiPurchase:OnGetEvents()
end

function XUiPurchase:OnNotify()
end

function XUiPurchase:OnBtnReturnClick()
    self:Close()
end

function XUiPurchase:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPurchase:OnBtnPayAddClick()
    self.PanelLjcz.gameObject:SetActive(true)
    self:PlayAnimation("PanelLjczEnable")
    self.UiPurchasePayAdd:OnRefresh()
end

function XUiPurchase:GetLBUiTypesList()
    local t = XPurchaseConfigs.GetLBUiTypesList()
    LBUiTypes = {}
    for _,v in pairs(t)do
        LBUiTypes[v] = v
    end
end

function XUiPurchase:IsYKUiType(cfg)
    if Next(cfg) then
        for _, v in pairs(cfg)do
            if YKUiTypes[v.UiType] then
                return true
            end
        end
    end
end

function XUiPurchase:InitUi()
    self.TabBtns = {}
    self.LBtnIndex = {}

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAssetPay, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)

    local groupTabBtns = {}
    self.TabsCfg = XPurchaseConfigs.GetGroupConfigType()
    self.TabGroup = self.PanelTopTabGroup:GetComponent("XUiButtonGroup")
    for _, v in ipairs(self.TabsCfg) do
        local btn = Object.Instantiate(self.BtnPayTab)
        btn.gameObject:SetActive(true)
        -- btn.gameObject:SetActive(v.GroupId ~= 1)
        btn.transform:SetParent(self.PanelTopTabGroup.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        btncs:SetName(v.GroupName)
        local iconPath = XPurchaseConfigs.GetIconPathByIconName(v.GroupIcon)
        if iconPath and iconPath.AssetPath then
            btn:SetRawImage(iconPath.AssetPath)
        end
        if self:IsLBUiType(v.Childs) then
            btn:ShowReddot(XDataCenter.PurchaseManager.LBRedPoint())
            self.LBBtn = btn
        elseif self:IsYKUiType(v.Childs) then
            btn:ShowReddot(XDataCenter.PurchaseManager.CheckYKContinueBuy())
        else
            btn:ShowReddot(false)
        end
        table.insert(groupTabBtns, btncs)
    end

    self.TabGroup:Init(groupTabBtns, function(tab) self:TabSkip(tab) end)

    local purchaseLBCb = function(skipIndex)
        self:OnStartSelTab(skipIndex)
    end

    self.LuaUIs = {}
    self.LuaUIs[PanelNameConfig.PanelRecharge] = XUiPurchasePay.New(self.PanelRecharge,self,XPurchaseConfigs.TabExConfig.Sample)
    self.LuaUIs[PanelNameConfig.PanelLb] = XUiPurchaseLB.New(self.PanelLb,self, purchaseLBCb)
    --self.UiPanel[PanelNameConfig.PanelYk] = XUiPurchaseYK.New(self.PanelYk,self)
    self.LuaUIs[PanelNameConfig.PanelDh] = XUiPurchaseHKExchange.New(self.PanelDh,self)
    self.LuaUIs[PanelNameConfig.PanelHksd] = XUiPurchaseHKShop.New(self.PanelHksd,self)
    self.LuaUIs[PanelNameConfig.PanelDh] = XUiPurchaseHKExchange.New(self.PanelDh,self)
    
    self.LuaUIs[PanelExNameConfig.PanelRecharge] = XUiPurchasePay.New(self.PanelRechargeEx,self,XPurchaseConfigs.TabExConfig.EXTable)
    self.LuaUIs[PanelExNameConfig.PanelLb] = XUiPurchaseLB.New(self.PanelLbEx,self, purchaseLBCb)
    self.LuaUIs[PanelExNameConfig.PanelYk] = XUiPurchaseYK.New(self.PanelYkEx,self)
    
    self.LuaUIs[PanelExNameConfig.PanelHksd] = XUiPurchaseHKShop.New(self.PanelHksdEx,self)
    self.LuaUIs[PanelExNameConfig.PanelCoatingLb] = XUiPurchaseCoatingLB.New(self.PanelCoatingLbEx, self, purchaseLBCb)

    self.LuaUIs[PanelExNameConfig.PanelHksd] = XUiPurchaseHKShop.New(self.PanelHksdEx,self)
    self.LuaUIs[PanelExNameConfig.PanelCoatingLb] = XUiPurchaseCoatingLB.New(self.PanelCoatingLbEx, self, purchaseLBCb)

    self.UiPurchasePayAdd = XUiPurchasePayAdd.New(self.PanelLjcz,self)
    self.UiPanelDetail = XUiPurchaseDetail.New(self.PanelDetail, self, function()
        self:ClosePanelDetail()
    end)
    self:AddListener()
end

function XUiPurchase:SetData()
    local cfg = self.TabsCfg[self.CurGroupTab]
    if not cfg then
        return
    end

    local names = XPurchaseConfigs.PanelNameConfig
    local childs = cfg.Childs or {}
    if #childs > 1 then
        -- names = XPurchaseConfigs.PanelExNameConfig
        self.Panels.gameObject:SetActive(false)
        self.PanelsEx.gameObject:SetActive(true)
        self.ImgBgEx.gameObject:SetActive(true)
        self.PanelTabGroup.gameObject:SetActive(true)
        self:InitGroupTab(self.CurUiTypes)
        if self.IsStartAnimation then
            self.IsStartAnimation = false
            self:PlayAnimation("AnimEnableSmall")
        else
            self:PlayAnimation("QieHuanSmall")
        end
    else
        self.PanelTabGroup.gameObject:SetActive(false)
        self.ImgBgEx.gameObject:SetActive(false)
        self.Panels.gameObject:SetActive(true)
        self.PanelsEx.gameObject:SetActive(false)
        for k,v in pairs(names)do
            if k ~= self.CurUiNames[k] then
                if self.LuaUIs[k] then
                    self.LuaUIs[k]:HidePanel()
                end
            else
                self.CurUiView = self.LuaUIs[v]
                self.CurUiView:ShowPanel()
                self.CurUiView:OnRefresh(self.CurUiTypes[1])
            end
        end
        if self.IsStartAnimation then
            self.IsStartAnimation = false
            self:PlayAnimation("AnimEnableBig")
        else
            self:PlayAnimation("QieHuanBig")
        end
    end
end

function XUiPurchase:TabSkip(tab)
    if self.CurGroupTab == tab then
        return
    end

    if tab == 4 then
        if self.CurGroupTab then
            self.TabGroup:SelectIndex(self.CurGroupTab);
        end
        XUiManager.TipText("EnPcRechargeCloseTip")
        XLog.Debug("暂时屏蔽充值入口");
        return;
    end

    local cfg = self.TabsCfg[tab]
    if not cfg then
        return
    end
    local childs = cfg.Childs or {}
    if Next(childs) == nil then
        return
    end

    self.CurGroupTab = tab
    self.SingleTab  = nil

    local names = XPurchaseConfigs.PanelNameConfig
    local sendUiTypes = {}
    self.CurUiTypes = {}
    self.CurUiNames = {}

    -- 充值的读表不需后端数据
    local payUiTypes = XPurchaseConfigs.GetPayUiTypes()
    for _, v in pairs(childs) do
        if not payUiTypes[v.UiType] then
            table.insert(sendUiTypes, v.UiType)
        end

        table.insert(self.CurUiTypes, v.UiType)
        local cfg = XPurchaseConfigs.GetUiTypeConfigByType(v.UiType)

        if cfg and cfg.UiPrefabStyle then
            self.CurUiNames[cfg.UiPrefabStyle] = cfg.UiPrefabStyle
        end
    end
    if self.CurUiView then
        self.CurUiView:HidePanel()
    end

    if Next(sendUiTypes) ~= nil then
        if XDataCenter.PurchaseManager.IsHaveDataByUiTypes(sendUiTypes) then
            self:SetData()
        else
            XDataCenter.PurchaseManager.GetPurchaseListRequest(sendUiTypes,function()
                self:SetData()
            end)
        end
    else
        if #childs > 1 then
            -- names = XPurchaseConfigs.PanelExNameConfig
            self.Panels.gameObject:SetActive(false)
            self.PanelsEx.gameObject:SetActive(true)
            self.ImgBgEx.gameObject:SetActive(true)
            self.PanelTabGroup.gameObject:SetActive(true)
            self:InitGroupTab(self.CurUiTypes)
            if self.IsStartAnimation then
                self.IsStartAnimation = false
                self:PlayAnimation("AnimEnableSmall")
            else
                self:PlayAnimation("QieHuanSmall")
            end
        else
            self.PanelTabGroup.gameObject:SetActive(false)
            self.ImgBgEx.gameObject:SetActive(false)
            self.Panels.gameObject:SetActive(true)
            self.PanelsEx.gameObject:SetActive(false)
            for k,v in pairs(names)do
                if k ~= self.CurUiNames[k] then
                    self.LuaUIs[k]:HidePanel()
                else
                    self.CurUiView = self.LuaUIs[v]
                    self.CurUiView:ShowPanel()
                    self.CurUiView:OnRefresh(self.CurUiTypes[1])
                end
            end
            if self.IsStartAnimation then
                self.IsStartAnimation = false
                self:PlayAnimation("AnimEnableBig")
            else
                self:PlayAnimation("QieHuanBig")
            end
        end
    end
end

function XUiPurchase:AccumulateRedPoint(result)
    if self.BtnLjcz then
        self.BtnLjcz:ShowReddot(result >= 0)
    end
end

function XUiPurchase:LBRedPoint(result)
    if self.LBBtn then
        self.LBBtn:ShowReddot(result >= 0)
    end

    local LbRedUiTypes = XDataCenter.PurchaseManager.LBRedPointUiTypes()
    if self.Btns and Next(self.LBtnIndex) and Next(LbRedUiTypes) then
        for index,uiType in pairs(self.LBtnIndex)do
            if uiType and self.Btns[index] then
                self.Btns[index]:ShowReddot(LbRedUiTypes[uiType] ~= nil)
            end
        end
    else
        if self.Btns and Next(self.Btns) then
            for _,btn in pairs(self.Btns)do
                if btn then
                    btn:ShowReddot(false)
                end
            end
        end
    end
end

-- [监听动态列表事件]
function XUiPurchase:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end


function XUiPurchase:OnStartSelTab(t)
    local uiTypes = XPurchaseConfigs.GetUiTypesByTab(t)
    local cfg = self.TabsCfg
    local index = 1
    for k, v in pairs(cfg)do
        local childs = v.Childs
        for _,c in pairs(childs)do
            for _,a in pairs(uiTypes)do
                if a.UiType == c.UiType then
                    index = k
                    break
                end
            end
        end
    end

    self.IsStartAnimation = true
    self:TabSkip(index)
    self.TabGroup:SelectIndex(index)
end

function XUiPurchase.UiTypeTabSort(a,b)
    if UITypeCfg[a] and UITypeCfg[b] then
        return UITypeCfg[a].GroupOrder < UITypeCfg[b].GroupOrder
    end
    return false
end

function XUiPurchase:InitGroupTab(uiTypes)
    if not self.Btns then
        self.Btns = {}
    end

    self.LBtnIndex = {}
    local LbRedUiTypes = XDataCenter.PurchaseManager.LBRedPointUiTypes()
    local i = 0
    for k, v in pairs(uiTypes) do
        local purchaseUiTypeConfig = XPurchaseConfigs.GetUiTypeConfigByType(v)
        local data = XDataCenter.PurchaseManager.GetDatasByUiType(v)
        local isYKType = purchaseUiTypeConfig and purchaseUiTypeConfig.GroupType == YKUiType
        if isYKType and (data == nil or #data == 0) then
            goto continue
        end
        
        if not self.TabBtns[k] then
            local btn = Object.Instantiate(self.BtnTab)
            btn.transform:SetParent(self.PanelTabGroup.transform, false)
            self.Btns[k] = btn
            local btncs = btn:GetComponent("XUiButton")
            self.TabBtns[k] = btncs
        end
        if LbRedUiTypes and LbRedUiTypes[v] then
            self.Btns[k]:ShowReddot(true)
            self.LBtnIndex[k] = v
        else
            self.Btns[k]:ShowReddot(false)
        end
        self.Btns[k].gameObject:SetActive(true)
        self.TabBtns[k]:SetName(UITypeCfg[v].Name)
        i = i + 1

        :: continue ::
    end

    local len = #self.Btns
    if i < len then
        for index = i+1, len do
            self.Btns[index].gameObject:SetActive(false)
        end
    end

    self.GroupTabgroup:Init(self.TabBtns, function(tab) self:GroupTabSkip(tab) end)
    if next(self.TabBtns) ~= nil then
        self.GroupTabgroup:SelectIndex(self.ChildTabIndex)
    end
end

function XUiPurchase:GroupTabSkip(tab)
    if self.SingleTab == tab then
        return
    end
    if self.CurGroupTab == 2 then
        local tempTab = {}
        table.insert(tempTab, XPurchaseConfigs.YKType.Day)
        XDataCenter.PurchaseManager.GetPurchaseListRequest(tempTab, function()
                self.ChildTabIndex = tab
                self:InitGroupTab({XPurchaseConfigs.YKType.Month, XPurchaseConfigs.YKType.Week, XPurchaseConfigs.YKType.Day})
            end)
    end

    local cfgs = self.TabsCfg[self.CurGroupTab]
    if not cfgs or not cfgs.Childs[tab] then
        return
    end

    local cfg = XPurchaseConfigs.GetUiTypeConfigByType(cfgs.Childs[tab].UiType)
    if not cfg or not cfg.UiPrefabStyle then
        return
    end

    self.SingleTab = tab

    if self.CurUiView then
        self.CurUiView:HidePanel()
    end

    local n = PanelExNameConfig[cfg.UiPrefabStyle]
    self.CurUiView = self.LuaUIs[n]
    self.CurUiView:ShowPanel()
    self.CurUiView:OnRefresh(cfg.UiType)
    self:PlayAnimation("QieHuanSmall")
end


function XUiPurchase:OnAccumulatedUpdate()
end

function XUiPurchase:OnAccumulatedGeted()
    self.UiPurchasePayAdd:SetListData()
end

function XUiPurchase:OnDisable()
    if self.CurUiView then
        self.CurUiView:HidePanel()
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_ACCUMULATED_UPDATE,self.OnAccumulatedUpdate,self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ACCUMULATED_REWARD, self.OnAccumulatedGeted,self)
end

function XUiPurchase:OnDestroy()
    self.Btns = nil
    if self.IsClearData then
        XDataCenter.PurchaseManager.ClearData()
    end

    for _,panel in pairs(self.LuaUIs) do
        if panel.BuyUiTips then
            panel.BuyUiTips:OnDestroy()
        end
    end
end

function XUiPurchase:IsLBUiType(cfg)
    if Next(cfg) then
        for _, v in pairs(cfg)do
            if LBUiTypes[v.UiType] then
                return true
            end
        end
    end
    return false
end

function XUiPurchase:IsYKUiType(cfg)
    if Next(cfg) then
        for _, v in pairs(cfg)do
            if YKUiTypes[v.UiType] then
                return true
            end
        end
    end
    return false
end

