local XUiGridEnergy = XClass(nil, "XUiGridEnergy")

function XUiGridEnergy:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.ImgOn = self.Transform:FindTransform("ImgOn")
    self.ImgOff = self.Transform:FindTransform("ImgOff")
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


---@class XUiBlackRockChessBattle : XLuaUi
---@field private _Control XBlackRockChessControl
---@field private PanelDetails XUiPanelEnemyDetails
---@field private PanelSkills table<number,XUiPanelBattleSkill>
local XUiBlackRockChessBattle = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessBattle")

local XUiPanelBattleSkill = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBattleSkill")

local PC_KEY = {
    ALPHA1 = 850,
    ALPHA2 = 860,
    ALPHA3 = 870,
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
}

local CSXInputManager = CS.XInputManager

local ShowEnemyCueId = 1051 --显示敌人棋子详情音效

local BGM_DICT = {
    [XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL] = 340,
    [XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD] = 337,
}

function XUiBlackRockChessBattle:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBlackRockChessBattle:OnStart()
    self:InitView()
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.BROADCAST_ROUND, handler(self, self.ShowRoundBroadcast))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.REFRESH_CHECK_MATE, handler(self, self.SetCheckMateState))
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CLOSE_BUBBLE_SKILL, handler(self, self.OnBubbleSkillClose))
    
    if XDataCenter.UiPcManager.IsPc() then
        self:AddPCKeyListener()
    end
end

function XUiBlackRockChessBattle:OnDestroy()
    self.LongClicker:Destroy()
    self.LongClicker = nil
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.BROADCAST_ROUND)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.REFRESH_CHECK_MATE)
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CLOSE_BUBBLE_SKILL)
    if XDataCenter.UiPcManager.IsPc() then
        self:DelPCKeyListener()
    end
end

function XUiBlackRockChessBattle:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH,
        XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_ENEMY,
        XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END
    }
end

function XUiBlackRockChessBattle:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
    }
end

function XUiBlackRockChessBattle:OnNotify(evt, ...)
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
    --CS.XAudioManager.PlayMusic(CS.XAudioManager.UiMainNeedPlayedBgmCueId)
    self.Super.OnRelease(self)
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
        [PC_KEY.TAB] = function() 
            self:OnPcSwitchWeapon()
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

function XUiBlackRockChessBattle:InitUi()
    self.GridWeapons = {}
    self.GridEnergies = {}
    self.WeaponIds = self._Control:GetWeaponIds()
    self.WeaponIndex = 1
    local currentWeaponId = self._Control:GetCurrentWeaponId()
    self.PanelSkills = {}
    for index, weaponId in pairs(self.WeaponIds) do
        if weaponId == currentWeaponId then
            self.WeaponIndex = index
        end
        self.PanelSkills[weaponId] = XUiPanelBattleSkill.New(self["PanelSkill"..index], self, weaponId)
    end
    
    self.PanelEnemyDetails.gameObject:SetActiveEx(false)
    
    self.PanelDetails = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelEnemyDetails").New(self.PanelEnemyDetails, self)
    self.PanelBubbles = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelBubbleSkill").New(self.PanelSkillDetails, self)
    
    local stageId = self._Control:GetStageId()
    self.PanelInfo.gameObject:SetActiveEx(true)
    local affixs = self._Control:GetStageBuffIds(stageId)
    self:RefreshTemplateGrids(self.PanelAffix, affixs, self.PanelInfo, nil, "GridAffix", function(grid, data) 
        grid.TxtTarget.text = self._Control:GetBuffDesc(data)
        grid.RImgAffix:SetRawImage(self._Control:GetBuffIcon(data))
    end)
    
    self.LastSwitchWeapon = 0
    self.LastSwitchCamera = 0
    
    local value1, value2, value3 = self._Control:GetPCInterval()
    self.SwitchWeaponInterval = value1
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
end

function XUiBlackRockChessBattle:InitCb()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    
    self.BtnMainUi.CallBack = function() 
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
    
    local pointer = self.BtnSwitchWeapon.gameObject:GetComponent(typeof(CS.XUiPointer))
    if not pointer then
        pointer = self.BtnSwitchWeapon.gameObject:AddComponent(typeof(CS.XUiPointer))
    end
    self.LongClicker = XUiButtonLongClick.New(pointer, self._Control:GetLongPressTimer(), self, function()
        self:OnBtnSwitchWeaponClick()
    end, function()
        self:OnBtnSwitchWeaponLongClick()
    end)
end

function XUiBlackRockChessBattle:InitView()
    self:PlayAnimation("Enable")
    --self:PlayAnimation("QieHuanSkill" .. self._Control:GetCurrentWeaponId())
    self:RefreshView()
    self:ChangeState(true, true)
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
    self:RefreshWeapon()
    self:RefreshEnergy()
    self.TxtTarget.text = self._Control:GetTargetDescription()
    local active = self.PanelInfo.gameObject.activeInHierarchy
    self.BtnTarget:SetButtonState(active and CS.UiButtonState.Select or CS.UiButtonState.Normal)

    local currentWeaponId = self._Control:GetCurrentWeaponId()
    local panel = self.PanelSkills[currentWeaponId]
    self:PlayPreviewEnergy(panel:GetSkillCost())
