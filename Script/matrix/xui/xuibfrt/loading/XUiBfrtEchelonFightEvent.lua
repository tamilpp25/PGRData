local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBfrtEchelonFightEventGrid = require("XUi/XUiBfrt/Loading/XUiBfrtEchelonFightEventGrid")

---@class XUiBfrtEchelonFightEvent:XLuaUi
local XUiBfrtEchelonFightEvent = XLuaUiManager.Register(XLuaUi, "UiBfrtEchelonFightEvent")

function XUiBfrtEchelonFightEvent:OnStart(echelonId, cb)
    self._EchelonId = echelonId
    self._CallBack = cb
    self:InitDynamicTable()
    self:RegisterBtnEvent()
    self.GridBuffBase.gameObject:SetActiveEx(false)
end

function XUiBfrtEchelonFightEvent:OnEnable()
    local echelonFightEventData = XDataCenter.BfrtManager.GetEchelonInfoShowFightEventIds(self._EchelonId)
    if echelonFightEventData then
        self._DynamicTable:SetDataSource(echelonFightEventData)
        self._DynamicTable:ReloadDataSync()
    end
end

function XUiBfrtEchelonFightEvent:RegisterBtnEvent()
    self:RegisterClickEvent(self.BtnClose, function()
        self:OnBtnCloseClick()
    end)
end

function XUiBfrtEchelonFightEvent:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelBaseBuffs)
    self._DynamicTable:SetProxy(XUiBfrtEchelonFightEventGrid, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiBfrtEchelonFightEvent:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DynamicTable:GetData(index))
    end
end

function XUiBfrtEchelonFightEvent:OnBtnCloseClick()
    self:Close()
    if self._CallBack then
        self._CallBack()
    end
end