local XUiStrongholdPowerExpectTipsGrid = require("XUi/XUiStronghold/XUiStrongholdPowerExpectTips/XUiStrongholdPowerExpectTipsGrid")

local XUiStrongholdPowerExpectTips = XLuaUiManager.Register(XLuaUi, "UiStrongholdPowerExpectTips")

function XUiStrongholdPowerExpectTips:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridDay.gameObject:SetActiveEx(false)
end

function XUiStrongholdPowerExpectTips:OnEnable()
    self:Refresh()
end

function XUiStrongholdPowerExpectTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiStrongholdPowerExpectTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDay)
    self.DynamicTable:SetProxy(XUiStrongholdPowerExpectTipsGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiStrongholdPowerExpectTips:Refresh()
    self.List = XStrongholdConfigs.GetElectricIdList()
    local curDay = XDataCenter.StrongholdManager.GetCurDay()
    local startIndex
    for i, electricId in ipairs(self.List) do
        if electricId == curDay then
            startIndex = i
            break
        end
    end

    self.DynamicTable:SetDataSource(self.List)
    self.DynamicTable:ReloadDataSync(startIndex)
end

function XUiStrongholdPowerExpectTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self.List[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end