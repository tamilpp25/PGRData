local Object = CS.UnityEngine.Object
local Next = _G.next
local XUiPurchase = XLuaUiManager.Register(XLuaUi, "UiPurchase")
-- local TabsConfig
local PanelNameConfig
local PanelExNameConfig
local LBUiTypes
local YKUiTypes
-- local TabExConfig
local UiTypeCfg = {}
local XUiPurchasePay = require("XUi/XUiPurchase/XUiPurchasePay")
local XUiPurchaseLB = require("XUi/XUiPurchase/XUiPurchaseLB")
local XUiPurchaseYK = require("XUi/XUiPurchase/XUiPurchaseYK")
local XUiPurchaseYKList = require("XUi/XUiPurchase/XUiPurchaseYKList")
-- local XUiPurchaseHK = require("XUi/XUiPurchase/XUiPurchaseHK")
local XUiPurchaseHKShop = require("XUi/XUiPurchase/XUiPurchaseHKShop")
local XUiPurchaseHKExchange = require("XUi/XUiPurchase/XUiPurchaseHKExchange")
local XUiPurchaseHKExchangeTop = require("XUi/XUiPurchase/XUiPurchaseHKExchangeTop")
local XUiPurchaseCoatingLB = require("XUi/XUiPurchase/XUiPurchaseCoatingLB")
local XUiPurchaseRecommend = require("XUi/XUiPurchase/XUiPurchaseRecommend")

local lastTab = nil;    -- PC端屏蔽充值

-- BtnLzcj = 累计充值、LB = 礼包、YK = 月卡、HK = 虹卡
---@class XUiPurchase:XLuaUi
function XUiPurchase:OnAwake()
    -- TabsConfig = XPurchaseConfigs.TabsConfig
    PanelNameConfig = XPurchaseConfigs.PanelNameConfig -- 顶头界面配置
    PanelExNameConfig = XPurchaseConfigs.PanelExNameConfig -- 补给包左侧页签配置
    -- TabExConfig = XPurchaseConfigs.TabExConfig
    self:GetLBUiTypesList() -- 创建LBUiTypes礼包类型
    self:GetYKUiTypesList() -- 创建YKUiTypes月卡类型
    UiTypeCfg = XPurchaseConfigs.GetTabControlUiTypeConfig() -- 创建顶部页签数据
    self:InitUi() -- 创建顶部按钮、注册子页面信息
    self:AddRedPointEvent(self.GameObject, self.LBRedPoint, self, { XRedPointConditions.Types.CONDITION_PURCHASE_LB_RED })
    self:AddRedPointEvent(self.GameObject, self.AccumulateRedPoint, self, { XRedPointConditions.Types.CONDITION_ACCUMULATE_PAY_RED })
    self:AddRedPointEvent(self.GameObject, self.UpdateRecommendRed, self, { XRedPointConditions.Types.CONDITION_PURCHASE_RECOMMEND_RED }, nil, false)
    self.TimeId = nil
end

function XUiPurchase:OnEnable()
    if self.CurUiView then
        self.CurUiView:ShowPanel()
    end
    XEventManager.AddEventListener(XEventId.EVENT_ONPCSELECT_MONEYCARD_CHANGED, self.OnPcSelectedIdChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_RECOMMEND_RED, self.UpdateRecommendRed, self)
    if not self.TimeId then
        self.TimeId = XScheduleManager.ScheduleForever(function()
            self:RefreshTimeData()
        end, XScheduleManager.SECOND, 0)
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

    -- 刷新累计充值状态
    local flag = XDataCenter.PurchaseManager.IsAccumulateEnterOpen()
    self.BtnLjcz.gameObject:SetActive(flag)
    if flag then
        local f = XDataCenter.PurchaseManager.AccumulatePayRedPoint()
        self.BtnLjcz:ShowReddot(f)
    end

    XDataCenter.PurchaseManager.GetRecommendManager():RequestServerData(function()
        if not self.TabGroup then
            return
        end
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        local recommendManager = XDataCenter.PurchaseManager.GetRecommendManager()
        local index = self:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Recommend)
        local button = self.TabGroup:GetButtonByIndex(index)
        local isActive = recommendManager:CheckHasRecommend()
        button.gameObject:SetActiveEx(isActive)
        if isActive then
            button:ShowReddot(recommendManager:GetIsShowRedPoint())
        else
            if self.CurGroupTab == index then
                self:OnStartSelTab(XPurchaseConfigs.TabsConfig.LB)
            end
        end
    end)
