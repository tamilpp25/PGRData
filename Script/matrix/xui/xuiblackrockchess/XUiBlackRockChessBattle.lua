local XUiGridEnergy = XClass(nil, "XUiGridEnergy")

function XUiGridEnergy:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridEnergy:Refresh(valid, isPreview)
    if not valid then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.ImgOn.gameObject:SetActiveEx(not isPreview)
    self.ImgOff.gameObject:SetActiveEx(isPreview)
end

local XUiGridWeapon = XClass(nil, "XUiGridWeapon")

function XUiGridWeapon:Ctor(ui, control)
    XTool.InitUiObjectByUi(self, ui)
    ---@type XBlackRockChessControl
    self.Control = control
end

function XUiGridWeapon:Refresh(weaponId, currentWeaponId)
    self.WeaponId = weaponId
    
    local isCur = weaponId == currentWeaponId
    local unlock = self.Control:IsWeaponUnlock(weaponId)
    self.Select.gameObject:SetActiveEx(isCur and unlock)
    self.Normal.gameObject:SetActiveEx(not isCur and unlock)
    self.Disable.gameObject:SetActiveEx(not unlock)
    
    local icon = self.Control:GetWeaponIcon(weaponId)
    self.RImgSelect:SetRawImage(icon)
    self.RImgNormal:SetRawImage(icon)
    self.RImgDisable:SetRawImage(icon)
end

local XUiGridAffix = XClass(XUiNode, "XUiGridAffix")

function XUiGridAffix:Refresh(buffId, isSelect)
    self.TxtTarget.text = self._Control:GetBuffDesc(buffId)
    self.RImgAffix:SetRawImage(self._Control:GetBuffIcon(buffId))
end


---@class XUiBlackRockChessBattle : XLuaUi
---@field private _Control XBlackRockChessControl
---@field private PanelDetails XUiPanelEnemyDetails
---@field private PanelSkills table<number,XUiPanelBattleSkill>
---@field private GameObject UnityEngine.GameObject
local XUiBlackRockChessBattle = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessBattle")

local XUiPanelBattleSkill = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBattleSkill")

local PC_KEY = {
    ALPHA1 = 850,
    ALPHA2 = 860,
    ALPHA3 = 870,
    ALPHA4 = 990,
    TAB = 880,
    END = 890,
    KEY_E = 900,
    KEY_Q = 910,
    KEY_W = 920,
    KEY_A = 930,
    KEY_S = 940,
    KEY_D = 950,
    LEFT_SHIFT = 960,
    ESCAPE = 970,
    HOME = 980,
    KEY_T = 1000,
}

local CSXInputManager = CS.XInputManager

local ShowEnemyCueId = 1051 --显示敌人棋子详情音效

local BGM_DICT = {
    [XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL] = 390,
    [XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD] = 393,
}


local CueHintInfo = {
    SetHintCb = handler(XMVCA.XBlackRockChess, XMVCA.XBlackRockChess.SetCueTipValue),
    Status = false
}

function XUiBlackRockChessBattle:OnAwake()
    self:InitUi()
    self:InitCb()
    
end

function XUiBlackRockChessBattle:InitCb()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnMainUi.CallBack = function()
        --拦截操作
        if not self:IsOperate() then
            return
        end
        XLuaUiManager.RunMain()
    end

    self.BtnEnd.CallBack = function()
        self:OnBtnEndClick()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end

    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end

    self.BtnView.CallBack = function()
        self._Control:SwitchCamera()
    end

    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end

    self.BtnTarget.CallBack = function()
        self:OnBtnTargetClick()
    end

    self.BtnSetting.CallBack = function()
        self:OnBtnSettingClick()
    end
    
    self.BtnTackBack.CallBack = function() 
        self:OnBtnTackBackClick()
    end

    if XDataCenter.UiPcManager.IsPc() then
        self:AddPCKeyListener()
    end
end

