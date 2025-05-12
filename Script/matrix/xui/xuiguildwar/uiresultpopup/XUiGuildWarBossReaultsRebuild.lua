local XUiGuildWarBossReaults = require('XUi/XUiGuildWar/XUiGuildWarBossReaults')

--- 公会战7.0新增龙怒系统结束弹窗
---@class XUiGuildWarBossReaultsRebuild: XLuaUi
local XUiGuildWarBossReaultsRebuild = XLuaUiManager.Register(XUiGuildWarBossReaults, 'UiGuildWarBossReaultsRebuild')


function XUiGuildWarBossReaultsRebuild:OnStart(closeCallBack)
    self.CloseCallBack = closeCallBack
end

return XUiGuildWarBossReaultsRebuild