end

function XUiPurchase:OnPcSelectedIdChanged(newSelectedId)
    self:ShowCurrentRainbowCard(newSelectedId)
end

function XUiPurchase:AddListener()
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClick)
    self:RegisterClickEvent(self.BtnLjcz, self.OnBtnPayAddClick)
    self:RegisterClickEvent(self.BtnPCSwich, self.OnBtnPCSwitchClick)
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
    -- self.PanelLjcz.gameObject:SetActive(true)
    -- self:PlayAnimationWithMask("PanelLjczEnable")
    XLuaUiManager.Open("UiAccumulateRecharge")
end

function XUiPurchase:OnBtnPCSwitchClick()
    XPlayer.ChangePcSelectMoneyCardId()
end

function XUiPurchase:GetLBUiTypesList()
    local t = XPurchaseConfigs.GetLBUiTypesList()
    LBUiTypes = {}
    for _, v in pairs(t) do
        LBUiTypes[v] = v
    end
end

function XUiPurchase:GetYKUiTypesList()
    local t = XPurchaseConfigs.GetYKUiTypes()
    YKUiTypes = {}
    for _, v in pairs(t) do
        YKUiTypes[v] = v
    end
end

function XUiPurchase:InitUi()
    self.TabBtns = {}
    self.LBtnIndex = {}

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAssetPay, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)

    local groupTabBtns = {}
    self.TabsCfg = XPurchaseConfigs.GetGroupConfigType() -- 获取顶部每个标签数据
    -- 创建顶部每个标签按钮
    self.TabGroup = self.PanelTopTabGroup:GetComponent("XUiButtonGroup")
    for _, v in ipairs(self.TabsCfg) do
        local btn = Object.Instantiate(self.BtnPayTab)
        btn.gameObject:SetActive(true)
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

    self.TabGroup:Init(groupTabBtns, function(tab)
        self:TabSkip(tab)
    end)

    local purchaseLBCb = function(skipIndex, leftTabIndex)
        if leftTabIndex == nil then
            leftTabIndex = 1
        end
        self:OnStartSelTab(skipIndex)
        if skipIndex == XPurchaseConfigs.TabsConfig.LB
                and leftTabIndex > 0
                and leftTabIndex <= self.GroupTab.TabBtnList.Count then
            self.GroupTab:SelectIndex(leftTabIndex)
        end
    end

    if XDataCenter.UiPcManager.IsPc() then
        local pcIndex = self:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Pay)
        local btn = self.TabGroup:GetButtonByIndex(pcIndex)
        if btn then
            btn:SetButtonState(CS.UiButtonState.Disable)
        end
    end

    self.UiPanel = {}
    self.UiPanel[PanelNameConfig.PanelRecharge] = XUiPurchasePay.New(self.PanelRecharge, self, XPurchaseConfigs.TabExConfig.Sample)
    self.UiPanel[PanelNameConfig.PanelLb] = XUiPurchaseLB.New(self.PanelLb, self, purchaseLBCb)
    self.UiPanel[PanelNameConfig.PanelYk] = XUiPurchaseYKList.New(self.PanelYk, self, purchaseLBCb)
    self.UiPanel[PanelNameConfig.PanelDh] = XUiPurchaseHKExchangeTop.New(self.PanelDh, self, purchaseLBCb)
    self.UiPanel[PanelNameConfig.PanelHksd] = XUiPurchaseHKShop.New(self.PanelHksd, self)
    self.UiPanel[PanelNameConfig.PanelTj] = XUiPurchaseRecommend.New(self.PanelTj, self, purchaseLBCb)

    self.UiPanel[PanelExNameConfig.PanelRecharge] = XUiPurchasePay.New(self.PanelRechargeEx, self, XPurchaseConfigs.TabExConfig.EXTable)
    self.UiPanel[PanelExNameConfig.PanelLb] = XUiPurchaseLB.New(self.PanelLbEx, self, purchaseLBCb)
    self.UiPanel[PanelExNameConfig.PanelDh] = XUiPurchaseHKExchange.New(self.PanelDhEx, self, purchaseLBCb)
    self.UiPanel[PanelExNameConfig.PanelYk] = XUiPurchaseYK.New(self.PanelYkEx, self, purchaseLBCb)
    self.UiPanel[PanelExNameConfig.PanelHksd] = XUiPurchaseHKShop.New(self.PanelHksdEx, self)
    self.UiPanel[PanelExNameConfig.PanelCoatingLb] = XUiPurchaseCoatingLB.New(self.PanelCoatingLbEx, self, purchaseLBCb)

    if self.PanelLjcz then
        self.PanelLjcz.gameObject:SetActiveEx(false)
    end
    if XDataCenter.UiPcManager.IsPc() then
        local id = XPlayer.GetPcSelectMoneyCardId()
        self:ShowCurrentRainbowCard(id)
        self.BtnPCSwich.gameObject:SetActiveEx(true)
    end
    self:AddListener()
