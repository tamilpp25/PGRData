--===========================================================================
 ---@desc 枢纽作战-次级关卡详情界面
--===========================================================================
local XUiPivotCombatSecondaryDetail = XLuaUiManager.Register(XLuaUi, "UiPivotCombatSecondaryDetail")
local XUiPivotCombatPanelEnv        = require("XUi/XUiPivotCombat/XUiPivotCombatPanelEnv")
local XUiPivotCombatPanelEfficiency = require("XUi/XUiPivotCombat/XUiPivotCombatPanelEfficiency")
local XUiPivotCombatPanelAffix      = require("XUi/XUiPivotCombat/XUiPivotCombatPanelAffix")

function XUiPivotCombatSecondaryDetail:OnAwake()
    self:InitUI()
    self:InitCB()
end

function XUiPivotCombatSecondaryDetail:OnEnable(region, stage, closeCb, retreatCb)
    self.Region = region or self.Region
    self.Stage = stage or self.Stage
    self.CloseCb = closeCb or self.CloseCb
    --撤退回调
    self.RetreatCb = retreatCb or self.RetreatCb
    
    self.TxtTitle.text = self.Stage:GetStageName()
    
    local isLockRole = stage:CheckIsLockCharacterStage()
    self.IsLockRole = isLockRole
    self.LockRole.gameObject:SetActiveEx(isLockRole)
    self.Unpass.gameObject:SetActiveEx(isLockRole)

    self.BtnEnter.gameObject:SetActiveEx(true)
    self.BtnReStart.gameObject:SetActiveEx(false)
    
    if isLockRole then
        self:RefreshHeadIcon()
    end
    
    
    --刷新关卡描述
    self.EnvPanel:Refresh(self.Stage:GetTips())
    --刷新关卡环境
    self.EffPanel:Refresh(self.Stage:GetEfficiency())
    --刷新关卡词缀
    self.AffPanel:Refresh(self.Stage:GetAffixes())
end

function XUiPivotCombatSecondaryDetail:InitUI()
    self.EnvPanel = XUiPivotCombatPanelEnv.New(self.PanelEnv)
    self.EffPanel = XUiPivotCombatPanelEfficiency.New(self.PanelEfficiency)
    self.AffPanel = XUiPivotCombatPanelAffix.New(self.PanelAffix)
    
    --头像脚本列表
    self.HeadList = {}
    --头像ui控件列表
    self.HeadUiList = { self.Head01, self.Head02, self.Head03 }
end 

function XUiPivotCombatSecondaryDetail:InitCB()
    self.BtnCloseDetail.CallBack = function()
        if self.CloseCb then
            self.CloseCb()
        end
        self:EmitSignal("SetSelect")
        self:Close()
    end
    self.BtnEnter.CallBack = function() 
        self.Stage:EnterBattleRoleRoom(self.Region:GetRegionId())
    end
    self.BtnReStart.CallBack = function() 
        self:OnClickBtnReStart()
    end
end

function  XUiPivotCombatSecondaryDetail:RefreshHeadIcon()
    local passed = self.Stage:GetPassed()
    self.BtnReStart.gameObject:SetActiveEx(passed)
    self.BtnEnter.gameObject:SetActiveEx(not passed)
    local charIdList = self.Stage:GetCharacterList()
    --锁角色并且未通关
    self.Unpass.gameObject:SetActiveEx(self.IsLockRole and not passed)
    --锁角色且通关
    self.LockRole.gameObject:SetActiveEx(self.IsLockRole and passed)

    if passed then
        self.HeadList = XDataCenter.PivotCombatManager.RefreshHeadIcon(charIdList, self.HeadList, self.HeadUiList)
    end
end

--点击撤退按钮
function XUiPivotCombatSecondaryDetail:OnClickBtnReStart()
    
    local confirm = function()
        XDataCenter.PivotCombatManager.CancelLockCharacterPivotCombatRequest(
                self.Region:GetRegionId(), self.Stage:GetStageId(), function()
                    --取消角色锁定
                    self.Stage:CancelLockCharacter()
                    --刷新头像
                    self:RefreshHeadIcon()
                    --关卡刷新显示
                    if self.RetreatCb then
                        self.RetreatCb(self.Stage)
                    end
                    --触发供能事件
                    XEventManager.DispatchEvent(XEventId.EVENT_PIVOTCOMBAT_ENERGY_REFRESH)
                end
        )
    end
    local title     = CSXTextManagerGetText("PivotCombatRetreatTitle")
    local content   = CSXTextManagerGetText("PivotCombatRetreatContent")
    XUiManager.DialogTip(title, content, nil, nil, confirm)
end 