function XUiBlackRockChessBattle:AddPCKeyListener()
    XDataCenter.InputManagerPc.IncreaseLevel()
    XDataCenter.InputManagerPc.SetCurOperationType(CS.XOperationType.BlackRockChess)
    self.OnPcClickCb = handler(self, self.OnPcClick)
    self.KeyDownMap = {
        [PC_KEY.ALPHA1] = function()
            self:OnPcSelectSkill(1)
        end,
        [PC_KEY.ALPHA2] = function()
            self:OnPcSelectSkill(2)
        end,
        [PC_KEY.ALPHA3] = function()
            self:OnPcSelectSkill(3)
        end,
        [PC_KEY.ALPHA4] = function()
            self:OnPcSelectSkill(4)
        end,
        [PC_KEY.TAB] = function()
            self:OnPcSwitchActor()
        end,
        [PC_KEY.END] = function()
            self:OnBtnEndClick()
        end,
        [PC_KEY.KEY_E] = function()
            self:OnPcConfirm()
        end,
        [PC_KEY.KEY_Q] = function()
            self:OnPcCancel()
        end,
        [PC_KEY.LEFT_SHIFT] = function()
            self:OnPcSwitchCamera()
        end,
        [PC_KEY.ESCAPE] = function()
            self:OnBtnBackClick()
        end,
        [PC_KEY.HOME] = function()
            XLuaUiManager.RunMain()
        end,
        [PC_KEY.KEY_T] = function()
            self:OnBtnTackBackClick()
        end
    }
    CSXInputManager.RegisterOnClick(CS.XOperationType.BlackRockChess, self.OnPcClickCb)

    self.OnPcPressCb = handler(self, self.OnPcPress)
    self.KeyPressMap = {
        [PC_KEY.KEY_W] = function()
            self:DragCamera(0, self.DragCameraSpeed)
        end,
        [PC_KEY.KEY_S] = function()
            self:DragCamera(0, -self.DragCameraSpeed)
        end,
        [PC_KEY.KEY_A] = function()
            self:DragCamera(-self.DragCameraSpeed, 0)
        end,
        [PC_KEY.KEY_D] = function()
            self:DragCamera(self.DragCameraSpeed, 0)
        end,
    }
    CSXInputManager.RegisterOnPress(CS.XOperationType.BlackRockChess, self.OnPcPressCb)

end

function XUiBlackRockChessBattle:DelPCKeyListener()
    XDataCenter.InputManagerPc.DecreaseLevel()
    XDataCenter.InputManagerPc.ResumeCurOperationType()
    CSXInputManager.UnregisterOnClick(CS.XOperationType.BlackRockChess, self.OnPcClickCb)
    CSXInputManager.UnregisterOnPress(CS.XOperationType.BlackRockChess, self.OnPcPressCb)
end

function XUiBlackRockChessBattle:OnStart()
    self:InitView()

    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.BROADCAST_ROUND, handler(self, self.ShowRoundBroadcast))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_CHECK_MATE, handler(self, self.SetCheckMateState))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.CLOSE_BUBBLE_SKILL, handler(self, self.OnBubbleSkillClose))

    
    self:RefreshEnergy()
end

function XUiBlackRockChessBattle:OnEnable()
    self:RefreshView()
    self:ChangeState(true, true)
end

function XUiBlackRockChessBattle:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
    }
end

function XUiBlackRockChessBattle:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY,
        XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END
    }
end

function XUiBlackRockChessBattle:OnNotify(evt, ...)
    if not self.GameObject or not self.GameObject.activeInHierarchy then
        return
    end
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE then
        self:ChangeState(true, true)
        self:RefreshView()
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH then
        self:RefreshView()
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY then
        self:ShowEnemyDetail(...)
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END then
        self:OnGamerMoveEnd()
    elseif evt == XEventId.EVENT_GUIDE_START then
        local args = { ... }
        local guideId = args[1] or 0
        local ag = self._Control:GetAgency()
        ag:MarkGuideCurrentCombat(guideId)
    end
end

function XUiBlackRockChessBattle:OnRelease()
    self._Control:ExitFight()
    CS.XAudioManager.StopMusicWithAnalyzer()
    self.Super.OnRelease(self)
end