end

function XUiPurchase:ShowCurrentRainbowCard(selectedId)
    if selectedId == 8 then
        self.BtnPCSwich:SetName(CS.XTextManager.GetText("PCSwitchRainbowCard", "IOS"))
    elseif selectedId == 10 then
        self.BtnPCSwich:SetName(CS.XTextManager.GetText("PCSwitchRainbowCard", "安卓"))
    end
end

function XUiPurchase:SetData()
    local cfg = self.TabsCfg[self.CurGroupTab]
    if not cfg then
        return
    end

    local names = XPurchaseConfigs.PanelNameConfig
    local childs = cfg.Childs or {}
    self:CheckChildCount(childs, names)
end

function XUiPurchase:CheckChildCount(childs, names)
    -- 防止Pc刚进入界面立刻快捷键退出后网络请求还未回复执行回调报错
    if XTool.UObjIsNil(self.PanelTabGroup) then
        return
    end
    if #childs > 1 then
        -- names = XPurchaseConfigs.PanelExNameConfig
        self.Panels.gameObject:SetActive(false)
        self.PanelsEx.gameObject:SetActive(true)
        self.ImgBgEx.gameObject:SetActive(true)
        self.PanelTabGroup.gameObject:SetActive(true)
        self:InitGroupTab(self.CurUiTypes)
        if self.IsStartAnimation then
            self.IsStartAnimation = false
            self:PlayAnimationWithMask("AnimEnableSmall")
        else
            self:PlayAnimationWithMask("QieHuanSmall")
        end
    else
        self.PanelTabGroup.gameObject:SetActive(false)
        self.ImgBgEx.gameObject:SetActive(false)
        self.Panels.gameObject:SetActive(true)
        self.PanelsEx.gameObject:SetActive(false)
        for k, v in pairs(names) do
            if self.UiPanel[k] then
                if k ~= self.CurUiNames[k] then
                    self.UiPanel[k]:HidePanel()
                else
                    self.CurUiView = self.UiPanel[v]
                    self.CurUiView:OnRefresh(self.CurUiTypes[1])
                end
            end
        end
        if self.IsStartAnimation then
            self.IsStartAnimation = false
            self:PlayAnimationWithMask("AnimEnableBig")
        else
            self:PlayAnimationWithMask("QieHuanBig")
        end
    end
end

