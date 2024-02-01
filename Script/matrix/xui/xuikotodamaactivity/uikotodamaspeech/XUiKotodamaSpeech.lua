local XUiKotodamaSpeech=XLuaUiManager.Register(XLuaUi,'UiKotodamaSpeech')

function XUiKotodamaSpeech:OnAwake()
    self.BtnClose.CallBack=function() self:Close() end
    self.BtnTanchuangClose.CallBack=function() self:Close() end

    self.DynamicTable=XDynamicTableNormal.New(self.SpeechList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiKotodamaActivity/UiKotodamaSpeech/XUiGridKotodamaSpeech'),self)
    self.GridSpeech.gameObject:SetActiveEx(false)
end

function XUiKotodamaSpeech:OnStart(collects,cbClose)
    self.TxtCollect.text=XUiHelper.GetText('KotodamaCollectable',#collects,self._Control:GetCollectableSentenceCount())
    self.CbClose = cbClose
    local dataCount=XTool.GetTableCount(collects)
    self.ImgEmpty.gameObject:SetActiveEx(dataCount<=0)
    self.DynamicTable:SetDataSource(collects)
    self.DynamicTable:ReloadDataASync()
end

function XUiKotodamaSpeech:OnDestroy()
    local collects = XMVCA.XKotodamaActivity:GetAllUnLockCollectSentenceIds()
    XMVCA.XKotodamaActivity:ClearAllNewSentenceState(collects)
    if self.CbClose then
        self.CbClose()
        self.CbClose = nil
    end
end

function XUiKotodamaSpeech:OnDynamicTableEvent(event,index,grid)
    if event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

return XUiKotodamaSpeech