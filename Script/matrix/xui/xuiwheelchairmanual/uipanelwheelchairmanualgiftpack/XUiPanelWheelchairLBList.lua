local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPurchaseLB = require('XUi/XUiPurchase/XUiPurchaseLB')

local XUiPanelWheelchairLBList = XClass(XUiPurchaseLB, 'XUiPanelWheelchairLBList')
local XUiGridWheelchairLBItem = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualGiftPack/XUiGridWheelchairLBItem')

local GridShowAnimationInterval = XMVCA.XWheelchairManual:GetWheelchairManualConfigNum('GiftPackGridFadeInAnimInterval')
local Next = _G.next

---@overload
function XUiPanelWheelchairLBList:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiGridWheelchairLBItem)
    self.DynamicTable:SetDelegate(self)
end

---因为基类不是XUiNode，需要父类手动调用
function XUiPanelWheelchairLBList:OnHide()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end

---@overload
function XUiPanelWheelchairLBList:OnRefresh(uiType)
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType)
    if not data then
        return
    end

    self.CurUiType = uiType
    self.GameObject:SetActive(true)
    if Next(data) ~= nil then
        if self._FilterFunc then
            data = self._FilterFunc(data)
        end

        self:OnSortFun(data)
    end
    if Next(data) == nil then
        self.ListData = {}
    end
    self.TimeFuns = {}
    self.TimeSaveFuns = {}
    self.IsReloadTable = true
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataSync(1)
    self:StartLBTimer()
end

---@overload
function XUiPanelWheelchairLBList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot,self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
        if self.IsReloadTable then
            grid:SetRootCanvasGroupAlpha(0)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        if not data then
            return
        end

        self:OpenPurchaseBuyTips(data)
        grid:OnTouched()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1011)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()

        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item:PlayAnimation('PanelLbItemEnable')
            end
            self.GridIndex = self.GridIndex + 1
            self.CurAnimationTimerId = nil
        end, GridShowAnimationInterval * XScheduleManager.SECOND, #grids, 0)
        self.IsReloadTable = false
    end
end

return XUiPanelWheelchairLBList