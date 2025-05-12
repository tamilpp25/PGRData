--region XUiGridEnergy
local XUiGridEnergy = XClass(nil, "XUiGridEnergy")

local MAX_HP_GRID = 10 --一条血条表示的最大血量
local MAX_HP_COUNT = 8 --血条最大数量

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
--endregion

--region XUiGridWeapon
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
--endregion

--region XUiGridAffix
local XUiGridAffix = XClass(XUiNode, "XUiGridAffix")

function XUiGridAffix:Refresh(buffId, isSelect)
    self.RImgAffix:SetRawImage(self._Control:GetBuffIcon(buffId))
end
--endregion

---@class XUiBlackRockChessBattle : XLuaUi
---@field private _Control XBlackRockChessControl
---@field private PanelDetails XUiPanelEnemyDetails
---@field private PanelSkills table<number,XUiPanelBattleSkill>
---@field private GameObject UnityEngine.GameObject
---@field private PanelBubbles XUiPanelBubbleSkill
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


local CueHintInfo = {
    SetHintCb = handler(XMVCA.XBlackRockChess, XMVCA.XBlackRockChess.SetCueTipValue),
    Status = false
}

function XUiBlackRockChessBattle:OnAwake()
    self:InitUi()
    self:InitCb()
    self:InitBoss()
end

function XUiBlackRockChessBattle:InitCb()
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
        self:OnSwitchCamera()
    end

    self.BtnSetting.CallBack = function()
        self:OnBtnSettingClick()
    end

    if XDataCenter.UiPcManager.IsPc() then
        self:AddPCKeyListener()
    end
    self.BtnMask.CallBack = handler(self, self.OnBtnMaskClick)
end

function XUiBlackRockChessBattle:AddPCKeyListener()
    XDataCenter.InputManagerPc.IncreaseLevel()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.BlackRockChess)
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
            if self:IsForbidPcKey() then
                return
            end
            XLuaUiManager.RunMain()
        end,
    }
    CSXInputManager.RegisterOnClick(CS.XInputManager.XOperationType.BlackRockChess, self.OnPcClickCb)

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
    CSXInputManager.RegisterOnPress(CS.XInputMapId.BlackRockChess, self.OnPcPressCb)

end

function XUiBlackRockChessBattle:DelPCKeyListener()
    XDataCenter.InputManagerPc.DecreaseLevel()
    XDataCenter.InputManagerPc.ResumeCurInputMap()
    CSXInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.BlackRockChess, self.OnPcClickCb)
    CSXInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.BlackRockChess, self.OnPcPressCb)
end

function XUiBlackRockChessBattle:OnStart(isNewGame)
    self:InitView()

    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BROADCAST_ROUND, self.ShowRoundBroadcast, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, self.SetCheckMateState, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CLOSE_BUBBLE_SKILL, self.OnBubbleSkillClose, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SELECT_PARTNER, self.HideEnemyDetail, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_POSSESS, self.UpdateRolePossess, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SHOP, self.ShowShopBuff, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, self.RefreshBattleView, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_ERENGY_UPDATE, self.RefreshEnergy, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_WIN, self.HideAllUiOnPlayWin, self)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_KILL, self.RefreshKillAndRound, self)
    self:RefreshEnergy()
    self:UpdateRolePossess()

    if isNewGame then
        -- 检查是否打开播报和商店界面
        self:CheckOpenToastAndShop()
    end
end

function XUiBlackRockChessBattle:OnEnable()
    self:RefreshView()
    if self._Control:GetChessPartner():IsPassPreparationStage() then
        self:ChangeState(true, false)
    else
        self:ChangeState(false, false, true)
    end
    self:CloseBuffTip()
    self:ShowShopBuff()
    self:RefreshKillAndRound()
end

function XUiBlackRockChessBattle:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
    }
end

function XUiBlackRockChessBattle:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_BOSS,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_PLAYER,
        XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END,
        XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_SKILL,
    }
end

