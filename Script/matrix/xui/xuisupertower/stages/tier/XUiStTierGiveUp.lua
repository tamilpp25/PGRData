--===========================
--超级爬塔 爬塔关卡放弃 页面
--===========================
local XUiStTierGiveUp = XLuaUiManager.Register(XLuaUi, "UiSuperTowerFubenCloseTip")

function XUiStTierGiveUp:OnAwake()
    XTool.InitUiObject(self)
end

function XUiStTierGiveUp:OnStart(theme, onGiveUpCallBack)
    self.Theme = theme
    self.OnGiveUpCb = onGiveUpCallBack
    self:InitTier()
    self:InitDynamicTable()
    self:InitBtns()
    self:ShowList()
end

function XUiStTierGiveUp:InitTier()
    self.TxtCurrentTier.text = self.Theme:GetCurrentTier()
    self.TxtMaxTier.text = "/" .. self.Theme:GetMaxTier()
end

function XUiStTierGiveUp:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
    self.BtnNo.CallBack = function() self:OnClickClose() end
    self.BtnYes.CallBack = function() self:OnClickGiveUp() end
end

function XUiStTierGiveUp:OnClickClose()
    self:Close()
end

function XUiStTierGiveUp:OnClickGiveUp()
    self.Theme:RequestReset(function() self:OnGiveUpSuccess() end)
end

function XUiStTierGiveUp:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable.gameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

--=============
--动态列表事件
--=============
function XUiStTierGiveUp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function(pluginGrid) self:OnGridClick(pluginGrid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.PluginList and self.PluginList[index] then
            grid:RefreshData(self.PluginList[index])
        end
    end
end

function XUiStTierGiveUp:ShowList()
    self.PluginData = self.Theme:GetTierPluginInfos()
    local pluginSlotScript = require("XEntity/XSuperTower/XSuperTowerPluginSlotManager")
    self.PluginSlot = pluginSlotScript.New()
    for _, data in pairs(self.PluginData) do
        self.PluginSlot:AddPluginById(data.Id, data.Count)
    end
    self.PluginList = self.PluginSlot:GetPluginsSplit()
    self.DynamicTable:SetDataSource(self.PluginList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiStTierGiveUp:OnGridClick(grid)
    XLuaUiManager.Open("UiSuperTowerPluginDetails", grid:GetPlugin(), 0)
end

function XUiStTierGiveUp:OnGiveUpSuccess()
    self:Close()
    if self.OnGiveUpCb then
        self.OnGiveUpCb()
    end
end