function XUiBlackRockChessBattle:OnDestroy()
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.BROADCAST_ROUND)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_CHECK_MATE)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.CLOSE_BUBBLE_SKILL)
    if XDataCenter.UiPcManager.IsPc() then
        self:DelPCKeyListener()
    end
end

function XUiBlackRockChessBattle:IsWaiting()
    return self._Control:IsWaiting()
end

--是否为玩家回合
function XUiBlackRockChessBattle:IsOperate()
    if self.SkillPerformance then
        return false
    end
    return self._Control:IsOperate()
end

--region   ------------------Click start-------------------

function XUiBlackRockChessBattle:OnBtnBackClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    XLuaUiManager.SafeClose("UiBlackRockChessBubbleSkill")
    self:Close()
end

function XUiBlackRockChessBattle:OnBtnEndClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end

    if not (self._Control:IsEnterMove() or self._Control:IsEnterSkill()) then
        return
    end
    --移动中不允许结束回合
    if self._Control:IsGamerMoving() then
        return
    end

    if XLuaUiManager.IsUiShow("UiCueMark") then
        return
    end
    
    local doEnd = function()
        self:OnBtnCancelClick()
        self.RImgExtraRound.gameObject:SetActiveEx(false)
        self._Control:OnForceEndRound()
        self:RefreshSkillView()
    end

    if XMVCA.XBlackRockChess:IsShowCueTip() and not self._Control:IsAllActorOperaEnd() then
        local title, c1, c2 = self._Control:GetIsAllActorOperaEndTip()
        XUiManager.DialogHintTip(title, c1, c2, nil, doEnd, CueHintInfo)
    else
        doEnd()
    end
    
end

function XUiBlackRockChessBattle:OnBtnCancelClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    if self.IsMoveState then
        return
    end
    self:ChangeState(true, true)
end

function XUiBlackRockChessBattle:OnBtnConfirmClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local roleId = actor:GetRoleId()
    local curWeaponId = actor:GetWeaponId()
    local skillIds = self._Control:GetWeaponSkillIds(curWeaponId)
    local selectIndex = self.PanelSkills[roleId]:GetSelectIndex()
    if selectIndex <= 0 then
        return
    end
    local skillId = skillIds[selectIndex]
    if not self._Control:CouldUseSkill(roleId, skillId) then
        --XUiManager.TipMsg(self._Control:GetEnergyNotEnoughText(1))
        return
    end
    self.SkillPerformance = true
    self:OnUseWeaponSkill(roleId, skillId)
end

function XUiBlackRockChessBattle:OnUseWeaponSkill(roleId, skillId)
    CS.XBlackRockChess.XBlackRockChessManager.SetLimitClick(true)
    --播放Cv
    local skillType = self._Control:GetWeaponSkillType(skillId)
    self._Control:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.UseSkill, roleId, skillType)
    
    RunAsyn(function()
        self._Control:SyncWaitCvEnd()
        CS.XBlackRockChess.XBlackRockChessManager.SetLimitClick(false)
        local endOfRound = self._Control:GetChessGamer():UseWeaponSkill(roleId, skillId)
        self:RefreshSkillView()
        self:OnAfterSkillUse(roleId, skillId, endOfRound)
    end)
end

--只能在协程里调用，否则会卡死主线程
function XUiBlackRockChessBattle:OnAfterSkillUse(roleId, skillId, endOfRound)
    self._Control:SyncWait()
    --角色技能使用结束
    local role = self._Control:GetChessGamer():GetRole(roleId)
    role:AfterSkillAttack(skillId)
    --关卡结束
    local endOfStage = self._Control:IsFightingStageEnd()
    local state = XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.ROUND_END
    if endOfStage then
        state = XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.STAGE_END
    elseif not endOfRound then
        state = XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.ROUND_EXTRA
    else
        local roleDict = self._Control:GetChessGamer():GetRoleDict()
        for id, role in pairs(roleDict) do
            if id ~= roleId and not role:IsOperaEnd() and role:IsInBoard() then
                role:CallCOnClick()
                state = XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.ACTOR_CHANGE
            end
        end
    end
    if state == XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.ROUND_EXTRA then
        self._Control:BroadcastRound(true, true)
        self.RImgExtraRound.gameObject:SetActiveEx(true)
        self:ChangeState(true, true)
    elseif state == XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.ACTOR_CHANGE then
        self:ChangeState(true, true)
    elseif state == XEnumConst.BLACK_ROCK_CHESS.STAGE_STATE.STAGE_END then
        self._Control:RequestSyncRound()
    else
        self._Control:EndGamerRound()
        self.RImgExtraRound.gameObject:SetActiveEx(false)
    end
    self.SkillPerformance = false