function XUiBlackRockChessBattle:OnNotify(evt, ...)
    if not self.GameObject or not self.GameObject.activeInHierarchy then
        return
    end
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE then
        self:ChangeState(true, true)
        self:RefreshView()
        self:RefreshKillAndRound()
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY then
        self:ShowEnemyDetail(...)
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_BOSS then
        local args = { ... }
        local bossId = args[1]
        local skillId = args[2]
        local isShow = args[3]
        if isShow then
            self:ShowPanelBossDetail(bossId, skillId)
        else
            self:HideBossDetail()
        end
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_PLAYER then
        self:HideEnemyDetail()
        self:HideBubbleSkill()
        self:HideBossDetail()
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END then
        self:OnGamerMoveEnd()
    elseif evt == XEventId.EVENT_GUIDE_START then
        local args = { ... }
        local guideId = args[1] or 0
        local ag = self._Control:GetAgency()
        ag:MarkGuideCurrentCombat(guideId)
    elseif evt == XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_SKILL then
        local args = { ... }
        local skillType = args[1]
        local isDelay = args[2]
        local cb = args[3]
        self:OnPlaySkill(skillType, isDelay, cb)
    end
end

function XUiBlackRockChessBattle:OnRelease()
    self._Control:ExitFight()
    CS.XAudioManager.StopMusicWithAnalyzer()
    self.Super.OnRelease(self)
end


function XUiBlackRockChessBattle:OnDestroy()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BROADCAST_ROUND, self.ShowRoundBroadcast, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, self.SetCheckMateState, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CLOSE_BUBBLE_SKILL, self.OnBubbleSkillClose, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_SELECT_PARTNER, self.HideEnemyDetail, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_POSSESS, self.UpdateRolePossess, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SHOP, self.ShowShopBuff, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, self.RefreshBattleView, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_ERENGY_UPDATE, self.RefreshEnergy, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_WIN, self.HideAllUiOnPlayWin, self)
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_KILL, self.RefreshKillAndRound, self)
    if XDataCenter.UiPcManager.IsPc() then
        self:DelPCKeyListener()
    end
    self:ClearBigSkillTipsTimer()
end

function XUiBlackRockChessBattle:RefreshBattleView(isUpdateToast)
    self:RefreshView()
    if isUpdateToast then
        self:UpdateToastAndShopOnRestart()
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

function XUiBlackRockChessBattle:CheckOpenToastAndShop()
    local nodeCfg = self._Control:GetCurNodeCfg()
    if not nodeCfg then
        return
    end

    XLuaUiManager.OpenWithCloseCallback("UiBlackRockChessToastRound", function()
        --在出弹框期间点击Esc UiBlackRockChessBattle会被关闭 这时self._Control变成了nil
        if self._Control then
            self._Control:StartGameRound()
        end
    end)

    local desc = self._Control:GetCurNodeCfg().Desc
    if not desc or desc == "" then
        self.PanelDetail.gameObject:SetActiveEx(false)
    else
        self.PanelDetail.gameObject:SetActiveEx(true)
        self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(desc)
    end
end

function XUiBlackRockChessBattle:UpdateToastAndShopOnRestart()
    XLuaUiManager.SafeClose("UiBlackRockChessToastRound")
    XLuaUiManager.SafeClose("UiBlackRockChessBattleShop")
    self:ChangeState(true, false)
    self:CheckOpenToastAndShop()
end

--region   ------------------Click start-------------------

function XUiBlackRockChessBattle:OnBtnBackClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    local uiName = XLuaUiManager.GetTopUiName()
    if uiName ~= "UiBlackRockChessBubbleSkill" or uiName ~= self.Name then
        XLuaUiManager.Close(uiName)
        return
    end
    XLuaUiManager.SafeClose("UiBlackRockChessBubbleSkill")
    self:Close()
end

function XUiBlackRockChessBattle:IsForbidPcKey()
    local uiName = XLuaUiManager.GetTopUiName()
    return uiName ~= "UiBlackRockChessBubbleSkill" and uiName ~= self.Name
end