function XUiPurchase:TabSkip(tab)

    if XDataCenter.UiPcManager.IsPc() then
        if tab == self:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Pay) then
            XUiManager.TipText("PcRechargeCloseTip")
            if self.CurGroupTab then
                self.TabGroup:SelectIndex(self.CurGroupTab);
            else
                XLog.Debug("从设置界面外部跳入, 直接关闭自身")
                self:Close()
            end
            return
        end
    end

    if self.CurGroupTab == tab then
        return
    end

    local cfg = self.TabsCfg[tab]
    if not cfg then
        return
    end

    local childs = cfg.Childs or {}
    if Next(childs) == nil then
        return
    end

    if self.TxtTagBgText then
        self.TxtTagBgText.text = XUiHelper.GetText("PurchaseBgText" .. cfg.GroupId)
    end

    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRecharge
    dict["role_level"] = XPlayer.GetLevel()
    dict["ui_second_button"] = XGlobalVar.BtnBuriedSpotTypeLevelTwo["BtnUiPurchaseBtnTabSkip" .. tab]
    CS.XRecord.Record(dict, "200004", "UiOpen")

    self.CurGroupTab = tab
    self.SingleTab = nil

    local names = XPurchaseConfigs.PanelNameConfig
    local sendUiTypes = {}
    self.CurUiTypes = {}
    self.CurUiNames = {}

    -- 充值的读表不需后端数据
    -- 获取充值的UiType, 充值的UiType是不配置在礼包里，默认是不知道哪里写死的1
    local payUiTypes = XPurchaseConfigs.GetPayUiTypes()
    for _, v in pairs(childs) do
        -- 过滤掉充值的UiType
        if not payUiTypes[v.UiType] then
            table.insert(sendUiTypes, v.UiType)
        end

        table.insert(self.CurUiTypes, v.UiType)
        local tmpCfg = XPurchaseConfigs.GetUiTypeConfigByType(v.UiType)
        if tmpCfg and tmpCfg.UiPrefabStyle then
            self.CurUiNames[tmpCfg.UiPrefabStyle] = tmpCfg.UiPrefabStyle
        end
    end

    if self.CurUiView then
        self.CurUiView:HidePanel()
    end

    sendUiTypes = appendArray(sendUiTypes, cfg.ReqUiTypes)
    sendUiTypes = table.unique(sendUiTypes, true)

    if Next(sendUiTypes) ~= nil then
        if XDataCenter.PurchaseManager.IsHaveDataByUiTypes(sendUiTypes) then
            self:SetData()
        else
            XDataCenter.PurchaseManager.GetPurchaseListRequest(sendUiTypes, function()
                self:SetData()
            end)
        end
    else
        self:CheckChildCount(childs, names)
    end
end

function XUiPurchase:AccumulateRedPoint(result)
    if self.BtnLjcz then
        self.BtnLjcz:ShowReddot(result >= 0)
    end

    local index = self:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Pay)
    local button = self.TabGroup:GetButtonByIndex(index)
    button:ShowReddot(result >= 0)
end

function XUiPurchase:LBRedPoint(result)
    if self.LBBtn then
        self.LBBtn:ShowReddot(result >= 0)
    end

    local LbRedUiTypes = XDataCenter.PurchaseManager.LBRedPointUiTypes()
    if self.Btns and Next(self.LBtnIndex) and Next(LbRedUiTypes) then
        for index, uiType in pairs(self.LBtnIndex) do
            if uiType and self.Btns[index] then
                self.Btns[index]:ShowReddot(LbRedUiTypes[uiType] ~= nil)
            end
        end
    else
        if self.Btns and Next(self.Btns) then
            for _, btn in pairs(self.Btns) do
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
    local index = self:GetTabIndexByTabType(t)

    self.IsStartAnimation = true
    self.TabGroup:SelectIndex(index)
end

function XUiPurchase:GetTabIndexByTabType(tabType)
    local uiTypes = XPurchaseConfigs.GetUiTypesByTab(tabType)
    local cfg = self.TabsCfg
    local index = 1
    for k, v in pairs(cfg) do
        local childs = v.Childs
        for _, c in pairs(childs) do
            for _, a in pairs(uiTypes) do
                if a.UiType == c.UiType then
                    index = k
                    break
                end
            end
        end
    end
    return index