end

function XUiBlackRockChessBattle:RefreshWeapon()
    local curWeaponId = self._Control:GetCurrentWeaponId()
    local lastIndex = self.WeaponIndex
    local count = #self.WeaponIds
    for index, id in ipairs(self.WeaponIds) do
        local grid = self.GridWeapons[index]
        if not grid then
            local ui = self["PanelWeapon"..index]
            if not ui then
                break
            end
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridWeapon.New(ui, self._Control)
            self.GridWeapons[index] = grid
        end
        local isCur = id == curWeaponId
        if isCur then
            lastIndex = index
        end
        grid:Refresh(id, curWeaponId)
        grid.Transform:SetSiblingIndex(isCur and count - 1 or 0)
    end
    if lastIndex ~= self.WeaponIndex then
        self.WeaponIndex = lastIndex
        self:PlayAnimationWithMask("QieHuanSkill" .. curWeaponId)
    end
   
    self:RefreshSkill()
end

function XUiBlackRockChessBattle:RefreshSkill()
    local curWeaponId = self._Control:GetCurrentWeaponId()
    for _, weaponId in ipairs(self.WeaponIds) do
        if curWeaponId == weaponId then
            self.PanelSkills[weaponId]:Open()
        else
            self.PanelSkills[weaponId]:Close()
        end
    end
end

function XUiBlackRockChessBattle:RefreshEnergy()
    local energy = self._Control:GetEnergy()
    local maxEnergy = self._Control:GetMaxEnergy()
    for i = 1, maxEnergy do
        local grid = self:GetGridEnergy(i)
        grid:Refresh(i <= energy, false)
    end
    self.TxtEnergy.text = energy
end

function XUiBlackRockChessBattle:PlayPreviewEnergy(costEnergy)
    local energy = self._Control:GetEnergy()
    local maxEnergy = self._Control:GetMaxEnergy()
    local leftEnergy = math.max(0, energy - costEnergy)
    for i = 1, maxEnergy do
        local grid = self:GetGridEnergy(i)
        grid:Refresh(i <= energy, i > leftEnergy and i <= energy)
    end
    self.TxtEnergy.text = leftEnergy
end

function XUiBlackRockChessBattle:GetGridEnergy(index)
    local grid = self.GridEnergies[index]
    local maxEnergy = self._Control:GetMaxEnergy()
    if not grid then
        local ui = self["GridEnergy"..index]
        ui.transform:SetSiblingIndex(maxEnergy - index)
        grid = XUiGridEnergy.New(ui)
        self.GridEnergies[index] = grid
    end
    return grid
end

function XUiBlackRockChessBattle:OnSwitchCamera()
    local now = os.time()
    if now - self.LastSwitchCamera < self.SwitchCameraInterval then
        return
    end
    self.LastSwitchCamera = now
    self._Control:SwitchCamera()
end

function XUiBlackRockChessBattle:OnBtnEndClick()
    --拦截操作
    if self:IsWaiting() then
        return
    end
    --移动中不允许结束回合
    if self._Control:IsGamerMoving() then
        return
    end
    self:OnBtnCancelClick()
    self.RImgExtraRound.gameObject:SetActiveEx(false)
    self._Control:OnForceEndRound()
    local panel = self.PanelSkills[self._Control:GetCurrentWeaponId()]
    if panel then
        panel:RefreshView()
    end
end

function XUiBlackRockChessBattle:OnBtnConfirmClick()
    --拦截操作
    if self:IsWaiting() then
        return
    end
    local curWeaponId = self._Control:GetCurrentWeaponId()
    local skillIds = self._Control:GetWeaponSkillIds(curWeaponId)
    local selectIndex = self.PanelSkills[curWeaponId]:GetSelectIndex()
    if selectIndex <= 0 then
        return
    end
    local skillId = skillIds[selectIndex]
    if not self._Control:CouldUseSkill(skillId) then
        XUiManager.TipMsg(self._Control:GetEnergyNotEnoughText(1))
        return
    end
    
    local skillAnimName = self._Control:GetWeaponAttackAnimName(skillId)
    if not string.IsNilOrEmpty(skillAnimName) then
        self._Control:PlayGamerTimeAnimation(self._Control:GetWeaponAttackTimeLine(skillId))
        self._Control:PlayGamerAnimation(skillAnimName)
        self:OnUseWeaponSkill(skillId)
    else
        self:OnUseWeaponSkill(skillId)
    end
end