function XUiBlackRockChessBattle:OnBtnEndClick()
    if self:IsForbidPcKey() then
        return
    end
    --非玩家回合 屏蔽结束回合
    if CS.XBlackRockChess.XBlackRockChessManager.IsLimitClick then
        return
    end
    
    --拦截操作
    if not self:IsOperate() then
        return
    end

    if not (self._Control:IsEnterMove() or self._Control:IsEnterSkill() or self._Control:IsEnemySelect()) then
        return
    end
    --移动中不允许结束回合
    if self._Control:IsGamerMoving() then
        return
    end

    if XLuaUiManager.IsUiShow("UiCueMark") then
        return
    end

    if not self._Control:IsPassNetworkCd() then
        return
    end

    --弹框已经打开了（针对PC按键）
    if XLuaUiManager.IsUiShow("UiBlackRockChessTip") then
        return
    end
    
    local doEnd = function()
        --结束玩家回合 屏蔽棋盘点击
        CS.XBlackRockChess.XBlackRockChessManager.SetLimitClick(true)
        self:HideBossDetail()
        self:OnBtnCancelClick()
        self.RImgExtraRound.gameObject:SetActiveEx(false)
        self._Control:OnForceEndRound()
        self:RefreshSkillView()
    end

    if XMVCA.XBlackRockChess:IsShowCueTip() and not self._Control:IsAllActorOperaEnd() then
        local _, title, _ = self._Control:GetIsAllActorOperaEndTip()
        XLuaUiManager.Open("UiBlackRockChessTip", title, nil, doEnd, nil, nil, CueHintInfo)
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
    --恢复头像显示
    self.PanelConfirm.gameObject:SetActiveEx(false)
    self.PanelSkills[roleId]:ResetSelect()
    
    local skillId = skillIds[selectIndex]
    if not self._Control:CouldUseSkill(roleId, skillId) then
        --XUiManager.TipMsg(self._Control:GetEnergyNotEnoughText(1))
        return
    end
    self.SkillPerformance = true
    self:OnUseWeaponSkill(roleId, skillId)
end

