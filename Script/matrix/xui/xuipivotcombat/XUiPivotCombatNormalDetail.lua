--===========================================================================
 ---@desc 中心关卡详情界面
--===========================================================================
local XUiPivotCombatNormalDetail = XLuaUiManager.Register(XLuaUi, "UiPivotCombatNormalDetail")
local XUiPivotCombatPanelEnv        = require("XUi/XUiPivotCombat/XUiPivotCombatPanelEnv")
local XUiPivotCombatPanelAffix      = require("XUi/XUiPivotCombat/XUiPivotCombatPanelAffix")

function XUiPivotCombatNormalDetail:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiPivotCombatNormalDetail:OnEnable(stage, onAnimationEncCb)
    self.Stage = stage or self.Stage
    self.OnAnimationEncCb = onAnimationEncCb or self.OnAnimationEncCb
    --显示名称
    self.TxtTitle.text = self.Stage:GetStageName()
    --更新词缀
    self.AffPanel:Refresh(self.Stage:GetAffixes())
    --更新环境
    self.EnvPanel:Refresh(self.Stage:GetTips())
    --更新行动说明
    self.IroPanel:Refresh(self.Stage:GetEfficiency())
end

--界面隐藏时关闭
function XUiPivotCombatNormalDetail:OnDisable()
    self:Close()
end

function XUiPivotCombatNormalDetail:InitUI()
    self.EnvPanel = XUiPivotCombatPanelEnv.New(self.PanelEnv)
    self.AffPanel = XUiPivotCombatPanelAffix.New(self.PanelAffix)
    self.IroPanel = XUiPivotCombatPanelEnv.New(self.PanelIntro)
end 

function XUiPivotCombatNormalDetail:InitCB()
    self.BtnCloseDetail.CallBack = function() 
        self:Close()
        if self.OnAnimationEncCb then
            self.OnAnimationEncCb()
        end
    end
    self.BtnEnter.CallBack = function()
        local region = XDataCenter.PivotCombatManager.GetCenterRegion()
        if not region then return end
        self.Stage:EnterBattleRoleRoom(region:GetRegionId())
    end
    self.BtnTeachStage.CallBack = function()
        XLuaUiManager.Open("UiBattleRoleRoom", XPivotCombatConfigs.TeachStageId)
    end
end 