end

function XUiBlackRockChessBattle:OnBtnHelpClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    local stageId = self._Control:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    local helpKey = self._Control:GetStageHelpKey(stageId)
    XUiManager.ShowHelpTip(helpKey)
end

function XUiBlackRockChessBattle:OnBtnTargetClick()
    local isShow = self.PanelInfo.gameObject.activeInHierarchy
    self:PlayAnimationWithMask(isShow and "TargetDisable" or "TargetEnable", function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.PanelInfo.gameObject:SetActiveEx(not isShow)

        local active = self.PanelInfo.gameObject.activeInHierarchy
        self.BtnTarget:SetButtonState(active and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end)
end

function XUiBlackRockChessBattle:OnBtnSettingClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    XLuaUiManager.Open("UiBlackRockChessSetUp")
end

function XUiBlackRockChessBattle:OnBtnTackBackClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    if not (self._Control:IsEnterMove() or self._Control:IsEnterSkill()) then
        return
    end
    self._Control:RequestRetract()
end

--endregion------------------Click finish------------------

function XUiBlackRockChessBattle:InitUi()
    self.GridEnergies = {
        XUiGridEnergy.New(self.GridEnergy1)
    }
    self:InitRole()
    
    self.PanelEnemyDetails.gameObject:SetActiveEx(false)
    
    self.PanelDetails = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelEnemyDetails").New(self.PanelEnemyDetails, self)
    self.PanelBubbles = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBubbleSkill").New(self.PanelSkillDetails, self)
    
    self.PanelHeadList = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelListHead").New(self.ListHead, self)
    self.PanelHeadList:Open()
    self.PanelHeadList:OnSelectRole(self._Control:GetChessGamer():GetSelectActor():GetRoleId())
    
    local stageId = self._Control:GetStageId()
    self.PanelInfo.gameObject:SetActiveEx(true)
    local affixes = self._Control:GetStageDisplayBuffIds(stageId)

    self.GridAffix.gameObject:SetActiveEx(false)
    if XTool.IsTableEmpty(affixes) then
        self.PanelAffix.gameObject:SetActiveEx(false)
    else
        self.DotGrids = {}
        self.PanelAffix.gameObject:SetActiveEx(true)
        self.DynamicCurve = XDynamicTableCurve.New(self.PanelAffix)
        self.DynamicCurve:SetProxy(XUiGridAffix, self)
        self.DynamicCurve:SetDelegate(self)

        self.Affixes = affixes
        self.DynamicCurve:SetDataSource(affixes)
        self.DynamicCurve:ReloadData()
        
        self:RefreshDot()
    end
    
    self.LastSwitchActor = 0
    self.LastSwitchCamera = 0
    
    local value1, value2, value3 = self._Control:GetPCInterval()
    self.SwitchActorInterval = value1
    self.SwitchCameraInterval = value2
    self.DragCameraSpeed = value3
    
    
    self.IgnorePcUiName = {
        "UiBlackRockChessVictorySettlement",
        "UiBlackRockChessSettleLose",
    }

    self.BroadCache = {}

    if XDataCenter.UiPcManager.IsPc() then
        self:SetPcKeyCover(self.BtnView, "LEFT_SHIFT")
        self:SetPcKeyCover(self.BtnEnd, "END")
        self:SetPcKeyCover(self.BtnCancel, "KEY_Q")
        self:SetPcKeyCover(self.BtnConfirm, "KEY_E")
        self:SetPcKeyCover(self.BtnSwitchWeapon, "TAB")
        self:SetPcKeyCover(self.BtnTackBack, "KEY_T")
    end
    self.RImgExtraRound.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattle:InitRole()
    self.PanelSkills = {}
    local panelInfos = {
        [self._Control:GetMasterRoleId()] = "PanelSkillLuna",
        [self._Control:GetAssistantRoleId()] = "PanelSkillLuxiya"
    }
    self.RoleIds = self._Control:GetChessGamer():GetRoleIds()
    local selectId = self._Control:GetSelectActor():GetRoleId()
    self.RoleIndex = 1
    for index, roleId in ipairs(self.RoleIds) do
        if roleId == selectId then
            self.RoleIndex = index
            break
        end
    end
    for roleId, panelName in pairs(panelInfos) do
        self.PanelSkills[roleId] = XUiPanelBattleSkill.New(self[panelName], self, roleId)
    end
end

function XUiBlackRockChessBattle:RefreshEnergy(consume)
    local energy = self._Control:GetEnergy()
    local maxCount = math.max(energy, #self.GridEnergies)
    consume = consume or 0
    for index = 1, maxCount do
        local grid = self:GetGridEnergy(index)
        grid:Refresh(index <= energy, index <= consume and consume > 0)
    end
    self.TxtEnergy.text = energy
end

function XUiBlackRockChessBattle:GetGridEnergy(index)
    local grid = self.GridEnergies[index]
    if not grid then
        if not self.EnergyParent then
            self.EnergyParent = self.GridEnergy1.transform.parent
        end
        local ui = XUiHelper.Instantiate(self.GridEnergy1, self.EnergyParent)
        ui.gameObject.name = "GridEnergy" .. index
        grid = XUiGridEnergy.New(ui)
        self.GridEnergies[index] = grid
    end
    return grid
end

function XUiBlackRockChessBattle:InitView()
    self:PlayAnimation("Enable")
    --self:RefreshView()
    --self:ChangeState(true, true)
    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
    
    --播放BGM
    local stageId = self._Control:GetStageId()
    local difficulty = self._Control:GetStageDifficulty(stageId)
    local cueId = BGM_DICT[difficulty]
    if cueId then
        CS.XAudioManager.PlayMusic(cueId)
    end
end

function XUiBlackRockChessBattle:RefreshView()
    self:RefreshRole()
    self.TxtTarget.text = self._Control:GetTargetDescription()
    local active = self.PanelInfo.gameObject.activeInHierarchy
    self.BtnTarget:SetButtonState(active and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    local disableRetract = self._Control:CheckRetract()
    self.BtnTackBack:SetDisable(not disableRetract)
    self:RefreshSkillView()
end

function XUiBlackRockChessBattle:RefreshRole()
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local selectRoleId = actor:GetRoleId()
    for roleId, panel in pairs(self.PanelSkills) do
        if selectRoleId == roleId then
            panel:Open()
        else
            panel:Close()
        end
    end
    local panel = self.PanelSkills[selectRoleId]
    self:RefreshEnergy(panel:GetSkillCost())
end

function XUiBlackRockChessBattle:RefreshSkillView()
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local panel = self.PanelSkills[actor:GetRoleId()]
    if panel then
        panel:RefreshView()
    end
end

function XUiBlackRockChessBattle:OnSwitchCamera()
    local now = os.time()
    if now - self.LastSwitchCamera < self.SwitchCameraInterval then
        return
    end
    self.LastSwitchCamera = now
    self._Control:SwitchCamera()
end

function XUiBlackRockChessBattle:OnBtnSwitchActorClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    if not self.IsMoveState then
        return
    end
    local isMoving = self._Control:IsGamerMoving()
    --移动中不允许切换角色
    if isMoving then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetForbidSwitchWeaponText(1))
        return
    end
    local roleId = self:GetNextRoleId()
    local actor = self._Control:GetChessGamer():GetRole(roleId)
    if not actor then
        return
    end
    if actor:IsUsePassiveSkill() then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetForbidSwitchWeaponText(3))
        return
    end
    --角色不在场
    if not actor:IsInBoard() then
        XUiManager.TipMsg(self._Control:GetOnSelectRoleTip(1))
        return
    end

    --角色已经操作结束
    if actor:IsOperaEnd() then
        XUiManager.TipMsg(self._Control:GetOnSelectRoleTip(2))
        return
    end
    --切换角色  
    actor:CallCOnClick()
    --进入移动状态
    self:ChangeState(true, true)
    --刷新界面显示
    self:RefreshRole()
end

function XUiBlackRockChessBattle:GetNextRoleId()
    local roleIndex = self.RoleIndex + 1
    if roleIndex > #self.RoleIds then
        roleIndex = 1
    end
    self.RoleIndex = roleIndex
    return self.RoleIds[roleIndex]
end

function XUiBlackRockChessBattle:ChangeState(isMove, isEnterMove)
    self.PanelConfirm.gameObject:SetActiveEx(not isMove)
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local roleId = actor:GetRoleId()
    self.IsMoveState = isMove
    if isMove then
        self.PanelSkills[roleId]:ResetSelect()
        self._Control:OnCancelSkill(roleId, isEnterMove)
        self:HideBubbleSkill()
        --self:ShowBubbleSkill(roleId, actor:GetWeaponId(), XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON)
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    else
        local panel = self.PanelSkills[roleId]
        self._Control:OnSelectSkill(roleId, panel:GetSelectSkillId())
    end
    self:HideEnemyDetail()
end

function XUiBlackRockChessBattle:ShowEnemyDetail(pieceId, isPreview)
    if isPreview then
        if not pieceId and not self.PanelDetails:IsNodeShow() then
            return
        end
        CS.XAudioManager.PlaySound(ShowEnemyCueId)
        self.PanelDetails:Open()
        self.PanelDetails:RefreshView(pieceId) 
    else
        self:HideEnemyDetail()
    end
end

function XUiBlackRockChessBattle:HideEnemyDetail()
    if  not self.PanelDetails:IsNodeShow() then
        return
    end
    self.PanelDetails:Close()
end

function XUiBlackRockChessBattle:ShowBubbleSkill(roleId, id, showType)
    if not self.PanelBubbles:IsNodeShow() then
        self.PanelBubbles:Open()
    end
    self.PanelBubbles:RefreshView(roleId, id, showType)
end

function XUiBlackRockChessBattle:HideBubbleSkill()
    if  not self.PanelBubbles:IsNodeShow() then
        return
    end
    self.PanelBubbles:Close()
end

function XUiBlackRockChessBattle:ShowRoundBroadcast(text)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    --当前正在展示
    if self.PanelTransition.gameObject.activeInHierarchy then
        table.insert(self.BroadCache, text)
        return
    end
    self.PanelTransition.gameObject:SetActiveEx(true)
    self.TxtTransition.text = text
    if not self.RoundTimer then
        self.RoundTimer = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                self:StopRoundTimer()
                return
            end
            self.PanelTransition.gameObject:SetActiveEx(false)
            self:StopRoundTimer()
        end, XScheduleManager.SECOND * 2.5)
    end