function XUiBlackRockChessBattle:OnUseWeaponSkill(roleId, skillId)
    --使用技能 玩家回合结束 屏蔽棋盘点击
    CS.XBlackRockChess.XBlackRockChessManager.SetLimitClick(true)
    self._Control:IsWaittingPlaySkill(true)
    --播放Cv
    local skillType = self._Control:GetWeaponSkillType(skillId)
    self._Control:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.UseSkill, roleId, skillType)

    self._Control:RunAsynWithPCall(function()
        local actor = self._Control:GetMasterRole()
        actor:SetForceExitMove(true)
        self._Control:SyncWaitCvEnd()
        self._Control:IsWaittingPlaySkill(false)
        local endOfRound = self._Control:GetChessGamer():UseWeaponSkill(roleId, skillId)
        self:RefreshSkillView()
        self:OnAfterSkillUse(roleId, skillId, endOfRound)
        actor:SetForceExitMove(false)
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

function XUiBlackRockChessBattle:OnBtnSettingClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    XLuaUiManager.Open("UiBlackRockChessSetUp")
end

--[[function XUiBlackRockChessBattle:OnBtnTackBackClick()
    --拦截操作
    if not self:IsOperate() then
        return
    end
    if not (self._Control:IsEnterMove() or self._Control:IsEnterSkill()) then
        return
    end
    self._Control:RequestRetract()
end]]

--endregion------------------Click finish------------------

function XUiBlackRockChessBattle:InitUi()
    self._MaxEnergy = self._Control:GetMaxEnergy()
    self._Vec4Temp = CS.UnityEngine.Vector4(0, 0, 0, 0)
    self._EulerTemp = CS.UnityEngine.Quaternion.Euler(0, 0, 0)
    --self.GridEnergies = {
    --    XUiGridEnergy.New(self.GridEnergy1)
    --}
    self:InitRole()
    
    self.PanelEnemyDetails.gameObject:SetActiveEx(false)
    
    self.PanelDetails = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelEnemyDetails").New(self.PanelEnemyDetails, self)
    self.PanelBubbles = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBubbleSkill").New(self.PanelSkillDetails, self)

    self.PanelHeadList = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelListHead").New(self.PanelTalk, self)
    self.PanelHeadList:Open()
    
    local stageId = self._Control:GetStageId()
    local affixes = self._Control:GetStageDisplayBuffIds(stageId)
    
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
    end
    self.RImgExtraRound.gameObject:SetActiveEx(false)
    self.PanelBubbleSkillDetail.gameObject:SetActiveEx(false)
    self.BtnMask.gameObject:SetActiveEx(false)
    self.PanelBossDetails.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattle:InitRole()
    self.PanelSkills = {}
    local panelInfos = {
        [self._Control:GetMasterRoleId()] = "PanelSkill",
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

function XUiBlackRockChessBattle:RefreshEnergy()
    local energy = self._Control:GetEnergy()
    local roleId = self._Control:GetSelectActor():GetRoleId()
    local actor = self._Control:GetChessGamer():GetRole(roleId)
    local energyBg = self._Control:GetEnergyBgByActorRedModel()
    if self._Control:IsEnterRedModel() then
        -- 红莲
        self:PlayEnterRedModelAnim()
    else
        self.ImgHpBar.gameObject:SetActiveEx(true)
        self.ImgHpRedBar.gameObject:SetActiveEx(false)
        self.EffectProfileFire.gameObject:SetActiveEx(false)
        self.EffectRImgHead.gameObject:SetActiveEx(false)
        self:PlayNormalBloodAnim()
    end
    self._CurEnergy = energy
    self.TxtEnergy.text = energy
    self.TxtHp.text = actor:GetSurvivalCount()
    self.ImgActorEnergy:SetRawImage(energyBg)
end

function XUiBlackRockChessBattle:PlayNormalBloodAnim()
    local energy = self._Control:GetEnergy()
    local progress = energy / self._MaxEnergy
    
    if not self._CurEnergy or self._CurEnergy > energy then
        self.ImgHpBar.fillAmount = progress
    elseif self._CurEnergy < energy then
        local lastProgress = self._CurEnergy / self._MaxEnergy
        self:Tween(0.4, function(weight)
            self.ImgHpBar.fillAmount = lastProgress + (progress - lastProgress) * weight
        end)
    end
end

function XUiBlackRockChessBattle:PlayEnterRedModelAnim()
    local energy = self._Control:GetEnergy()
    local progress = energy / self._MaxEnergy
    local effectProgress = progress - 0.5

    --切换为红莲头像时显示的特效
    self.EffectProfileFire.gameObject:SetActiveEx(true)
    self.EffectRImgHead.gameObject:SetActiveEx(true)
    
    if not self._CurEnergy or self._CurEnergy > energy then
        self.ImgHpBar.gameObject:SetActiveEx(false)
        self.ImgHpRedBar.gameObject:SetActiveEx(true)
        --血条特效
        self._Vec4Temp:Set(1, 1, effectProgress, 0)
        self.HpBarFireLoop.material:SetVector("_MaskTex_ST", self._Vec4Temp)
        self.HpBarFire2Loop.material:SetVector("_MaskTex_ST", self._Vec4Temp)
        --血条没变化 无需显示血条刷新特效
        self.EffectHpBar.gameObject:SetActiveEx(false)
    elseif self._CurEnergy < energy then
        local isInit = true
        local lastProgress = self._CurEnergy / self._MaxEnergy
        --血条变化时刷新的特效
        self._Vec4Temp:Set(1, 1, effectProgress, 0)
        self.EffectHpBar.gameObject:SetActiveEx(true)
        self.HpBarFlowPar.material:SetVector("_MaskTex_ST", self._Vec4Temp)
        self.HpBarLightTailPar.material:SetVector("_MaskTex_ST", self._Vec4Temp)
        --血条缓动特效
        self:Tween(0.4, function(weight)
            self:OnRefreshBloodTween(lastProgress, progress, weight)
            if isInit then
                self.ImgHpBar.gameObject:SetActiveEx(false)
                self.ImgHpRedBar.gameObject:SetActiveEx(true)
            end
        end, function()
            self.EffectHpBar.gameObject:SetActiveEx(false)
        end)
    end

    local limit = self._Control:GetEnterRedModelEnergy()
    if self._CurEnergy and self._CurEnergy < limit and energy >= limit then
        --播放进入红莲状态特效
        if not self._BurstEnable then
            self._BurstEnable = self.EffectRImgHead:Find("Animation/BurstEnable")
        end
        if self._BurstEnable then
            self._BurstEnable:PlayTimelineAnimation()
        end
        self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.ENTER_RED_MODEL)
    end
end

function XUiBlackRockChessBattle:OnRefreshBloodTween(lastProgress, progress, weight)
    --血条底图缓动
    local value = lastProgress + (progress - lastProgress) * weight
    self.ImgHpRedBar.fillAmount = value
    --血条特效缓动
    self._Vec4Temp:Set(1, 1, value - 0.5, 0)
    self.HpBarFireLoop.material:SetVector("_MaskTex_ST", self._Vec4Temp)
    self.HpBarFire2Loop.material:SetVector("_MaskTex_ST", self._Vec4Temp)
    --血条亮点缓动
    self._EulerTemp:Set(0, 0, 360 * (1 - value))
    self.HpBarLightSpot.rotation = self._EulerTemp
end

--function XUiBlackRockChessBattle:GetGridEnergy(index)
--    local grid = self.GridEnergies[index]
--    if not grid then
--        if not self.EnergyParent then
--            self.EnergyParent = self.GridEnergy1.transform.parent
--        end
--        local ui = XUiHelper.Instantiate(self.GridEnergy1, self.EnergyParent)
--        ui.gameObject.name = "GridEnergy" .. index
--        grid = XUiGridEnergy.New(ui)
--        self.GridEnergies[index] = grid
--    end
--    return grid
--end

function XUiBlackRockChessBattle:InitView()
    self:PlayAnimation("Enable")
    --self:RefreshView()
    --self:ChangeState(true, true)
    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessBattle:RefreshView()
    self:RefreshRole()
    self:RefreshBoss()
    self:RefreshSkillView()
    self.TxtStageName.text = self._Control:GetCurNodeCfg().Name
end

function XUiBlackRockChessBattle:RefreshRole()
    if not self._Control:GetChessPartner():IsPassPreparationStage() then
        return
    end
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
    self:RefreshEnergy()
end

function XUiBlackRockChessBattle:InitBoss()
    self.GridBoss.gameObject:SetActiveEx(false)
    self.GridBoss2.gameObject:SetActiveEx(false)
    self.BossGoList = { self.GridBoss, self.GridBoss2 }
    self.PanelBossList = {}
end

function XUiBlackRockChessBattle:RefreshBoss()
    local bossList = self._Control:GetChessEnemy():GetBossList()
    for i, bossInfo in ipairs(bossList) do
        local panelBoss = self.PanelBossList[i]
        if not panelBoss then
            local go =  self.BossGoList[i]
            ---@type XUiPanelBoss
            panelBoss = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBoss").New(go, self)
            self.PanelBossList[i] = panelBoss
        end
        panelBoss:Open()
        panelBoss:Refresh(bossInfo:GetId())
    end

    for i = #bossList + 1, #self.PanelBossList do
        self.PanelBossList[i]:Close()
    end
end

function XUiBlackRockChessBattle:RefreshSkillView()
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local panel = self.PanelSkills[actor:GetRoleId()]
    if panel then
        panel:RefreshView()
        panel:RefreshHead()
    end
end

function XUiBlackRockChessBattle:UpdateNextNodeView()
    
end

function XUiBlackRockChessBattle:OnSwitchCamera()
    local now = CS.UnityEngine.Time.unscaledTime
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

---@param isPrepare boolean 是否备战阶段
function XUiBlackRockChessBattle:ChangeState(isMove, isEnterMove, isPrepare)
    self.PanelConfirm.gameObject:SetActiveEx(not isMove and not isPrepare)
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local roleId = actor:GetRoleId()
    self.IsMoveState = isMove
    if isMove then
        self.PanelSkills[roleId]:ResetSelect()
        self._Control:OnCancelSkill(isEnterMove)
        self._Control:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    else
        local panel = self.PanelSkills[roleId]
        local skillId = panel:GetSelectSkillId()
        if XTool.IsNumberValid(skillId) then
            self._Control:OnSelectSkill(roleId, skillId)
        end
    end
    if isMove or isPrepare then
        self:HideBubbleSkill()
    end
    self:HideEnemyDetail()
end

function XUiBlackRockChessBattle:ShowEnemyDetail(pieceId, isPreview)
    self:HideEnemyDetail()
    self:HideBubbleSkill()
    self:HideBossDetail()
    if not isPreview then return end
    
    local pieceInfo = self._Control:GetChessEnemy():GetPieceInfo(pieceId)
    local isPiece = pieceInfo ~= nil
    local partnerInfo = self._Control:GetChessPartner():GetPieceInfo(pieceId)
    local isPartner = partnerInfo ~= nil
    if isPiece then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, ShowEnemyCueId)
        self.PanelDetails:Open()
        self.PanelDetails.GridHeadUi:SetPieceType(XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY)
        self.PanelDetails:RefreshView(pieceId)
    elseif isPartner then
        -- 备战阶段的tip在商店那
        if self._Control:GetChessPartner():IsPassPreparationStage() then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, ShowEnemyCueId)
            self.PanelDetails:Open()
            self.PanelDetails.GridHeadUi:SetPieceType(XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER)
            self.PanelDetails:RefreshView(pieceId)
        end
    end
