local XUiChooseRolePanel = require("XUi/XUiDoubleTowers/Choose/XUiChooseRolePanel")
local XUiChooseGuardPanel = require("XUi/XUiDoubleTowers/Choose/XUiChooseGuardPanel")

--动作塔防选择角色/守卫界面
local XUiDoubleTowersChoose = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersChoose")

function XUiDoubleTowersChoose:OnAwake()
    self.ChooseRolePanel = XUiChooseRolePanel.New(self.PanelRoleOption)
    self.ChooseGuardPanel = XUiChooseGuardPanel.New(self.PanelGuardOption)
    self:AutoAddListener()
end

function XUiDoubleTowersChoose:OnStart(chooseType)
    if chooseType == XDoubleTowersConfigs.ModuleType.Role then
        self.ChooseRolePanel:Refresh()
    elseif chooseType == XDoubleTowersConfigs.ModuleType.Guard then
        self.ChooseGuardPanel:Refresh()
    end

    self.ChooseRolePanel.GameObject:SetActiveEx(chooseType == XDoubleTowersConfigs.ModuleType.Role)
    self.ChooseGuardPanel.GameObject:SetActiveEx(chooseType == XDoubleTowersConfigs.ModuleType.Guard)
end

function XUiDoubleTowersChoose:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiDoubleTowersChoose:Close()
    self:EmitSignal("Close")
    self.Super.Close(self)
end