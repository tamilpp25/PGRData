---@class XUiPanelWheelchairManualGiftPack: XUiNode
---@field _Control XWheelchairManualControl
local XUiPanelWheelchairManualGiftPack = XClass(XUiNode, 'XUiPanelWheelchairManualGiftPack')
local XUiPurchaseLB = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualGiftPack/XUiPanelWheelchairLBList')


function XUiPanelWheelchairManualGiftPack:OnStart()
    self._GiftListPanel = XUiPurchaseLB.New(self.ListGiftPack, self, handler(self, self.OnPurchaseCallBack))
    self._GiftListPanel:ShowPanel()

    if self.PanelLbItem then
        self.PanelLbItem.gameObject:SetActiveEx(false)
    end
    
    local showPackageIds = self._Control:GetCurActivityShowPurchaseIds()

    if not XTool.IsTableEmpty(showPackageIds) then
        self._GiftListPanel:SetFilterFunc(handler(self, self.OnFilterFun))
        self._ShowPackageIdsMap = {}
        for i, v in pairs(showPackageIds) do
            self._ShowPackageIdsMap[v] = true
        end
    end

    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.GiftNew)
end

function XUiPanelWheelchairManualGiftPack:OnEnable()
    -- 每次都请求一次数据，以便显示新开放的礼包
    local uiType = self._Control:GetCurActivityPurchaseUiType()

    if XTool.IsNumberValid(uiType) then
        XDataCenter.PurchaseManager.GetPurchaseListRequest({ uiType }, function()
            if self and not XTool.UObjIsNil(self.GameObject) and self._Control then
                self._GiftListPanel:OnRefresh(self._Control:GetCurActivityPurchaseUiType())
            end
        end)
    else
        XLog.Error('礼包类型无效:'..tostring(uiType)..' 当前活动Id:'..tostring(self._Control:GetCurActivityId()))
    end
end

function XUiPanelWheelchairManualGiftPack:OnDisable()
    self._GiftListPanel:OnHide()
end

-- 筛选
function XUiPanelWheelchairManualGiftPack:OnFilterFun(data)
    local result = {}
    for i, v in pairs(data) do
        if self._ShowPackageIdsMap[v.Id] then
            table.insert(result, v)
        end
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
    
    return result
end

function XUiPanelWheelchairManualGiftPack:OnPurchaseCallBack(skipIndex, leftTabIndex, payCount)
    if leftTabIndex == nil then
        leftTabIndex = 1
    end
    if skipIndex == XPurchaseConfigs.TabsConfig.Pay and not XDataCenter.UiPcManager.IsPc() then
        if payCount then
            XLuaUiManager.Open("UiPurchaseQuickBuy", payCount)
        else
            XLuaUiManager.Open("UiPurchase", skipIndex)
        end
    else
        XLuaUiManager.Open("UiPurchase", skipIndex)
    end
end

function XUiPanelWheelchairManualGiftPack:SetUiSprite(...)
    self.Parent:SetUiSprite(...)
end

return XUiPanelWheelchairManualGiftPack