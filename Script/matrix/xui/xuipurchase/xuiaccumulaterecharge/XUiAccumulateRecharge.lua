local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiAccumulateRechargeGrid = require("XUi/XUiPurchase/XUiAccumulateRecharge/XUiAccumulateRechargeGrid")

---@class XUiAccumulateRecharge : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field PanelAssetPay UnityEngine.RectTransform
---@field BtnPCSwich XUiComponent.XUiButton
---@field TxtTime UnityEngine.UI.Text
---@field TxtPayNumber UnityEngine.UI.Text
---@field BtnLook XUiComponent.XUiButton
---@field ImgLook UnityEngine.UI.Image
---@field ImgUnlook UnityEngine.UI.Image
---@field PanelRewardGroup UnityEngine.RectTransform
---@field PanelAccumulate UnityEngine.RectTransform
local XUiAccumulateRecharge = XLuaUiManager.Register(XLuaUi, "UiAccumulateRecharge")

local TableInsert = table.insert
local Pairs = pairs

function XUiAccumulateRecharge:Ctor()
    self._CurrentLookState = nil
    ---@type XDynamicTableNormal
    self._DynamicTable = nil
    self._PayRewardIds = nil
    self._PayRewardExtraIds = nil
end

--region 生命周期
function XUiAccumulateRecharge:OnAwake()
    XUiPanelAsset.New(self, self.PanelAssetPay, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.HongKa)

    self._CurrentLookState = XSaveTool.GetData(XPurchaseConfigs.LjczLookStateKey) or
        CS.XGame.ClientConfig:GetInt(XPurchaseConfigs.PurchaseLJCZDefaultLookStateKey)
    self._DynamicTable = XDynamicTableNormal.New(self.PanelRewardGroup)
    self._DynamicTable:SetProxy(XUiAccumulateRechargeGrid, self)
    self._DynamicTable:SetDelegate(self)
    self:_RegisterButtonClicks()
end

function XUiAccumulateRecharge:OnStart()
    self:_Init()
end

function XUiAccumulateRecharge:OnEnable()
    self:_Refresh()
    self:_RegisterListeners()
end

function XUiAccumulateRecharge:OnDisable()
    self:_RemoveListeners()
end

--endregion

--region 按钮事件

function XUiAccumulateRecharge:OnBtnLookClick()
    if self._CurrentLookState == XPurchaseConfigs.LjczLookState.Show then
        self._CurrentLookState = XPurchaseConfigs.LjczLookState.Hide
    else
        self._CurrentLookState = XPurchaseConfigs.LjczLookState.Show
    end
    self:_RefreshLookState()
end

function XUiAccumulateRecharge:OnAccumulatedGeted()
    self:_RefreshDynamicTable()
end

function XUiAccumulateRecharge:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data)
    end
end

--endregion

--region 私有方法
function XUiAccumulateRecharge:_RegisterButtonClicks()
    --在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:RegisterClickEvent(self.BtnLook, self.OnBtnLookClick, true)
end

function XUiAccumulateRecharge:_Init()
    self.BtnPCSwich.gameObject:SetActiveEx(false)
    if self.TxtTagBgText then
        self.TxtTagBgText.text = XUiHelper.GetText("PurchaseBgText1")
    end
    if self.BtnHelp then    
        self.BtnHelp.gameObject:SetActiveEx(false)
    end
end

function XUiAccumulateRecharge:_Refresh()
    local data = XDataCenter.PurchaseManager.GetAccumulatePayConfig()
    if not data then
        return
    end

    local beginTimeStr, endTimeStr = XDataCenter.PurchaseManager.GetAccumulatePayTimeStr()
    local isTimeExit = beginTimeStr and endTimeStr

    self._PayRewardIds = data.PayRewardId or {}
    self:_RefreshDynamicTable()
    self:_RefreshLookState()

    self.TxtTime.text = isTimeExit and beginTimeStr .. "--" .. endTimeStr or ""
    self.PanelAccumulate.gameObject:SetActiveEx(XDataCenter.SetManager.RechargeType ~= XSetConfigs.RechargeEnum.Close)
end

function XUiAccumulateRecharge:_RefreshDynamicTable()
    local purchaseList = {}
    local purchaseCanGet = {}
    local purchaseGeted = {}
    local purchaseCanotGet = {}

    for i, id in Pairs(self._PayRewardIds) do
        local state = XDataCenter.PurchaseManager.PurchaseAddRewardState(id)
        local extraState = XDataCenter.PurchaseManager.PurchaseAddExtraRewardState(id)
        local rewardData = { Id = id, State = state, ExtraState = extraState }

        if state == XPurchaseConfigs.PurchaseRewardAddState.CanGet or
            extraState == XPurchaseConfigs.PurchaseRewardAddState.CanGet then
            TableInsert(purchaseCanGet, rewardData)
        elseif state == XPurchaseConfigs.PurchaseRewardAddState.Geted
            and extraState == XPurchaseConfigs.PurchaseRewardAddState.Geted then
            TableInsert(purchaseGeted, rewardData)
        elseif state == XPurchaseConfigs.PurchaseRewardAddState.CanotGet
            and extraState == XPurchaseConfigs.PurchaseRewardAddState.CanotGet then
            TableInsert(purchaseCanotGet, rewardData)
        end
    end

    for _, data in Pairs(purchaseCanGet) do
        TableInsert(purchaseList, data)
    end

    for _, data in Pairs(purchaseCanotGet) do
        TableInsert(purchaseList, data)
    end

    for _, data in Pairs(purchaseGeted) do
        TableInsert(purchaseList, data)
    end

    self._DynamicTable:SetDataSource(purchaseList)
    self._DynamicTable:ReloadDataASync(1)
end

function XUiAccumulateRecharge:_RefreshLookState()
    local currentState = self._CurrentLookState
    local isShow = (currentState == XPurchaseConfigs.LjczLookState.Show)
    local count = XDataCenter.PurchaseManager.GetAccumulatedPayCount()

    self.ImgLook.gameObject:SetActive(isShow)
    self.ImgUnlook.gameObject:SetActive(not isShow)
    self.TxtPayNumber.text = isShow and count or XUiHelper.GetText("PurchaseAddHide")

    XSaveTool.SaveData(XPurchaseConfigs.LjczLookStateKey, currentState)
end

function XUiAccumulateRecharge:_RegisterListeners()
    XEventManager.AddEventListener(XEventId.EVENT_ACCUMULATED_REWARD, self.OnAccumulatedGeted, self)
end

function XUiAccumulateRecharge:_RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_ACCUMULATED_REWARD, self.OnAccumulatedGeted, self)
end

--endregion

return XUiAccumulateRecharge