end

function XUiBlackRockChessBattle:StopRoundTimer()
    if not self.RoundTimer then
        self:BroadcastByCache()
        return
    end
    XScheduleManager.UnSchedule(self.RoundTimer)
    self.RoundTimer = nil
    self:BroadcastByCache()
end

function XUiBlackRockChessBattle:BroadcastByCache()
    if XTool.IsTableEmpty(self.BroadCache) then
        return
    end
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local text = self.BroadCache[1]
    table.remove(self.BroadCache, 1)
    self:ShowRoundBroadcast(text)
end

function XUiBlackRockChessBattle:SetCheckMateState(value)
    if XTool.UObjIsNil(self.PanelLost) then
        return
    end
    self.PanelLost.gameObject:SetActiveEx(value)
end

function XUiBlackRockChessBattle:OnBubbleSkillClose()
    for _, panel in pairs(self.PanelSkills) do
        panel:OnBubbleClose()
    end
    self.BubbleWeaponId = nil
end

function XUiBlackRockChessBattle:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
end

function XUiBlackRockChessBattle:OnGamerMoveEnd()
    self:ShowEnemyDetail()
end

function XUiBlackRockChessBattle:CheckPcKeyValid()
    if not self:IsOperate() then
        return false
    end
    
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end

    for _, uiName in ipairs(self.IgnorePcUiName) do
        if XLuaUiManager.IsUiShow(uiName) or XLuaUiManager.IsUiLoad(uiName) then
            return false
        end
    end
    
    return true
