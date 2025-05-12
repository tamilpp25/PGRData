local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelKotodamaSpeech = XClass(XUiNode, 'XUiPanelKotodamaSpeech')

function XUiPanelKotodamaSpeech:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.SpeechList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiKotodamaActivity/UiKotodamaSpeech/XUiGridKotodamaSpeech'), self)
    self.GridSpeech.gameObject:SetActiveEx(false)
end

function XUiPanelKotodamaSpeech:OnEnable()
    local collects = XMVCA.XKotodamaActivity:GetAllUnLockCollectSentenceIds()
    local dataCount = XTool.GetTableCount(collects)
    self.TxtCollect.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('Collectable'), dataCount, self._Control:GetCollectableSentenceCount())
    self.ImgEmpty.gameObject:SetActiveEx(dataCount <= 0)

    if dataCount > 0 then
        self.DynamicTable:SetDataSource(collects)
        self.DynamicTable:ReloadDataASync()
    end
end

function XUiPanelKotodamaSpeech:OnDisable()
    local collects = XMVCA.XKotodamaActivity:GetAllUnLockCollectSentenceIds()
    XMVCA.XKotodamaActivity:ClearAllNewSentenceState(collects)
end

function XUiPanelKotodamaSpeech:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

return XUiPanelKotodamaSpeech