local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelWheelChairManualPopupPassportCard: XUiNode
---@field _Control XWheelchairManualControl
---@field _PrefabCfg XTableWheelchairManualPassportPrefab
---@field BtnBuy XUiComponent.XUiButton
local XUiPanelWheelChairManualPopupPassportCard = XClass(XUiNode, 'XUiPanelWheelChairManualPopupPassportCard')

function XUiPanelWheelChairManualPopupPassportCard:OnStart()
    self._PrefabCfg = self._Control:GetCurActivityPassportCardPrefabCfg()
    self:InitCommonManualShow()
    self:InitSeniorManualShow()
end

function XUiPanelWheelChairManualPopupPassportCard:OnEnable()
    self:RefreshCommonManualShow()
    self:RefreshSeniorManualShow()
end

function XUiPanelWheelChairManualPopupPassportCard:OnDestroy()
    self._PrefabCfg = nil
end

function XUiPanelWheelChairManualPopupPassportCard:InitCommonManualShow()
    self._CommonManualId = self._Control:GetCurActivityCommanManualId()
    
    --self.CommonTxtTitle.text = self._Control:GetManualName(self._CommonManualId)
    
    local rewardId = self._Control:GetManualPreviewRewardId(self._CommonManualId)
    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
    
    self._CommonRewardGrids = {}
    
    XUiHelper.RefreshCustomizedList(self.CommonGrid256New.transform.parent, self.CommonGrid256New, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self.Parent, go)
        grid:Refresh(rewardGoodsList[index])
        table.insert(self._CommonRewardGrids, grid)
    end)
    
    --self.CommonBtnDetail:SetNameByGroup(0, self._PrefabCfg.CommonDesc)
    self.CommonBtnDetail.CallBack = handler(self, self.OnCommonBtnClick)
    
    self.CommonTxtTips.text = self._Control:GetManualDesc(self._CommonManualId)
end

function XUiPanelWheelChairManualPopupPassportCard:InitSeniorManualShow()
    self._SeniorManualId = self._Control:GetCurActivitySeniorManualId()
    
    --self.SeniorTxtTitle.text = self._Control:GetManualName(self._SeniorManualId)

    local rewardId = self._Control:GetManualPreviewRewardId(self._SeniorManualId)
    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
    
    self._SeniorRewardGrids = {}

    XUiHelper.RefreshCustomizedList(self.SeniorGrid256New.transform.parent, self.SeniorGrid256New, rewardGoodsList and #rewardGoodsList or 0, function(index, go)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self.Parent, go)
        grid:Refresh(rewardGoodsList[index])
        table.insert(self._SeniorRewardGrids, grid)
    end)

    --self.SeniorBtnDetail:SetNameByGroup(0, self._PrefabCfg.SeniorDesc)
    self.SeniorBtnDetail.CallBack = handler(self, self.OnSeniorBtnClick)
    
    self.BtnBuy.CallBack = handler(self, self.OnBuyClick)

    self.SeniorTxtTips.text = self._Control:GetManualDesc(self._SeniorManualId)
end

function XUiPanelWheelChairManualPopupPassportCard:RefreshCommonManualShow()
    
end

function XUiPanelWheelChairManualPopupPassportCard:RefreshSeniorManualShow()
    local seniorIsUnLock = self._Control:GetIsSeniorManualUnLock()

    self.BtnBuy:SetButtonState(seniorIsUnLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.PanelConsume.gameObject:SetActiveEx(not seniorIsUnLock)
    
    if not seniorIsUnLock then
        self.BtnBuy:SetNameByGroup(0, self._Control:GetManualConsumeItemCount(self._SeniorManualId))
        
        self.BtnBuy:SetRawImage(XItemConfigs.GetItemIconById(self._Control:GetManualConsumeItemId(self._SeniorManualId)))
    end
end

function XUiPanelWheelChairManualPopupPassportCard:OnCommonBtnClick()
    if XTool.IsNumberValid(self._PrefabCfg.CommonSkipId) and XFunctionManager.IsCanSkip(self._PrefabCfg.CommonSkipId) then
        XFunctionManager.SkipInterface(self._PrefabCfg.CommonSkipId)
    end
end

function XUiPanelWheelChairManualPopupPassportCard:OnSeniorBtnClick()
    if XTool.IsNumberValid(self._PrefabCfg.SeniorSkipId) and XFunctionManager.IsCanSkip(self._PrefabCfg.SeniorSkipId) then
        XFunctionManager.SkipInterface(self._PrefabCfg.SeniorSkipId)
    end
end

function XUiPanelWheelChairManualPopupPassportCard:OnBuyClick()
    if self._Control:GetIsSeniorManualUnLock() then
        return
    end
    
    local costItemId = self._Control:GetManualConsumeItemId(self._SeniorManualId)
    local haveCostItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local costItemCount = self._Control:GetManualConsumeItemCount(self._SeniorManualId)
    local manualName = self._Control:GetManualName(self._SeniorManualId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local title = XUiHelper.GetText("BuyConfirmTipsTitle")
    local desc = XUiHelper.GetText("PassportBuyPassportTipsDesc", costItemCount, costItemName, manualName)
    local sureCallback = function()
        if haveCostItemCount < costItemCount then
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            if costItemId == XDataCenter.ItemManager.ItemId.HongKa then
                XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
            elseif costItemId == XDataCenter.ItemManager.ItemId.FreeGem then
                XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
            end
            return
        end
        XMVCA.XWheelchairManual:RequestWheelchairManualPurchase(self._SeniorManualId, function() 
            self.Parent:Close()
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_PASSPORTLIST)
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        end)
    end

    XUiManager.DialogTip(title, desc, nil, nil, sureCallback)
end

return XUiPanelWheelChairManualPopupPassportCard