end

function XUiBlackRockChessBattle:OnPcClick(inputDeviceType, key, clickType, operationType)
    if clickType == CS.XOperationClickType.KeyDown then
        if not self:CheckPcKeyValid() then
            return
        end
        local func = self.KeyDownMap[key]
        if func then func() end
    elseif clickType == CS.XOperationClickType.KeyUp then
        self:DragCamera(0, 0)
    end
end

function XUiBlackRockChessBattle:OnPcPress(inputDeviceType, key, operation)
    if not self:CheckPcKeyValid() then
        return
    end
    local fun = self.KeyPressMap[key]
    if not fun then
        return
    end
    fun()
end

function XUiBlackRockChessBattle:OnPcSelectSkill(index)
    --if not self.IsMoveState then
    --    return
    --end
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local roleId = actor and actor:GetRoleId() or 0
    if not XTool.IsNumberValid(roleId) then
        return
    end
    local panelSkill = self.PanelSkills[roleId]
    if not panelSkill then
        return
    end 
    panelSkill:OnBtnClick(index)
end

function XUiBlackRockChessBattle:OnPcSwitchActor()
    local now = os.time()
    if now - self.LastSwitchActor < self.SwitchActorInterval then
        return
    end
    self.LastSwitchActor = now
    self:OnBtnSwitchActorClick()
