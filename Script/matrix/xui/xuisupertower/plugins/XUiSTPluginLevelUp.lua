--===========================
--超级爬塔芯片升级弹窗页面
--===========================
local XUiSTPluginLevelUp = XLuaUiManager.Register(XLuaUi, "UiSuperTowerPlugUp")

function XUiSTPluginLevelUp:OnAwake()
    XTool.InitUiObject(self)
    self.GridPlugin.gameObject:SetActiveEx(false)
    self.PluginGrids = {}
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiSTPluginLevelUp:OnStart(oldList, newList, closeCallback)
    self.PrePluginList = oldList
    self.NewPluginList = newList
    self.OnCloseCallBack = closeCallback
    self:ShowPanel()
end

function XUiSTPluginLevelUp:ShowPanel()
    self:ShowPlugins(self.PrePluginList, self.Panelup.transform)
    self:ShowPlugins(self.NewPluginList, self.PanelUpNew.transform)
end

function XUiSTPluginLevelUp:ShowPlugins(pluginList, parent)
    if not pluginList or not parent then return end
    local gridScript = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
    for _, plugin in pairs(pluginList) do
        local gridGO = CS.UnityEngine.Object.Instantiate(self.GridPlugin.gameObject)
        gridGO.transform:SetParent(parent, false)
        local grid = gridScript.New(gridGO)      
        grid:RefreshData(plugin)
        grid:ShowPanel()
    end
end

function XUiSTPluginLevelUp:OnClose()
    self:Close()
    if self.OnCloseCallBack then
        local cb = self.OnCloseCallBack
        self.OnCloseCallBack = nil
        cb()
    end
end

function XUiSTPluginLevelUp:OnDisable()
    self:OnClose()
end

function XUiSTPluginLevelUp:OnDestroy()
    self:OnClose()
end