local XUiGridEquipMultiConsume = require("XUi/XUiEquipStrengthen/XUiGridEquipMultiConsume")

--一键培养消耗预览弹窗
local XUiEquipStrengthenConsumption = XLuaUiManager.Register(XLuaUi, "UiEquipStrengthenConsumption")

function XUiEquipStrengthenConsumption:OnAwake()
    self:AutoAddListener()

    self.GridConsume.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridEquipMultiConsume)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipStrengthenConsumption:OnStart(consumes)
    self.Consumes = consumes

    self.DynamicTable:SetDataSource(self.Consumes)
    self.DynamicTable:ReloadDataSync()
end

function XUiEquipStrengthenConsumption:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnCloseMask.CallBack = handler(self, self.Close)
    self.BtnDetermine.CallBack = handler(self, self.Close)
end

function XUiEquipStrengthenConsumption:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Consumes[index])
    end
end
