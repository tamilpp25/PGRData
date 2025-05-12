local XUiGuildWarStageResults = require('XUi/XUiGuildWar/XUiGuildWarStageResults')

--- 龙怒玩法节点切换为废墟的弹窗
---@class XUiGuildWarNodeToRelicReaults:XUiGuildWarStageResults
local XUiGuildWarNodeToRelicReaults = XLuaUiManager.Register(XUiGuildWarStageResults, 'UiGuildWarNodeToRelicReaults')

---@overload
function XUiGuildWarNodeToRelicReaults:OnAwake()
    self.Super.OnAwake(self)

    if self.TxtTitle then
        self.TxtTitle.text = XGuildWarConfig.GetClientConfigValues('DragonRageToRelicTitle')[1]
    end
end

return XUiGuildWarNodeToRelicReaults