end

function XUiPurchase.UiTypeTabSort(a, b)
    if UiTypeCfg[a] and UiTypeCfg[b] then
        return UiTypeCfg[a].GroupOrder < UiTypeCfg[b].GroupOrder
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
        self.TabBtns[k]:SetName(UiTypeCfg[v].Name)
        i = i + 1
    end

    local len = #self.Btns
    if i < len then
        for index = i + 1, len do
            self.Btns[index].gameObject:SetActive(false)
        end
    end

    self.GroupTab:Init(self.TabBtns, function(tab)
        self:GroupTabSkip(tab)
    end)
    self.GroupTab:SelectIndex(self.ChildTabIndex)
end

function XUiPurchase:GroupTabSkip(tab)
    if self.SingleTab == tab then
        return
    end

    local cfgs = self.TabsCfg[self.CurGroupTab]
    if not cfgs or not cfgs.Childs[tab] then
        return
    end

    local cfg = XPurchaseConfigs.GetUiTypeConfigByType(cfgs.Childs[tab].UiType)
    if not cfg or not cfg.UiPrefabStyle then
        return
    end

    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRecharge
    dict["role_level"] = XPlayer.GetLevel()
    dict["ui_second_button"] = XGlobalVar.BtnBuriedSpotTypeLevelTwo["BtnUiPurchaseGroupTabSkip" .. tab]
    CS.XRecord.Record(dict, "200004", "UiOpen")

    self.SingleTab = tab

    if self.CurUiView then
        self.CurUiView:HidePanel()
    end

    local n = PanelExNameConfig[cfg.UiPrefabStyle]
    self.CurUiView = self.UiPanel[n]
    -- 切换到非礼包页签，默认多隐藏礼包页签一次，防止数据未到达时快速切换到皮肤礼包导致隐藏错误
    if n ~= PanelExNameConfig.PanelLb then
        self.UiPanel[PanelExNameConfig.PanelLb]:HidePanel()
    end
    self.CurUiView:OnRefresh(cfg.UiType)
    self:PlayAnimationWithMask("QieHuanSmall")
end

function XUiPurchase:OnDisable()
    if self.CurUiView then
        self.CurUiView:HidePanel()
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_ONPCSELECT_MONEYCARD_CHANGED, self.OnPcSelectedIdChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_RECOMMEND_RED, self.UpdateRecommendRed, self)

    if self.TimeId then
        XScheduleManager.UnSchedule(self.TimeId)
        self.TimeId = nil
    end
end

function XUiPurchase:OnDestroy()
    self.Btns = nil
    if self.IsClearData then
        XDataCenter.PurchaseManager.ClearData()
    end

    for _, panel in pairs(self.UiPanel) do
        if panel.BuyUiTips then
            panel.BuyUiTips:OnDestroy()
        end
    end
end

function XUiPurchase:IsLBUiType(cfg)
    if Next(cfg) then
        for _, v in pairs(cfg) do
            if LBUiTypes[v.UiType] then
                return true
            end
        end
    end
    return false
end

function XUiPurchase:IsYKUiType(cfg)
    if Next(cfg) then
        for _, v in pairs(cfg) do
            if YKUiTypes[v.UiType] then
                return true
            end
        end
    end
    return false
end

function XUiPurchase:UpdateRecommendRed()
    local index = self:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Recommend)
    local button = self.TabGroup:GetButtonByIndex(index)
    button:ShowReddot(XDataCenter.PurchaseManager.GetRecommendManager():GetIsShowRedPoint())
end

function XUiPurchase:RefreshTimeData()
    local tjPanel = self.UiPanel[PanelNameConfig.PanelTj]
    if tjPanel.RefreshTimeData then
        tjPanel:RefreshTimeData()
    end
end