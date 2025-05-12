local XUiRoleDeployPanel = require("XUi/XUiDoubleTowers/Deploy/XUiRoleDeployPanel")
local XUiGuardDeployPanel = require("XUi/XUiDoubleTowers/Deploy/XUiGuardDeployPanel")

--动作塔防养成界面
local XUiDoubleTowersDeploy = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersDeploy")

function XUiDoubleTowersDeploy:OnAwake()
    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.PanelRoleDeploy = XUiRoleDeployPanel.New(self.RolePanel)
    self.PanelGuardDeploy = XUiGuardDeployPanel.New(self.GuardPanel)

    self.PanelOpenBreakthroughTips.gameObject:SetActiveEx(false)
    self.PanelBreakthroughTips = {}
    XTool.InitUiObjectByUi(self.PanelBreakthroughTips, self.PanelOpenBreakthroughTips)
end

function XUiDoubleTowersDeploy:OnStart(moduleType)
    self:InitBtnPluginGroup()
    self:InitButtons()
    if moduleType then
        self.BtnPluginGroup:SelectIndex(moduleType)
    else
        self.BtnPluginGroup:SelectIndex(XDoubleTowersConfigs.ModuleType.Role)
    end
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDoubleTowersConfigs.GetActivityRewardItemId() }, self.PanelAsset, self)
    XDataCenter.DoubleTowersManager.ShowEquipTips = handler(self, self.OnShowBreakthroughTips)
end

function XUiDoubleTowersDeploy:OnEnable()
    --if not self.CurModuleType then
    --    self.BtnPluginGroup:SelectIndex(XDoubleTowersConfigs.ModuleType.Role)
    --    return
    --end
    self:RegisterEvents()
end

function XUiDoubleTowersDeploy:OnDisable()
    self:RemoveEvents()
end

function XUiDoubleTowersDeploy:RegisterEvents()
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_PLUGIN_CHANGE, self.OnBtnResetStateChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_SLOT_UNLOCK, self.CheckSlotRedPoint, self)
end

function XUiDoubleTowersDeploy:RemoveEvents()
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_PLUGIN_CHANGE, self.OnBtnResetStateChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_SLOT_UNLOCK, self.CheckSlotRedPoint, self)
end

function XUiDoubleTowersDeploy:CheckSlotRedPoint()
    XRedPointManager.Check(self.RedPointTabBtn1, { ModuleType = XDoubleTowersConfigs.ModuleType.Role })
    XRedPointManager.Check(self.RedPointTabBtn2, { ModuleType = XDoubleTowersConfigs.ModuleType.Guard })
end

function XUiDoubleTowersDeploy:Refresh()
    if self.CurModuleType == XDoubleTowersConfigs.ModuleType.Role then
        self.PanelRoleDeploy:Refresh()
    elseif self.CurModuleType == XDoubleTowersConfigs.ModuleType.Guard then
        self.PanelGuardDeploy:Refresh()
    end
    self.PanelRoleDeploy.GameObject:SetActiveEx(self.CurModuleType == XDoubleTowersConfigs.ModuleType.Role)
    self.PanelGuardDeploy.GameObject:SetActiveEx(self.CurModuleType == XDoubleTowersConfigs.ModuleType.Guard)
    
    self:CheckSlotRedPoint()
end

--初始化插件按钮组
function XUiDoubleTowersDeploy:InitBtnPluginGroup()
    local tabGroup = {self.BtnDefense, self.BtnStreng}
    self.BtnPluginGroup:Init(tabGroup, function(tabIndex) self:OnBtnPluginGroupClicked(tabIndex) end)

    for idx, tabBtn in ipairs(tabGroup) do
        self["RedPointTabBtn"..idx] = XRedPointManager.AddRedPointEvent(tabBtn, function(_, count)
            tabBtn:ShowReddot(count >= 0)
        end, self, {
            XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS_SLOT_UNLOCKED,
        })
    end
end

function XUiDoubleTowersDeploy:InitButtons()

    self.BtnBack.CallBack = function() 
        self:Close()
    end
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
    self.BtnReset.CallBack = function() 
        self:OnBtnResetClick()
    end
    self:BindHelpBtn(self.BtnHelp, "DoubleTowerDeployHelp")
end

function XUiDoubleTowersDeploy:OnBtnResetStateChange()
    local list = self.BaseInfo:GetPluginListByType(self.CurModuleType)
    local state = XTool.IsTableEmpty(list) and XUiButtonState.Disable or XUiButtonState.Normal
    local defaultPluginId = XDoubleTowersConfigs.GetRoleDefaultPluginId()
    if self.CurModuleType == XDoubleTowersConfigs.ModuleType.Role 
            and #list == 1 
            and list[1] == defaultPluginId then
        local pluginDb = self.BaseInfo:GetPluginDb(defaultPluginId)
        local level = not XTool.IsTableEmpty(pluginDb) and pluginDb:GetLevel() or 0
        state = level == 1 and XUiButtonState.Disable or XUiButtonState.Normal
    end 
    self.BtnReset:SetButtonState(state)
end

function XUiDoubleTowersDeploy:OnBtnResetClick()
    if self.BtnReset.ButtonState == CS.UiButtonState.Disable then
        return
    end
    local list = self.BaseInfo:GetPluginListByType(self.CurModuleType)
    
    XDataCenter.DoubleTowersManager.RequestDoubleTowerResetPlugin(list, function()
        self.TeamDb:ResetPlugin(self.CurModuleType)
        self:OnBtnResetStateChange()
        self:Refresh()
        XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam()
    end)
end

function XUiDoubleTowersDeploy:OnBtnPluginGroupClicked(tabIndex)
    if self.CurModuleType == tabIndex then
        return
    end
    self:PlayAnimation("QieHuan")
    self.CurModuleType = tabIndex
    self:OnBtnResetStateChange()
    XDataCenter.DoubleTowersManager.RefreshSelectModuleType(tabIndex)
    self:Refresh()
end

function XUiDoubleTowersDeploy:OnShowBreakthroughTips(text)
    if text then
        self.PanelBreakthroughTips.TxtDes.text = text
        self.PanelOpenBreakthroughTips.gameObject:SetActiveEx(true)
        self:PlayAnimation("TipsEnable", function() 
            self.PanelOpenBreakthroughTips.gameObject:SetActiveEx(false)
        end)
    end
end 