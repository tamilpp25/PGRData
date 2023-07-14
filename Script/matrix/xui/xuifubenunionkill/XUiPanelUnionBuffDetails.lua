local XUiPanelUnionBuffDetails = XClass(nil, "XUiPanelUnionBuffDetails")
local XUiGridUnionBuffItem = require("XUi/XUiFubenUnionKill/XUiGridUnionBuffItem")

function XUiPanelUnionBuffDetails:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnTanchuangClose.CallBack = function() self:OnCloseClick() end
    self.DynamicTableBuff = XDynamicTableNormal.New(self.ScrollBuff.gameObject)
    self.DynamicTableBuff:SetProxy(XUiGridUnionBuffItem)
    self.DynamicTableBuff:SetDelegate(self)
end

function XUiPanelUnionBuffDetails:Refresh(buffInfos)
    self.BuffInfos = buffInfos
    self.GameObject:SetActiveEx(true)
    -- 收集增益数据
    self.DynamicTableBuff:Clear()
    self.DynamicTableBuff:SetDataSource(self.BuffInfos)
    self.DynamicTableBuff:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.BuffInfos <= 0)
end

function XUiPanelUnionBuffDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local buffId = self.BuffInfos[index]
        if not buffId then return end
        grid:Refresh(buffId)
    end
end

function XUiPanelUnionBuffDetails:OnCloseClick()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelUnionBuffDetails