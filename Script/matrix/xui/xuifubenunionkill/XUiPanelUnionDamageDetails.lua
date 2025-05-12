local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelUnionDamageDetails = XClass(nil, "XUiPanelUnionDamageDetails")
local XUiGridUnionDamageItem = require("XUi/XUiFubenUnionKill/XUiGridUnionDamageItem")

function XUiPanelUnionDamageDetails:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = rootUi

    XTool.InitUiObject(self)
    self.BtnTanchuangClose.CallBack = function() self:OnCloseClick() end
    self.DynamicTableDamage = XDynamicTableNormal.New(self.ScrollDamage.gameObject)
    self.DynamicTableDamage:SetProxy(XUiGridUnionDamageItem)
    self.DynamicTableDamage:SetDelegate(self)
end

function XUiPanelUnionDamageDetails:Refresh(damageInfos)
    self.DamageInfos = damageInfos
    self.GameObject:SetActiveEx(true)
    -- 收集增益数据
    if #self.DamageInfos >= 1 then
        self.DamageInfos[1].IsMax = true
    end

    self.DynamicTableDamage:Clear()
    self.DynamicTableDamage:SetDataSource(self.DamageInfos)
    self.DynamicTableDamage:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.DamageInfos <= 0)
end

function XUiPanelUnionDamageDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local damageInfo = self.DamageInfos[index]
        if not damageInfo then return end
        grid:Refresh(damageInfo)
    end
end

function XUiPanelUnionDamageDetails:OnCloseClick()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelUnionDamageDetails