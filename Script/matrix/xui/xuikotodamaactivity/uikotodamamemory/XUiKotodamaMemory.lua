local XUiKotodamaMemory=XLuaUiManager.Register(XLuaUi,'UiKotodamaMemory')

function XUiKotodamaMemory:OnAwake()
    self.BtnClose.CallBack=function() self:Close() end
    self.BtnTanchuangClose.CallBack=function() self:Close() end
    
    self.DynamicTable=XDynamicTableNormal.New(self.MemoryList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiKotodamaActivity/UiKotodamaMemory/XUiGridKotodamaMemorySentence'),self)
    self.GridMemory.gameObject:SetActiveEx(false)
end

function XUiKotodamaMemory:OnStart()
    self:Refresh()
end

function XUiKotodamaMemory:Refresh()
    local data=self._Control:GetAllLatestPassSentenceIds()
    local dataCount=XTool.GetTableCount(data)
    self.ImgEmpty.gameObject:SetActiveEx(dataCount<=0)
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync()
end

function XUiKotodamaMemory:OnDynamicTableEvent(event,index,grid)
    if event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

return XUiKotodamaMemory