end

function XUiBlackRockChessBattle:HideEnemyDetail()
    if not self.PanelDetails:IsNodeShow() then
        return
    end
    self.PanelDetails:Close()
end

function XUiBlackRockChessBattle:ShowBubbleSkill(roleId, id, showType)
    self:HideBossDetail()
    
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

-- 显示Boss详情
function XUiBlackRockChessBattle:ShowPanelBossDetail(bossId, skillId)
    self:HideBubbleSkill()
    self:HideEnemyDetail()
    
    if not self.UiPanelBossDetails then
        self.UiPanelBossDetails = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBossDetails").New(self.PanelBossDetails, self)
    end
    self.UiPanelBossDetails:Open()
    self.UiPanelBossDetails:RefreshView(bossId, skillId)
end

-- 隐藏Boss详情
function XUiBlackRockChessBattle:HideBossDetail()
    if not self.UiPanelBossDetails or not self.UiPanelBossDetails:IsNodeShow() then
        return
    end
    self.UiPanelBossDetails:Close()
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
    local actor = self._Control:GetChessGamer():GetSelectActor()
    local isBlendPiece = actor and actor:IsBlendPieceId()
    if isBlendPiece then
        self:HideBubbleSkill()
    else
        self:ShowEnemyDetail()
    end
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