end

function XUiBlackRockChessBattle:OnPcConfirm()
    self:OnBtnConfirmClick()
end

function XUiBlackRockChessBattle:OnPcCancel()
    self:OnBtnCancelClick()
end

function XUiBlackRockChessBattle:DragCamera(xOffset, yOffset)
    local deltaTime = CS.UnityEngine.Time.deltaTime
    CS.XBlackRockChess.XBlackRockChessManager.Instance:DragCamera(xOffset * deltaTime, yOffset * deltaTime)
end
 
function XUiBlackRockChessBattle:OnPcSwitchCamera()
    self:OnSwitchCamera()
end

--- 
---@param gameObj UnityEngine.Transform | UnityEngine.GameObject
---@param keyName string
---@return
--------------------------
function XUiBlackRockChessBattle:SetPcKeyCover(gameObj, keyName)
    if not gameObj then
        return
    end
    local customKey = gameObj.gameObject:GetComponentInChildren(typeof(CS.XUiPc.XUiPcCustomKey), true)
    if not customKey then
        return
    end
    customKey.gameObject:SetActiveEx(false)
    if not customKey.SetKey then
        return
    end
    customKey:SetKey(CS.XOperationType.BlackRockChess, self:GetPcKeyCode(keyName))
    customKey.gameObject:SetActiveEx(true)
end

function XUiBlackRockChessBattle:GetPcKeyCode(keyName)
    if not PC_KEY[keyName] then
        return 0
    end
    return PC_KEY[keyName]
end

function XUiBlackRockChessBattle:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Affixes[index + 1])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        self:RefreshDot()
    end
end

function XUiBlackRockChessBattle:RefreshDot()
    local tweenIndex = self.DynamicCurve:GetTweenIndex()
    tweenIndex = tweenIndex + 1 -- 下标从0开始
    for index, _ in ipairs(self.Affixes) do
        local dot = self.DotGrids[index]
        if not dot then
            local ui = index == 1 and self.GridPoint or XUiHelper.Instantiate(self.GridPoint, self.ListPoint)
            dot = {}
            XTool.InitUiObjectByUi(dot, ui)
            self.DotGrids[index] = dot
        end
        local select = tweenIndex == index
        dot.ImagePointOff.gameObject:SetActiveEx(not select)
        dot.ImagePointOn.gameObject:SetActiveEx(select)
    end
end