function XUiBlackRockChessBattle:OnUseWeaponSkill(skillId)
    local endOfRound = self._Control:UseWeaponSkill(skillId)
    self:ChangeState(true, false)
    local panel = self.PanelSkills[self._Control:GetCurrentWeaponId()]
    panel:RefreshView()
    --使用了 技能无法使用 || 被动技能 || 小刀的普攻打中敌人 || 小刀的技能2打中敌人
    if not endOfRound then
        RunAsyn(function()
            --等待操作完成
            while true do
                if not self:IsWaiting() then
                    break
                end
                asynWaitSecond(0.1)
            end
            if self._Control:GetChessGamer():IsExtraTurn() then
                self._Control:BroadcastRound(true, true)
                self.RImgExtraRound.gameObject:SetActiveEx(true)
            end
            self:ChangeState(true, true)
        end)
        
        return
    end
    self._Control:EndGamerRound()
    self.RImgExtraRound.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessBattle:IsWaiting()
    return self._Control:IsWaiting()
end

function XUiBlackRockChessBattle:OnBtnCancelClick()
    --拦截操作
    if self:IsWaiting() then
        return
    end
    if self.IsMoveState then
        return
    end
    self:ChangeState(true, true)
end

function XUiBlackRockChessBattle:OnBtnHelpClick()
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

function XUiBlackRockChessBattle:OnBtnSwitchWeaponClick()
    --拦截操作
    if self:IsWaiting() then
        return
    end
    if not self.IsMoveState then
        return
    end
    local isMoving = self._Control:IsGamerMoving()
    --移动中不允许切换武器
    if isMoving then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetForbidSwitchWeaponText(1))
        return
    end
    local nextWeaponId = self:GetNextWeaponId()
    --未解锁不允许切换武器
    local unlock = self._Control:IsWeaponUnlock(nextWeaponId)
    if not unlock then
        local weaponName = self._Control:GetWeaponName(nextWeaponId)
        self._Control:GetChessGamer():ShowDialog(string.format(self._Control:GetWeaponLockText(1), weaponName))
        return
    end
    --额外回合不允许切换武器
    if self._Control:GetChessGamer():IsExtraTurn() then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetForbidSwitchWeaponText(2))
        return
    end

    if self._Control:GetChessGamer():IsUsePassiveSkill() then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetForbidSwitchWeaponText(3))
        return
    end
    --进入移动状态
    self:ChangeState(true, true)
    --切换武器
    self._Control:SwitchWeapon()
    --刷新界面显示
    self:RefreshWeapon()
end

function XUiBlackRockChessBattle:OnBtnSwitchWeaponLongClick()
    local currentWeaponId = self._Control:GetCurrentWeaponId()
    if currentWeaponId == self.BubbleWeaponId then
        return
    end
    if not XTool.IsNumberValid(currentWeaponId) then
        return
    end
    
    self.BubbleWeaponId = currentWeaponId
    XLuaUiManager.Open("UiBlackRockChessBubbleSkill", currentWeaponId, self.BtnSwitchWeapon, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON)

end

function XUiBlackRockChessBattle:OnBtnSettingClick()
    --系统设置
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XLuaUiManager.Open("UiSet", false, 4)
end

function XUiBlackRockChessBattle:OnBtnBackClick()
    --拦截操作
    if self:IsWaiting() then
        return
    end
    XLuaUiManager.SafeClose("UiBlackRockChessBubbleSkill")
    self:Close()
end

function XUiBlackRockChessBattle:GetNextWeaponId()
    local weaponIndex = self.WeaponIndex + 1
    if weaponIndex > #self.WeaponIds then
        weaponIndex = 1
    end
    return self.WeaponIds[weaponIndex]
end

function XUiBlackRockChessBattle:ChangeState(isMove, isEnterMove)
    self.PanelArm.gameObject:SetActiveEx(isMove)
    self.PanelConfirm.gameObject:SetActiveEx(not isMove)
    local currentWeaponId = self._Control:GetCurrentWeaponId()
    self.IsMoveState = isMove
    if isMove then
        self.PanelSkills[currentWeaponId]:ResetSelect()
        self._Control:OnCancelSkill(isEnterMove)
        self:HideBubbleSkill()
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    else
        local panel = self.PanelSkills[currentWeaponId]
        self._Control:OnSelectSkill(panel:GetSelectIndex())
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

function XUiBlackRockChessBattle:ShowBubbleSkill(id, showType)
    if not self.PanelBubbles:IsNodeShow() then
        self.PanelBubbles:Open()
    end
    self.PanelBubbles:RefreshView(id, showType)
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
    if XLuaUiManager.IsMaskShow(XEnumConst.BLACK_ROCK_CHESS.MASK_KEY) then
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
    local curWeaponId = self._Control:GetCurrentWeaponId()
    if not XTool.IsNumberValid(curWeaponId) then
        return
    end
    local panelSkill = self.PanelSkills[curWeaponId]
    if not panelSkill then
        return
    end 
    panelSkill:OnBtnClick(index)
end

function XUiBlackRockChessBattle:OnPcSwitchWeapon()
    local now = os.time()
    if now - self.LastSwitchWeapon < self.SwitchWeaponInterval then
        return
    end
    self.LastSwitchWeapon = now
    self:OnBtnSwitchWeaponClick()
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