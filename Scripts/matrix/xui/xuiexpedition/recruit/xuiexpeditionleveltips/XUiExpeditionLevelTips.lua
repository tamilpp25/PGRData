--虚像地平线招募界面：等级提示子页面
local XUiExpeditionLevelTips = XLuaUiManager.Register(XLuaUi, "UiExpeditionLevelTips")
function XUiExpeditionLevelTips:OnAwake()
    XTool.InitUiObject(self)
    self:AddListener()
end

function XUiExpeditionLevelTips:AddListener()
    self.BtnClose.CallBack = function() self:Close() end
end