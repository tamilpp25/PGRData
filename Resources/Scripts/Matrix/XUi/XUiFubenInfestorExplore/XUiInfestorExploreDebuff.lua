local XUiGridInfestorExploreBuff = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreBuff")

local XUiInfestorExploreDebuff = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreDebuff")

function XUiInfestorExploreDebuff:OnAwake()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.GridBuff.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetProxy(XUiGridInfestorExploreBuff)
    self.DynamicTable:SetDelegate(self)
end

function XUiInfestorExploreDebuff:OnStart()
    local buffIds = XDataCenter.FubenInfestorExploreManager.GetBuffIds()
    self.BuffIds = buffIds

    local num = #buffIds
    self.TxtOwnBuff.text = num
    self.ImgEmpty.gameObject:SetActiveEx(num <= 0)

    self.DynamicTable:SetDataSource(buffIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiInfestorExploreDebuff:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local buffId = self.BuffIds[index]
        grid:Refresh(buffId)
    end
end
