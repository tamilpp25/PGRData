---@class XUiPanelFangKuaiFight3D
local XUiPanelFangKuaiFight3D = XClass(nil, "XUiPanelFangKuaiFight3D")

local IpadResolution = 1.4 -- 4:3
local IphoneXResolution = 2.1 --2436 / 1125

function XUiPanelFangKuaiFight3D:Ctor(uiRoot)
    ---@type XUiFangKuaiFight
    self._UiRoot = uiRoot
end

function XUiPanelFangKuaiFight3D:Destroy()
    self:RemoveRoleTimer()
    self:RemoveBossTimer()
end

function XUiPanelFangKuaiFight3D:InitSceneRoot()
    local panelMyRoleIpad = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelMyModel/PanelIpad")
    local panelBossIpad = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelEnemyModel/PanelIpad")
    local panelMyRoleIphoneX = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelMyModel/PanelIphoneX")
    local panelBossIphoneX = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelEnemyModel/PanelIphoneX")
    local panelMyRoleNormal = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelMyModel/PanelNormal")
    local panelBossNormal = self._UiRoot.UiModelGo.transform:FindTransformWithSplit("PanelEnemyModel/PanelNormal")

    local radio = self._UiRoot.Transform.rect.width / self._UiRoot.Transform.rect.height
    local panelMyModel, panelBossModel
    if radio < IpadResolution then
        panelMyModel = panelMyRoleIpad
        panelBossModel = panelBossIpad
        panelMyRoleIpad.gameObject:SetActiveEx(true)
        panelBossIpad.gameObject:SetActiveEx(true)
        panelMyRoleIphoneX.gameObject:SetActiveEx(false)
        panelBossIphoneX.gameObject:SetActiveEx(false)
        panelMyRoleNormal.gameObject:SetActiveEx(false)
        panelBossNormal.gameObject:SetActiveEx(false)
    elseif radio > IphoneXResolution then
        panelMyModel = panelMyRoleIphoneX
        panelBossModel = panelBossIphoneX
        panelMyRoleIpad.gameObject:SetActiveEx(false)
        panelBossIpad.gameObject:SetActiveEx(false)
        panelMyRoleIphoneX.gameObject:SetActiveEx(true)
        panelBossIphoneX.gameObject:SetActiveEx(true)
        panelMyRoleNormal.gameObject:SetActiveEx(false)
        panelBossNormal.gameObject:SetActiveEx(false)
    else
        panelMyModel = panelMyRoleNormal
        panelBossModel = panelBossNormal
        panelMyRoleIpad.gameObject:SetActiveEx(false)
        panelBossIpad.gameObject:SetActiveEx(false)
        panelMyRoleIphoneX.gameObject:SetActiveEx(false)
        panelBossIphoneX.gameObject:SetActiveEx(false)
        panelMyRoleNormal.gameObject:SetActiveEx(true)
        panelBossNormal.gameObject:SetActiveEx(true)
    end
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(panelMyModel, self._UiRoot.Name, nil, true, nil, true)
    ---@type XUiPanelRoleModel
    self._BossModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(panelBossModel, self._UiRoot.Name, nil, true, nil, true)
end

function XUiPanelFangKuaiFight3D:ShowCharacterModel(role, boss)
    ---@type XTableFangKuaiNpcAction
    self._Role = role
    ---@type XTableFangKuaiNpcAction
    self._Boss = boss
    self._RoleModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil, self._Role.Model, nil, true, nil, nil, true)
    self._BossModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil, self._Boss.Model, nil, true,nil,nil,true)
end

function XUiPanelFangKuaiFight3D:PlayRoleAnimation(state, resetTime)
    local anims = {}
    if state == XEnumConst.FangKuai.RoleAnim.Standby then
        anims = self._Role.StandbyAnim
    elseif state == XEnumConst.FangKuai.RoleAnim.Attack then
        anims = self._Role.AttackAnim
    elseif state == XEnumConst.FangKuai.RoleAnim.Joyful then
        anims = self._Role.JoyfulAnim
    elseif state == XEnumConst.FangKuai.RoleAnim.Move then
        anims = self._Role.MoveFangKuaiAnim
    end
    self:RemoveRoleTimer()
    if #anims > 0 then
        self:PlayRandomAnimation(anims, self._RoleModelPanel, resetTime)
        if state ~= XEnumConst.FangKuai.RoleAnim.Standby and XTool.IsNumberValid(resetTime) then
            self._RoleTimer = XScheduleManager.ScheduleOnce(function()
                self:PlayRoleAnimation(XEnumConst.FangKuai.RoleAnim.Standby)
            end, resetTime)
        end
    end
end

function XUiPanelFangKuaiFight3D:PlayBossAnimation(state, resetTime)
    local anims = {}
    if state == XEnumConst.FangKuai.BossAnim.BossStandby then
        anims = self._Boss.BossStandbyAnim
    elseif state == XEnumConst.FangKuai.BossAnim.BossAttack then
        anims = self._Boss.BossAttackAnim
    end
    self:RemoveBossTimer()
    if #anims > 0 then
        self:PlayRandomAnimation(anims, self._BossModelPanel)
        if state ~= XEnumConst.FangKuai.BossAnim.BossStandby and XTool.IsNumberValid(resetTime) then
            self._BossTimer = XScheduleManager.ScheduleOnce(function()
                self:PlayBossAnimation(XEnumConst.FangKuai.BossAnim.BossStandby)
            end, resetTime)
        end
    end
end

function XUiPanelFangKuaiFight3D:PlayRandomAnimation(anims, model)
    local index = math.random(1, #anims)
    model:CrossFadeAnim(anims[index])
end

function XUiPanelFangKuaiFight3D:RemoveRoleTimer()
    if self._RoleTimer then
        XScheduleManager.UnSchedule(self._RoleTimer)
        self._RoleTimer = nil
    end
end

function XUiPanelFangKuaiFight3D:RemoveBossTimer()
    if self._BossTimer then
        XScheduleManager.UnSchedule(self._BossTimer)
        self._BossTimer = nil
    end
end

return XUiPanelFangKuaiFight3D