function XUiBlackRockChessBattle:OnPcPress(inputDeviceType, key, operationType)
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
    if self:IsForbidPcKey() then
        return
    end
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
    if self:IsForbidPcKey() then
        return
    end
    self:OnBtnConfirmClick()
end

function XUiBlackRockChessBattle:OnPcCancel()
    if self:IsForbidPcKey() then
        return
    end
    self:OnBtnCancelClick()
end

function XUiBlackRockChessBattle:DragCamera(xOffset, yOffset)
    local deltaTime = CS.UnityEngine.Time.deltaTime
    CS.XBlackRockChess.XBlackRockChessManager.Instance:DragCamera(xOffset * deltaTime, yOffset * deltaTime)
end
 
function XUiBlackRockChessBattle:OnPcSwitchCamera()
    if self:IsForbidPcKey() then
        return
    end
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
    customKey:SetKey(CS.XInputMapId.BlackRockChess, self:GetPcKeyCode(keyName), CS.XInputManager.XOperationType.BlackRockChess)
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

-- 释放技能，横幅表现
function XUiBlackRockChessBattle:OnPlaySkill(skillType, isDelay, cb)
    if not self.SkillInfos then
        self.SkillInfos = {
            [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.BANSHOU_BIG_SKILL] = {
                ["RImg"] = self.RImgUltimateBanshou,
            },
            [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_BLACK_BIGSKILL] = {
                ["RImg"] = self.RImgUltimateSabiBlack,
                ["DelayRImg"] = self.RImgUltimateSabiBlack,
            },
            [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL] = {
                ["RImg"] = self.RImgUltimateSabi,
                ["DelayRImg"] = self.RImgUltimateSabi,
            },
            [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3] = {
                ["RImg"] = self.RImgUltimateVera,
            },
        }
    end
    
    local skillInfo = self.SkillInfos[skillType]
    if skillInfo then
        local rImg = isDelay and skillInfo.DelayRImg or skillInfo.RImg
                rImg.gameObject:SetActiveEx(true)
        if cb then
            self:ClearBigSkillTipsTimer()
            self.BigSkillTipsTimer = XScheduleManager.ScheduleOnce(function()
                rImg.gameObject:SetActiveEx(false)
                cb()
            end, 2000)
        end
    else
        if cb then cb() end
        XLog.Error("未定义技能横幅路径和动画")    
    end
