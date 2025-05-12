local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local XUiSuperTowerRolePluginUnlockTip = XLuaUiManager.Register(XLuaUi, "UiSuperTowerUnlocking")

function XUiSuperTowerRolePluginUnlockTip:OnAwake()
    self.BtnClose.CallBack = function() self:Close() end
end

-- superTowerRole : XSuperTowerRole
function XUiSuperTowerRolePluginUnlockTip:OnStart(superTowerRole)
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    -- 标题
    self.TxtTitle.text = string.format("%s专属插件解锁", characterViewModel:GetLogName())
    -- 插件
    local plugin = superTowerRole:GetTransfinitePlugin()
    local grid = XUiSuperTowerPluginGrid.New(self.GridPlugin)
    grid:RefreshData(plugin)
end

return XUiSuperTowerRolePluginUnlockTip