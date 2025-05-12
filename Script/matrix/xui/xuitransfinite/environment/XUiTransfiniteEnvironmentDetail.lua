local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTransfiniteEnvironmentDetailGrid = require("XUi/XUiTransfinite/Environment/XUiTransfiniteEnvironmentDetailGrid")

---@class XUiTransfiniteEnvironmentDetail:XLuaUi
local XUiTransfiniteEnvironmentDetail = XLuaUiManager.Register(XLuaUi, "UiTransfiniteEnvironmentDetail")

function XUiTransfiniteEnvironmentDetail:Ctor()
    self._EnvironmentData = false
    self._SelectedIndex = 1
end

function XUiTransfiniteEnvironmentDetail:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self.PanelAmbient.gameObject:SetActiveEx(false)
    self.PanelAmbientNew.gameObject:SetActiveEx(true)
    self.PanelChallenge.gameObject:SetActiveEx(false)
    self.PanelSupport.gameObject:SetActiveEx(false)
    XTool.InitUiObjectByInstance(self.PanelAmbientNew.transform:GetComponent("UiObject"), self)

    self.DynamicTable = XDynamicTableNormal.New(self.BuffList)
    self.DynamicTable:SetProxy(XUiTransfiniteEnvironmentDetailGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridBuff.gameObject:SetActiveEx(false)
end

---@param environment XTransfiniteEnvironment
function XUiTransfiniteEnvironmentDetail:OnStart(environment)
    self._EnvironmentData = environment
end

function XUiTransfiniteEnvironmentDetail:OnEnable()
    local dataProvider = self._EnvironmentData:GetData()
    if not dataProvider then
        return
    end
    self.DynamicTable:SetDataSource(dataProvider)
    self.DynamicTable:ReloadDataASync(1)
    self:Update()
end

function XUiTransfiniteEnvironmentDetail:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_ON_ENVIRONMENT_CLOSE)
end

---@param grid XUiTransfiniteEnvironmentDetailGrid
function XUiTransfiniteEnvironmentDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        grid:UpdateSelected(self._SelectedIndex)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._SelectedIndex = index
        self:Update()
    end
end

function XUiTransfiniteEnvironmentDetail:UpdateSelected()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelected(self._SelectedIndex)
    end
end

function XUiTransfiniteEnvironmentDetail:Update()
    ---@type XTransfiniteEnvironmentData
    local data = self.DynamicTable:GetData(self._SelectedIndex)
    if not data then
        return
    end
    self.TxtBuffDetail.text = data.Desc
    self.RImgBuffDetail:SetRawImage(data.Icon)
    self:UpdateSelected()
end