end

-- 清理大招提示定时器
function XUiBlackRockChessBattle:ClearBigSkillTipsTimer()
    if self.BigSkillTipsTimer then
        XScheduleManager.UnSchedule(self.BigSkillTipsTimer)
        self.BigSkillTipsTimer = nil
    end
end

--region 角色附身棋子

function XUiBlackRockChessBattle:UpdateRolePossess(possessId)
    if XTool.IsNumberValid(possessId) then
        local pieceInfo = self._Control:GetChessPartner():GetPieceInfo(possessId)
        -- 附身主教后 主教会被销毁
        if not pieceInfo then
            self.PanelPossessDetail.gameObject:SetActiveEx(false)
            return
        end
        local cfg = self._Control:GetPartnerPieceById(pieceInfo:GetConfigId())
        self.PanelPossessDetail.gameObject:SetActiveEx(true)
        self.RImgPossessIcon:SetRawImage(cfg.EffectIcon)
        self.TxtPossessDetail.text = cfg.EffectDesc
    else
        self.PanelPossessDetail.gameObject:SetActiveEx(false)
    end
end

--endregion

--region 商店buff

function XUiBlackRockChessBattle:ShowShopBuff()
    --local buffIds = self._Control:GetShopInfo():GetBuffIds() 
    local buffIds = self._Control:GetChessBuffIds() -- 商店干掉了，用来显示当前buff
    if not buffIds then
        return
    end
    XUiHelper.RefreshCustomizedList(self.GridBuff.parent, self.GridBuff, #buffIds, function(i, go)
        local buff = self._Control:GetBuffConfig(buffIds[i])
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.GridBuff:SetRawImage(buff.Icon)
        uiObject.GridBuff.CallBack = function()
            self:ShowBuffTip(buff)
        end
    end)
end

---@param buff XTableBlackRockChessBuff
function XUiBlackRockChessBattle:ShowBuffTip(buff)
    self.PanelBubbleBufflDetail.gameObject:SetActiveEx(true)
    if not self._BuffTip then
        self._BuffTip = {}
        XUiHelper.InitUiClass(self._BuffTip, self.PanelBubbleBufflDetail)
    end
    self._BuffTip.RImgBuff:SetRawImage(buff.Icon)
    self._BuffTip.TxtName.text = buff.Name
    self._BuffTip.TxtDetail.text = buff.Desc
    self.BtnMask.gameObject:SetActiveEx(true)
end

function XUiBlackRockChessBattle:CloseBuffTip()
    self.PanelBubbleBufflDetail.gameObject:SetActiveEx(false)
end

--endregion

function XUiBlackRockChessBattle:OnBtnMaskClick()
    if self.PanelBubbleSkillDetail.gameObject.activeSelf then
        self.PanelBubbleSkillDetail.gameObject:SetActiveEx(false)
    end
    self.BtnMask.gameObject:SetActiveEx(false)
    self:CloseBuffTip()
end

function XUiBlackRockChessBattle:HideAllUiOnPlayWin()
    local safeAreaContentPane = self.Transform:Find("SafeAreaContentPane")
    safeAreaContentPane.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattle:RefreshKillAndRound()
    self.TxtNumber1.text = self._Control:GetChessGamer():GetKillTotal()
    self.TxtNumber2.text = self._Control:GetChessGamer():GetRoundTotal()
end

return XUiBlackRockChessBattle