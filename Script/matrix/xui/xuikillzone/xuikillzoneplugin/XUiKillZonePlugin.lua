local XUiGridKillZonePluginGroup = require("XUi/XUiKillZone/XUiKillZonePlugin/XUiGridKillZonePluginGroup")
local XUiGridKillZonePluginSlotOperate = require("XUi/XUiKillZone/XUiKillZonePlugin/XUiGridKillZonePluginSlotOperate")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZonePlugin = XLuaUiManager.Register(XLuaUi, "UiKillZonePlugin")

function XUiKillZonePlugin:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener({ XKillZoneConfigs.ItemIdCoinB }, handler(self, self.UpdateAssets), self.AssetActivityPanel)

    self.GridPluginGroup.gameObject:SetActiveEx(false)
    self.GridSlot.gameObject:SetActiveEx(false)
end

function XUiKillZonePlugin:OnStart()
    self.SelectSlot = XDataCenter.KillZoneManager.GetNextEmptySlot()
    self.PluginSlotGrids = {}

    XDataCenter.KillZoneManager.ClearCookiePluginOperate()

    self:SetAutoCloseInfo(XDataCenter.KillZoneManager.GetEndTime(), function(isClose)
        if isClose then
            self.IsEnd = true
            XDataCenter.KillZoneManager.OnActivityEnd()
        end
    end)
end

function XUiKillZonePlugin:OnEnable()
    self.Super.OnEnable(self)

    self:UpdateAssets()
    self:UpdatePluginSlots()
    self:UpdatePluginGroups()
end

function XUiKillZonePlugin:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_PLUGIN_CHANGE,
        XEventId.EVENT_KILLZONE_PLUGIN_SLOT_CHANGE,
    }
end

function XUiKillZonePlugin:OnNotify(evt, ...)
    if self.IsEnd then return end

    local args = { ... }
    if evt == XEventId.EVENT_KILLZONE_PLUGIN_CHANGE then
        self:UpdatePluginSlots()
        self:UpdatePluginGroups()
    elseif evt == XEventId.EVENT_KILLZONE_PLUGIN_SLOT_CHANGE then
        self:UpdatePluginSlots()
    end
end

function XUiKillZonePlugin:UpdateAssets()
    self.AssetActivityPanel:Refresh({ XKillZoneConfigs.ItemIdCoinB })
end

function XUiKillZonePlugin:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPluginList)
    self.DynamicTable:SetProxy(XUiGridKillZonePluginGroup)
    self.DynamicTable:SetDelegate(self)
    self.PluginGroupIds = XKillZoneConfigs.GetPluginGroupIds()
    self.DynamicTable:SetDataSource(self.PluginGroupIds)
end

function XUiKillZonePlugin:UpdatePluginGroups()
    self.DynamicTable:ReloadDataSync()
end

function XUiKillZonePlugin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local clickCb = handler(self, self.OnClickPlugin)
        grid:SetClickCb(clickCb)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local groupId = self.PluginGroupIds[index]
        grid:Refresh(groupId)
        grid:SetSelectPlugin(self.SelectPluginId)
    end
end

function XUiKillZonePlugin:OnClickPlugin(pluginId, gridTransform)
    if self.IsEnd then
        return
    end
    self.SelectPluginId = pluginId
    self:UpdatePluginGroups()
    local closeCb = function()
        self.SelectPluginId = nil
        self:UpdatePluginGroups()
    end


    local worldPos = gridTransform.position
    local localPos = self.PanelPluginList.transform:InverseTransformPoint(worldPos)
    local specialPosition = localPos.x < 0
    XLuaUiManager.Open("UiKillZonePluginPopup", self.SelectSlot, pluginId, false, closeCb, specialPosition)
end

function XUiKillZonePlugin:UpdatePluginSlots()
    local maxSlotNum = XKillZoneConfigs.GetMaxPluginSlotNum()

    for index = 1, maxSlotNum do
        local grid = self.PluginSlotGrids[index]
        if not grid then
            local go = index == 1 and self.GridSlot or CS.UnityEngine.Object.Instantiate(self.GridSlot, self.PanelSlotContent)
            local clickCb = handler(self, self.OnClickPluginSlot)
            grid = XUiGridKillZonePluginSlotOperate.New(go, clickCb)
            self.PluginSlotGrids[index] = grid
        end

        grid:Refresh(index)
        grid:SetSelect(index == self.SelectSlot)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiKillZonePlugin:OnClickPluginSlot(slot)
    if self.IsEnd then
        return
    end
    local isLock = not XDataCenter.KillZoneManager.IsPluginSlotUnlock(slot)
    if isLock then
        local msg = XKillZoneConfigs.GetPluginSlotConditionDesc(slot)
        XUiManager.TipMsg(msg)
        return
    end

    local pluginId = XDataCenter.KillZoneManager.GetSlotWearingPluginId(slot)
    if XTool.IsNumberValid(pluginId) then
        XLuaUiManager.Open("UiKillZonePluginPopup", slot, pluginId, true)
    else
        XUiManager.TipText("KillZoneSelectPlguinEmptyOperate")
    end

    --选中对应孔位
    self.SelectSlot = slot

    self:UpdatePluginSlots()
end

function XUiKillZonePlugin:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "KillZoneMain")
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnReset.CallBack = function() self:OnClickBtnReset() end
end

function XUiKillZonePlugin:OnClickBtnBack()
    self:Close()
end

function XUiKillZonePlugin:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiKillZonePlugin:OnClickBtnReset()
    if self.IsEnd then
        return
    end
    local pluginIds = XDataCenter.KillZoneManager.GetCanResetPluginIds()
    if XTool.IsTableEmpty(pluginIds) then
        XUiManager.TipText("KillZoneResetPlguinEmpty")
        return
    end
    XLuaUiManager.Open("UiKillZonePluginReset", pluginIds)
end