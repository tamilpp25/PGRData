local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local XUiSuperTowerRolePluginUnlockTip = XLuaUiManager.Register(XLuaUi, "UiSuperTowerUnlocking")

function XUiSuperTowerRolePluginUnlockTip:OnAwake()
    self.BtnClose.CallBack = function() self:Close() end
end

-- superTowerRole : XSuperTowerRole
function XUiSuperTowerRolePluginUnlockTip:OnStart(superTowerRole)
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    -- 标题
    self.TxtTitle.text = string.format("%s"..CS.XTextManager.GetText("STCharacterPluginUnlockTip"), characterViewModel:GetLogName()) -- 海外修改(替换代码中中文文本)
    -- 插件
    local plugin = superTowerRole:GetTransfinitePlugin()
    local grid = XUiSuperTowerPluginGrid.New(self.GridPlugin)
    grid:RefreshData(plugin)
end

return XUiSuperTowerRolePluginUnlockTip