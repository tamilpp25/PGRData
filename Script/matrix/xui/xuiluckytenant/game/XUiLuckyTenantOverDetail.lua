local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")

---@class XUiLuckyTenantOverDetail : XLuaUi
---@field _Control XLuckyTenantControl
local XUiLuckyTenantOverDetail = XLuaUiManager.Register(XLuaUi, "UiLuckyTenantOverDetail")

function XUiLuckyTenantOverDetail:OnStart(uiState)
    uiState = uiState or XLuckyTenantEnum.OverDetailUi.Over
    self._UiState = uiState
    if uiState == XLuckyTenantEnum.OverDetailUi.Over then
        self.Over.gameObject:SetActiveEx(true)
        self.Restart.gameObject:SetActiveEx(false)
        self.TxtDocNotClear.gameObject:SetActiveEx(not self._Control:IsNormalClear())
        self.BtnRestart.gameObject:SetActiveEx(false)
        self.BtnOver.gameObject:SetActiveEx(true)

    elseif uiState == XLuckyTenantEnum.OverDetailUi.Restart then
        self.Over.gameObject:SetActiveEx(false)
        self.Restart.gameObject:SetActiveEx(true)
        self.BtnRestart.gameObject:SetActiveEx(true)
        self.BtnOver.gameObject:SetActiveEx(false)
    end
end

function XUiLuckyTenantOverDetail:OnAwake()
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    self:BindExitBtns(self.BtnCancel)
    XUiHelper.RegisterClickEvent(self, self.BtnRestart, self.OnClickRestart, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnOver, self.OnClickOver, nil, true)
end

function XUiLuckyTenantOverDetail:OnClickRestart()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_RESTART)
    self:Close()
end

function XUiLuckyTenantOverDetail:OnClickOver()
    self._Control:RequestOver()
end

return XUiLuckyTenantOverDetail