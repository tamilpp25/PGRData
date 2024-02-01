---@class XBlackRockChessControl : XControl
---@field private _Model XBlackRockChessModel
---@field private _ChessControl XBlackRockChessInfo
---@field private _ConditionControl XChessConditionControl
---@field private _BattleScene XChessScene
---@field private _GameManager XBlackRockChess.XBlackRockChessManager 玩法管理器
local XBlackRockChessControl = XClass(XControl, "XBlackRockChessControl")

local XChessScene = require("XModule/XBlackRockChess/XGameObject/XChessScene")

local XBlackRockChessInfo = require("XModule/XBlackRockChess/XEntity/XBlackRockChessInfo")
local XChessConditionControl = require("XModule/XBlackRockChess/XEntity/XChessConditionControl")

function XBlackRockChessControl:OnInit()
    --初始化内部变量
    self._BattleScene = XChessScene.New()

    self._GameManager = CS.XBlackRockChess.XBlackRockChessManager
    
    self._FuncDict = {}

    self:ResetWait()
    
    --难度缓存
    self._DifficultCache = {
        [self:GetFirstChapterId()] = true,
        [self:GetSecondChapterId()] = true,
    }
    self._IsGamerRound = false
    self._ConditionControl = self:AddSubControl(XChessConditionControl)
    
    local url1, url2, hLine, hPiece, pointCount = self:GetLineRenderProperty()
    CS.XBlackRockChess.XBlackRockChessUtil.InitLine(hPiece, hLine, pointCount, url1, url2)
    
    self._DebugInfo = ""
end

function XBlackRockChessControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE_UI_CLOSE, self.ExitStage, self)
end

function XBlackRockChessControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE_UI_CLOSE, self.ExitStage, self)
end

function XBlackRockChessControl:RegisterFunc(funId, func)
    self._FuncDict[funId] = func
end

function XBlackRockChessControl:UnRegisterFunc(funId)
    self._FuncDict[funId] = nil
end

function XBlackRockChessControl:DispatchEvent(funId, ...)
    if not self._FuncDict then
        return
    end
    local func = self._FuncDict[funId]
    if not func then
        return
    end
    func(...)
end

function XBlackRockChessControl:OnRelease()
    if self._BattleScene then
        self._BattleScene:Release()
    end

    for _, func in pairs(self._FuncDict) do
        func = nil
    end
    self._BattleScene = nil
    self._FuncDict = nil
    self._GameManager = nil
    self._DifficultCache = nil
    self._DebugInfo = ""
end

function XBlackRockChessControl:DebugRoundSync()
    local info = string.format("第%s回合:\n", self:GetChessRound() - 1)
    if string.IsNilOrEmpty(self._DebugInfo) then
        self._DebugInfo = "\n"
    end
    self._DebugInfo = self._DebugInfo .. info
end

function XBlackRockChessControl:DebugActorOp(id, actionType, params)
    local info
    if actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE then
        info = string.format("\t角色【%s】移动到坐标（%s, %s）\n", id, params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK then
        info = string.format("\t角色【%s】释放技能[%s], 技能中心点（%s, %s）\n", id, params[2], params[3], params[4])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND then
        info = string.format("\t跳过回合\n")
    end
    self._DebugInfo = self._DebugInfo .. info
end

function XBlackRockChessControl:PrintDebugInfo()
    XLog.Error(self._DebugInfo)
    self._DebugInfo = ""
end

function XBlackRockChessControl:EnterFight(stageId)
    self:ResetWait()
    local scenePath = self._Model:GetStageSceneUrl(stageId)
    --初始化手动触发引导
    if not self._ManualTriggering then
        self._ManualTriggering = {}
        local template = self._Model:GetClientConfig("ManualTriggeringGuide")
        for _, value in ipairs(template.Values) do
            if not string.IsNilOrEmpty(value) then
                table.insert(self._ManualTriggering, tonumber(value))
            end
        end
    end
    XLuaUiManager.OpenWithCallback("UiBlackRockChessComponent", function()
        --展示场景
        self._BattleScene:Display(scenePath)
        --初始化游戏
        self:InitGame(stageId)
    end)

    if XLuaUiManager.IsUiLoad("UiBlackRockChessChapterDetail") then
        XLuaUiManager.Remove("UiBlackRockChessChapterDetail")
    end
    
    XLuaUiManager.Close("UiBiancaTheatreBlack")
    XLuaUiManager.Open("UiBlackRockChessBattle")
end

function XBlackRockChessControl:ExitFight()
    XLuaUiManager.SafeClose("UiBlackRockChessComponent")
    self:ResetFight()
    self._BattleScene:Dispose()
end

function XBlackRockChessControl:ResetFight()
    self._DebugInfo = ""
    self._ChessControl:ExitFight()
    self._GameManager.Instance:EndOfGame()
    if self._CvAudio then
        self._CvAudio:Stop()
        self._CvAudio = nil
    end
    self:RemoveSubControl(self._ChessControl)
    self._ChessControl = nil
end

--region   ------------------活动数据 start-------------------

function XBlackRockChessControl:GetActivityStopTime()
    return self._Model:GetActivityStopTime()
end

function XBlackRockChessControl:OnActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipText("CommonActivityEnd")
end

function XBlackRockChessControl:GetMaxEnergy()
    return self._Model:GetMaxEnergy()
end

function XBlackRockChessControl:IsNormalCache(chapterId)
    if self._DifficultCache[chapterId] == nil then
        return true
    end
    return self._DifficultCache[chapterId]
end

function XBlackRockChessControl:UpdateDifficultCache(chapterId, value)
    self._DifficultCache[chapterId] = value
end

function XBlackRockChessControl:GetFirstChapterId()
    return self._Model:GetFirstChapterId()
end

function XBlackRockChessControl:GetSecondChapterId()
    return self._Model:GetSecondChapterId()
end

--endregion------------------活动数据 finish------------------

--region   ------------------对局数据 start-------------------

function XBlackRockChessControl:GetActorPoint(roleId)
    local actor = self:GetChessGamer():GetRole(roleId)
    if not actor then
        return
    end
    return actor:GetMovedPoint()
end

function XBlackRockChessControl:GetPieceInitCd(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.InitMoveCd or 0
end

---@return XBlackRockChessGamer
function XBlackRockChessControl:GetChessGamer()
    return self._ChessControl:GetGamerInfo()
end

---@return XBlackRockChessEnemy
function XBlackRockChessControl:GetChessEnemy()
    return self._ChessControl:GetEnemyInfo()
end

function XBlackRockChessControl:IsGamerRound()
    return self._IsGamerRound
end

function XBlackRockChessControl:SetGameRound(value)
    self._IsGamerRound = value
end

--玩家所有角色操作完成
function XBlackRockChessControl:IsAllActorOperaEnd()
    local gamer = self:GetChessGamer()
    return gamer and gamer:IsAllActorOperaEnd() or false
end

function XBlackRockChessControl:GetCurrentWeaponId()
    local actor = self:GetChessGamer():GetSelectActor()
    if not actor then
        return 0
    end
    return actor:GetWeaponId()
end

function XBlackRockChessControl:GetEnergy()
    return self:GetChessGamer():GetEnergy()
end

function XBlackRockChessControl:OnSelectSkill(roleId, skillId)
    local actor = self:GetChessGamer():GetRole(roleId)
    if not actor then
        return
    end
    actor:OnSelectSkill(skillId)
end

function XBlackRockChessControl:OnCancelSkill(roleId, isEnterMove)
    local actor = self:GetChessGamer():GetRole(roleId)
    if not actor then
        return
    end
    actor:OnCancelSkill(isEnterMove)
end

function XBlackRockChessControl:IsGamerMoving()
    return self:GetChessGamer():IsMoving()
end

function XBlackRockChessControl:ChangeRound(count)
    self._ChessControl:ChangeRound(count)
end

function XBlackRockChessControl:GetChessRound()
    return self._ChessControl:GetRound()
end

function XBlackRockChessControl:GetStageId()
    if not self._ChessControl then
        return
    end
    return self._ChessControl:GetStageId()
end

function XBlackRockChessControl:CouldUseSkill(roleId, skillId)
    if not self:IsSkillUnlock(skillId) then
        return false
    end
    local actor = self:GetChessGamer():GetRole(roleId)
    if not actor then
        return false
    end
    return actor:TryGetSkill(skillId):CouldUseSkill()
end

function XBlackRockChessControl:ConsumeEnergy(roleId, skillId)
    local cost = self:GetWeaponSkillCost(roleId, skillId)
    self:GetChessGamer():ConsumeEnergy(cost)
end

function XBlackRockChessControl:OnForceEndRound()
    self:GetChessGamer():DoForceEndOfTurn()
    self:EndGamerRound()
end

function XBlackRockChessControl:EndGamerRound()
    RunAsyn(function()
        --玩家回合结束
        local gamer = self:GetChessGamer()
        gamer:OnRoundEnd()
        self:UpdateCondition()
        --等待
        self:SyncWait()

        --检测关卡是否达成
        if self:IsFightingStageEnd() then
            self:RequestSyncRound()
            return
        end

        local enemy = self:GetChessEnemy()
        --到敌人回合
        enemy:OnRoundBegin()
    end)
end

--- 同步等待函数，需要放在协程中执行
--------------------------
function XBlackRockChessControl:SyncWait()
    while true do
        if not self:IsWaiting() then
            break
        end
        
        asynWaitSecond(0.2)
    end
end

function XBlackRockChessControl:IsWaiting()
    return self._WaitingCount ~= 0 or self:GetChessGamer():IsMoving() 
            or CS.XBlackRockChess.XBlackRockChessManager.IsLimitClick
end

--能否操作
function XBlackRockChessControl:IsOperate()
    if self:IsWaiting() then
        return false
    end

    if CS.XBlackRockChess.XBlackRockChessManager.IsLimitClick then
        return false
    end

    if self:IsWaitingCvEnd() then
        return false
    end

    if not self:IsGamerRound() then
        return false
    end

    if self:GetChessGamer():CheckIsSkillRunning() then
        return false
    end
    
    return true
end

function XBlackRockChessControl:IsEnterMove()
    if CS.XBlackRockChess.XBlackRockChessManager.Instance.IsEnterMove then
        return true
    end
    local chessBoard = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard
    if not chessBoard then
        return false
    end
    local movePoints = chessBoard.MovablePoint
    if not movePoints then
        return false
    end
    return movePoints.Count > 0
end

function XBlackRockChessControl:IsEnterSkill()
    return CS.XBlackRockChess.XBlackRockChessManager.Instance.IsEnterAttack
end

function XBlackRockChessControl:AddWaitCount()
    self._WaitingCount = self._WaitingCount + 1
end

function XBlackRockChessControl:SubWaitCount()
    self._WaitingCount = self._WaitingCount - 1
end

function XBlackRockChessControl:ResetWait()
    self._WaitingCount = 0
end

function XBlackRockChessControl:IsWaitingCvEnd()
    return self._IsWaitingCvEnd
end

function XBlackRockChessControl:SetWaitingCv(value)
    self._IsWaitingCvEnd = value
end

--- 同步等待函数，需要放在协程中执行
--------------------------
function XBlackRockChessControl:SyncWaitCvEnd()
    while true do
        if not self:IsWaitingCvEnd() then
            break
        end

        asynWaitSecond(0.2)
    end
end

--- 根据位置获取棋盘上的棋子
---@param vec2Int UnityEngine.Vector2Int
---@return XBlackRockChessPiece | XChessActor
--------------------------
function XBlackRockChessControl:PieceAtCoord(vec2Int)
    ---@type XBlackRockChess.XPiece | XBlackRockChess.XWeapon
    local piece = self._GameManager.Instance:PieceAtCoord(vec2Int)
    if not piece then
        return
    end
    --当前位置为角色
    if piece.ChessRole then
        return self:GetChessGamer():GetRole(piece.ChessRole.RoleId)
    else
        if piece.Id and piece.Id <= 0 then
            return self:GetChessEnemy():GetPieceInfoByPoint(vec2Int)
        end
        return self:GetChessEnemy():GetPieceInfo(piece.Id)
    end
end

function XBlackRockChessControl:UpdateReinforce()
    if not self._ChessControl then
        return
    end
    self._ChessControl:UpdateReinforce()
end

function XBlackRockChessControl:CheckReinforceTrigger(reinforceId)
    if not self._ChessControl then
        return true
    end
    return self._ChessControl:CheckReinforceTrigger(reinforceId)
end

function XBlackRockChessControl:BroadcastRound(isPlayer, isExtraRound) 
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.BROADCAST_ROUND, self:GetRoundBroadcastText(isPlayer, isExtraRound))
end

function XBlackRockChessControl:BroadcastReviveCount(count)
    local stageId = self:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    local template = self._Model:GetStageConfig(stageId)
    local mini = template.MinGuaranteeReviveCount
    if mini ~= count then
        return
    end
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.BROADCAST_ROUND, self:GetReviveBroadcastText())
end

function XBlackRockChessControl:ShowBubbleText(imp, text)
    if not imp then
        return
    end
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_DIALOG_BUBBLE, imp.transform, text)
end

function XBlackRockChessControl:PlayGrowls(belong, trigger, belongArg, triggerArg)
    local template = self._Model:GetChessGrowlsConfig(belong, trigger, belongArg, triggerArg)
    if not template then
        return
    end
    local cvIds = template.CvIds
    local cvTexts = template.Text
    local duration = template.Duration or 0
    local index

    if not XTool.IsTableEmpty(cvIds) then
        index = math.random(1, #cvIds)
    end

    local cvId, cvText = nil, nil
    if index then
        cvId = cvIds[index]
        cvText = cvTexts[index] or XMVCA.XFavorability:GetCvContentByIdAndType(cvId, CS.XAudioManager.CvType)
    else
        index = math.random(1, #cvTexts)
        cvText = cvTexts[index]
    end

    if belong == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER then
        local hideFunc = function()
            self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_GROWLS, belongArg, triggerArg)
        end
        if cvId then
            if self._CvAudio then
                self._CvAudio:Stop()
            end
            if duration <= 0 then
                self._CvAudio = CS.XAudioManager.PlayCvWithCvType(cvId, CS.XAudioManager.CvType, hideFunc)
            else
                self._CvAudio = CS.XAudioManager.PlayCvWithCvType(cvId, CS.XAudioManager.CvType)
            end
            self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_GROWLS, belongArg, cvText, triggerArg, duration)
        else
            self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_GROWLS, belongArg, cvText, triggerArg, duration)
        end
    elseif belong == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE then
        if cvId then
            self._CvAudio = CS.XAudioManager.PlayCvWithCvType(cvId, CS.XAudioManager.CvType)
        end
        local infoList = self:GetChessEnemy():GetPieceListByConfigId(belongArg)
        for _, info in ipairs(infoList) do
            info:ShowBubbleText(cvText)
        end
    end
end

function XBlackRockChessControl:GetChessGrowlsTriggerArgs(belong, trigger, belongArg)
    return self._Model:GetChessGrowlsTriggerArgs(belong, trigger, belongArg)
end

function XBlackRockChessControl:GetIncId()
    if not self._ChessControl then
        return 0
    end
    return self._ChessControl:GetIncId()
end

function XBlackRockChessControl:AddKillCount(pieceType)
    --增加击杀人数
    self:GetChessGamer():AddKillCount(pieceType)
    local template = self._Model:_GetActivityConfig()
    local count = template.KillEnergyAdd or 0
    --回复能量
    self:GetChessGamer():ConsumeEnergy(count * -1)
    --更新条件检测
    self:UpdateCondition()
end

function XBlackRockChessControl:UpdateEnergy()
    if not self._Model then
        return
    end
    self._Model:UpdateEnergy(self:GetChessGamer():GetEnergy())
end

function XBlackRockChessControl:UpdateIsExtraRound(value)
    if not self._Model then
        return
    end
    self._Model:UpdateExtraRound(value)
end

function XBlackRockChessControl:GetMemberInitPos(memberId)
    local stageId = self:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return 0, 0
    end
    local template = self._Model:GetStageConfig(stageId)
    local layoutId = template.LayoutId

    return self._Model:GetMemberInitPos(layoutId, memberId)
end

function XBlackRockChessControl:CreateAction(objId, actionType, objType, ...)
    return {
        ObjId = objId,
        ActionType = actionType,
        ObjType = objType,
        Params = { ... }
    }
end

--- 检查是否能悔棋
---@return
--------------------------
function XBlackRockChessControl:CheckRetract()
    local stageId = self:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    local maxRetractCount = self._Model:GetStageRetractCount(stageId)
    return self._ChessControl:GetRetractCount() < maxRetractCount
end

--- 打开预览气泡
--------------------------
function XBlackRockChessControl:OpenBubblePreview(id, dimObj, showType, alignment, hideCloseBtn)
    local uiName = "UiBlackRockChessBubbleSkill"
    XLuaUiManager.SafeClose(uiName)
    
    XLuaUiManager.Open(uiName, id, dimObj, showType, alignment, hideCloseBtn)
end

--endregion------------------对局数据 finish------------------

--region   ------------------武器 start-------------------

function XBlackRockChessControl:GetWeaponType(weaponId)
    return self._Model:GetWeaponType(weaponId)
end
function XBlackRockChessControl:GetWeaponMoveRange(weaponId)
    return self._Model:GetWeaponMoveRange(weaponId)
end


function XBlackRockChessControl:GetWeaponIcon(weaponId)
    return self._Model:GetWeaponIcon(weaponId)
end

function XBlackRockChessControl:IsWeaponUnlock(weaponId)
    return self._Model:IsWeaponUnlock(weaponId)
end

function XBlackRockChessControl:IsSkillUnlock(skillId)
    return self._Model:IsSkillUnlock(skillId)
end

function XBlackRockChessControl:GetWeaponName(weaponId)
    return self._Model:GetWeaponName(weaponId)
end

function XBlackRockChessControl:GetWeaponDesc(weaponId)
    return self._Model:GetWeaponDesc(weaponId)
end

function XBlackRockChessControl:GetWeaponUnlockDesc(weaponId)
    return self._Model:GetWeaponUnlockDesc(weaponId)
end

function XBlackRockChessControl:GetWeaponMapIcon(weaponId)
    return self._Model:GetWeaponMapIcon(weaponId)
end

function XBlackRockChessControl:GetWeaponSkillIds(weaponId)
    return self._Model:GetWeaponSkillIds(weaponId)
end

function XBlackRockChessControl:GetWeaponSkillIcon(skillId)
    return self._Model:GetWeaponSkillIcon(skillId)
end

function XBlackRockChessControl:GetWeaponSkillCost(roleId, skillId, isDefault)
    if not XMVCA.XBlackRockChess:IsInFight() or isDefault then
        return self._Model:GetWeaponSkillCost(skillId)
    end
    return self:GetChessGamer():GetRole(roleId):TryGetSkill(skillId):GetCost()
end

function XBlackRockChessControl:GetWeaponSkillCd(roleId, skillId, isDefault)
    if not XMVCA.XBlackRockChess:IsInFight() or isDefault then
        return self._Model:GetWeaponSkillCd(skillId)
    end
    return self:GetChessGamer():GetRole(roleId):TryGetSkill(skillId):GetCd()
end

function XBlackRockChessControl:GetWeaponSkillInitCd(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.InitCd or 0
end

function XBlackRockChessControl:GetWeaponSkillRange(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Range or 0
end

function XBlackRockChessControl:GetWeaponSkillType(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Type or 0
end

function XBlackRockChessControl:GetWeaponSkillName(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Name or ""
end

function XBlackRockChessControl:GetWeaponSkillDesc(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Desc or ""
end

function XBlackRockChessControl:GetWeaponSkillMapIcon(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.MapIcon or ""
end

function XBlackRockChessControl:GetWeaponSkillUnlockDesc(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.UnlockDesc or ""
end

function XBlackRockChessControl:IsPassive(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.IsPassive == 1 or false
end

function XBlackRockChessControl:GetWeaponSkillParams(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if not template then
        return {}
    end
    return template.Params
end

function XBlackRockChessControl:IsDizzy(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.IsDizzy == 1 or false
end

--技能额外回合
function XBlackRockChessControl:GetWeaponSkillExtraTurn(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if template.Type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK 
            or template.Type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL2
            or template.Type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_ATTACK
            or template.Type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_SKILL1
            or template.Type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_SKILL2
    then
        return template.Params[2]
    end
    
    return 0
end

--技能协助范围
function XBlackRockChessControl:GetWeaponSkillAssistRange(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_ATTACK 
            and template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL2 then
        return 0
    end
    return template.Params[3]
end

--技能召唤的角色Id
function XBlackRockChessControl:GetWeaponSkillAssistRoleId(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3 then
        return 0
    end
    return template.Params[2]
end

function XBlackRockChessControl:GetWeaponSkillIsPenetrate(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL1 then
        return false
    end
    return template and template.Params[3] == 1 or false
end

function XBlackRockChessControl:GetWeaponHitEffectIds(skillId, isAssist)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if isAssist then
        return template and template.AssistHitEffectId or {}
    end
    return template and template.HitEffectId or {}
end

--endregion------------------武器 finish------------------

--region   ------------------棋子 start-------------------
function XBlackRockChessControl:GetPieceHeadIcon(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.HeadIcon or ""
end

function XBlackRockChessControl:GetPieceMaxLife(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.MaxLife or 1
end

function XBlackRockChessControl:GetPromotionPieceId(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.PromotionPiece or 0
end

function XBlackRockChessControl:GetPiecePrefab(pieceConfigId)
    return self._Model:GetPiecePrefab(pieceConfigId)
end

function XBlackRockChessControl:GetReinforceType(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.Type or XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.KING_AROUND
end

function XBlackRockChessControl:GetReinforceLocations(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.Locations or {}
end

function XBlackRockChessControl:GetReinforceRange(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.Range or 0
end

function XBlackRockChessControl:GetReinforcePieceIds(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.PieceIds or {}
end

function XBlackRockChessControl:GetReinforceCondition(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.Condition
end

function XBlackRockChessControl:GetReinforcePreviewCd(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.PreviewCd or -1
end

function XBlackRockChessControl:GetReinforceTriggerCd(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.TriggerCd or -1
end

function XBlackRockChessControl:GetPieceBuffIds(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.BuffIds or {}
end

function XBlackRockChessControl:GetPieceDesc(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.Desc or "???"
end

function XBlackRockChessControl:GetPieceType(pieceConfigId)
    return self._Model:GetPieceType(pieceConfigId)
end

--endregion------------------棋子 finish------------------

--region   ------------------角色 start-------------------

function XBlackRockChessControl:GetSelectActor()
    return self:GetChessGamer():GetSelectActor()
end

function XBlackRockChessControl:GetRoleModelUrl(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.ModelUrl or ""
end

function XBlackRockChessControl:GetRoleName(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.Name or ""
end

function XBlackRockChessControl:GetRoleControllerUrl(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.ControllerUrl or ""
end

function XBlackRockChessControl:GetRoleIds(roleType)
    local dict = self._Model:GetCharacterTypeDict()
    return dict and dict[roleType] or {}
end

function XBlackRockChessControl:GetMasterRoleId()
    local list = self:GetRoleIds(XEnumConst.BLACK_ROCK_CHESS.CHARACTER_TYPE.MASTER)
    return list[1]
end

function XBlackRockChessControl:GetAssistantRoleId()
    local list = self:GetRoleIds(XEnumConst.BLACK_ROCK_CHESS.CHARACTER_TYPE.ASSISTANT)
    return list[1]
end

function XBlackRockChessControl:GetRoleSkillIds(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.SkillIds or {}
end

function XBlackRockChessControl:GetRoleSkillParam(skillId)
    local template = self._Model:GetCharacterSkillConfig(skillId)
    
    return template and template.Params or {}
end

function XBlackRockChessControl:GetRoleSkillType(skillId)
    local template = self._Model:GetCharacterSkillConfig(skillId)

    return template and template.Type or 0
end

function XBlackRockChessControl:GetRoleSkillIcon(skillId)
    local template = self._Model:GetCharacterSkillConfig(skillId)
    return template and template.Icon or ""
end

function XBlackRockChessControl:GetRoleCircleIcon(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.CircleIcon or ""
end

function XBlackRockChessControl:GetRoleRectIcon(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.RectIcon or ""
end

function XBlackRockChessControl:GetRoleWeaponId(roleId, index)
    index = index or 1
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.WeaponIds[index] or 0
end

--endregion------------------角色 finish------------------

--region   ------------------关卡 start-------------------

-- 关卡复活次数
function XBlackRockChessControl:GetStageReviveCount(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.ReviveCount or 0
end

-- 当前关卡剩余复活次数，只能进入战斗才能获取
function XBlackRockChessControl:GetGamerLeftReviveCount()
    local stageId = self._ChessControl:GetStageId()
    local total = self:GetStageReviveCount(stageId)
    local useCount = self:GetChessGamer():GetReviveCount()
    
    return math.max(0, total - useCount)
end

function XBlackRockChessControl:GetMaxBloodGridCount()
    local template = self._Model:GetClientConfig("MaxBloodGridCount")
    return template and tonumber(template.Values[1]) or 0
end

function XBlackRockChessControl:GetStageName(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.Name or ""
end

function XBlackRockChessControl:GetMainPanelRewardShowId()
    local template = self._Model:GetClientConfig("MainRewardShowId")
    return template and tonumber(template.Values[1]) or 0
end

function XBlackRockChessControl:GetStageExitStoryId(stageId)
    return self._Model:GetStageExitStoryId(stageId)
end

function XBlackRockChessControl:GetStageExitCommunicationId(stageId)
    return self._Model:GetStageExitCommunicationId(stageId)
end

function XBlackRockChessControl:GetStageFirstPassWeaponId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.FirstPassWeaponId or 0
end

function XBlackRockChessControl:GetStageFirstPassSkillId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.FirstPassSkillId or 0
end

function XBlackRockChessControl:GetStageFirstPassBuffIds(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.FirstPassBuffIds or {}
end

function XBlackRockChessControl:GetActiveConditionId()
    return self._ChessControl and self._ChessControl:GetActiveConditionId() or 0
end

function XBlackRockChessControl:GetTargetDescription()
    return self._ConditionControl and self._ConditionControl:GetStageTargetDesc() or ""
end


--- 正在战斗的关卡是否结束
---@return boolean
--------------------------
function XBlackRockChessControl:IsFightingStageEnd()
    --场上棋子是否全部阵亡
    if self:GetChessEnemy():IsAllPieceDead() then
        return true
    end
    return self._ChessControl and self._ChessControl:IsFightingStageEnd() or false
end

function XBlackRockChessControl:CheckCondition(conditionId, ...)
    return self._ConditionControl:CheckCondition(conditionId, ...)
end

function XBlackRockChessControl:UpdateCondition()
    if self._ChessControl then
        self._ChessControl:UpdateCondition()
    end
end

function XBlackRockChessControl:GetStageChapterId(stageId)
    local chapter, _ = self._Model:GetStageChapterAndDifficulty(stageId)
    return chapter
end

function XBlackRockChessControl:GetStageChapterIdAndDifficulty(stageId)
    return self._Model:GetStageChapterAndDifficulty(stageId)
end

function XBlackRockChessControl:GetStageDifficulty(stageId)
    return self._Model:GetStageDifficulty(stageId)
end

function XBlackRockChessControl:GetStageTargetDesc(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.TargetDesc
end

function XBlackRockChessControl:GetStageStarRewardTemplateId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.StarRewardTemplateId or 0
end

function XBlackRockChessControl:GetStageDisplayBuffIds(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.DisplayBuffIds or {}
end

function XBlackRockChessControl:GetStageBuffIds(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.BuffIds
end

function XBlackRockChessControl:GetStageNormalRewards(stageId)
    local rewards = {}
    local template = self._Model:GetStageConfig(stageId)
    if template then
        if XTool.IsNumberValid(template.FirstPassWeaponId) then
            table.insert(rewards, { reward = template.FirstPassWeaponId, isWeapon = true })
        end
        if XTool.IsNumberValid(template.FirstPassSkillId) then
            table.insert(rewards, { reward = template.FirstPassSkillId, isPassSkill = true })
        end
        if not XTool.IsTableEmpty(template.FirstPassBuffIds) then
            for _, buffId in pairs(template.FirstPassBuffIds) do
                table.insert(rewards, { reward = buffId, isBuff = true })
            end
        end
        if XTool.IsNumberValid(template.FirstPassRewardId) then
            local rewardDatas = XRewardManager.GetRewardList(template.FirstPassRewardId)
            for _, rewardData in pairs(rewardDatas) do
                table.insert(rewards, { reward = rewardData, isItem = true })
            end
        end
    end
    return rewards
end

function XBlackRockChessControl:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

function XBlackRockChessControl:GetStageStar(stageId)
    return self._Model:GetStageStar(stageId)
end

function XBlackRockChessControl:GetStageMaxStar(stageId)
    return self._Model:GetStageMaxStar(stageId)
end

function XBlackRockChessControl:GetStarRewardByTemplateId(templateId)
    return self._Model:GetStarRewardByTemplateId(templateId)
end

function XBlackRockChessControl:GetConditionDesc(conditionId)
    local template = self._Model:GetConditionConfig(conditionId)
    return template and template.Desc or ""
end

function XBlackRockChessControl:GetChapterPrefabPath(chapterId, difficulty)
    local keyValue = chapterId % 2 == 0 and 2 or 1
    local key = string.format("Chapter%sPrefab", keyValue)
    return self._Model:GetClientConfigWithIndex(key, difficulty)
end

function XBlackRockChessControl:GetChapterStageIds(chapterId, difficulty)
    local ids = self._Model:GetChapterStageIds(chapterId, difficulty)
    table.sort(ids) -- 从小到大排序
    return ids
end

function XBlackRockChessControl:GetChapterName(chapterId, difficulty)
    return self._Model:GetChapterName(chapterId, difficulty)
end

---@return boolean,string
function XBlackRockChessControl:IsHardOpen(chapterId)
    return self._Model:CheckChapterCondition(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
end

---@return boolean,string
function XBlackRockChessControl:IsNormalOpen(chapterId)
    return self._Model:CheckChapterCondition(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
end

---获取最近的未过关的关卡
function XBlackRockChessControl:GetNextStageId(chapterId, difficulty)
    local stageIds = self:GetChapterStageIds(chapterId, difficulty)
    for _, stageId in pairs(stageIds) do
        if not self:IsStagePass(stageId) then
            return stageId
        end
    end
    return nil
end

function XBlackRockChessControl:ContinueStage(cb)
    local stageId = self:GetAgency():GetFightingStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    self:RequestEnterStage(stageId, cb)
end

function XBlackRockChessControl:GiveUpStage(cb)
    self:RequestFinishStage(cb)
end

function XBlackRockChessControl:GetStageHelpKey(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.HelpKey or ""
end

function XBlackRockChessControl:GetChapterProgress(chapterId)
    -- （通关的简单关卡+困难关卡获取的星级）/（简单关卡+困难星级）
    local normal = 0
    local hard = 0
    local normalStageIds = self:GetChapterStageIds(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    for _, stageId in pairs(normalStageIds) do
        if self:IsStagePass(stageId) then
            normal = normal + 1
        end
    end
    local hardStageIds = self:GetChapterStageIds(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD)
    for _, stageId in pairs(hardStageIds) do
        hard = hard + self:GetStageStar(stageId)
    end
    return (normal + hard) / (#normalStageIds + #hardStageIds * 3)
end

function XBlackRockChessControl:GetStageIcon(stageId)
        local template = self._Model:GetStageConfig(stageId)
    return template and template.StageIcon or ""
end

function XBlackRockChessControl:ContainStageBuff(searchType)
    local stageId = self:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    local buffIds = self:GetStageBuffIds(stageId)
    if XTool.IsTableEmpty(buffIds) then
        return false
    end

    for _, buffId in ipairs(buffIds) do
        local buffType = self:GetBuffType(buffId)
        if buffType == searchType then
            return true
        end
    end
    return false
end

--endregion------------------关卡 finish------------------

--- 绑定视图
---@param uiTrans UnityEngine.Transform
---@param objTrans UnityEngine.Transform
---@param offset UnityEngine.Vector3
---@param pivot UnityEngine.Vector2
--------------------------
function XBlackRockChessControl:SetViewPosToTransformLocalPosition(uiTrans, objTrans, offset, pivot)
    if not self._GameManager then
        return
    end
    self._GameManager.Instance:SetViewPosToTransformLocalPosition(uiTrans, objTrans, offset, pivot)
end

--region   ------------------游戏设置 start-------------------

function XBlackRockChessControl:InitGame(stageId)
    local board = self._BattleScene:TryFind("GroupBase/Main")
    if not board then
        XLog.Error("游戏初始化失败，未找到棋盘游戏物体")
        return
    end
    local xBoard = board:GetComponent(typeof(CS.XBlackRockChess.XChessBoard))
    if not xBoard then
        XLog.Error("游戏初始化失败，未找到棋盘脚本")
        return
    end
    self._GameManager.Instance:Clear()
    local interval, jumpHigh = self:GetPieceMoveConfig()
    local chessboardType = self._Model:GetStageChessBoardType(stageId)
    self._GameManager.Instance.FuncChessTypeById = handler(self, self.GetPieceType)
    self._GameManager.Instance.FuncPrefabById = handler(self, self.GetPiecePrefab)
    self._GameManager.Instance:EnterGame(xBoard, interval, jumpHigh, chessboardType)
    self._GameManager.Instance:RegisterCameraDistance(handler(self, self.OnCameraDisChanged))
    local param = self:GetCameraParam()
    self._GameManager.Instance:SetCameraParam(param.NormalMin, param.NormalMax, param.DownMin, 
            param.DownMax, param.ZoomSpeed, param.DragSpeed, param.NormalMaxSpeed, param.DownDragX, param.DownDragY)
    
    --进入棋局
    self._ChessControl:DoEnterFight()
end

function XBlackRockChessControl:SwitchWeapon()
    local player = self:GetChessGamer()
    player:SwitchWeapon()
end

function XBlackRockChessControl:SwitchCamera()
    self._GameManager.Instance:SwitchCamera()
end

function XBlackRockChessControl:OnCameraDisChanged(scale)
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.CAMERA_DISTANCE_CHANGED, scale)
end

function XBlackRockChessControl:PlaySound(cueId)
    if not XTool.IsNumberValid(cueId) then
        return
    end
    
    CS.XAudioManager.PlaySound(cueId)
end

function XBlackRockChessControl:PlaySkillSound(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    self:PlaySound(template and template.CueId or 0)
end

function XBlackRockChessControl:PlaySkillHitSound(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    self:PlaySound(template and template.HitCueId or 0)
end

--endregion------------------游戏设置 finish------------------

--region   ------------------客户端配置 start-------------------

function XBlackRockChessControl:GetForbidSwitchWeaponText(index)
    return self._Model:GetClientConfigWithIndex("ForbidSwitchWeaponText", index)
end

function XBlackRockChessControl:GetPieceController()
    return self._Model:GetClientConfigWithIndex("PieceController", 1)
end

function XBlackRockChessControl:GetSecondaryConfirmationText(index)
    return self._Model:GetClientConfigWithIndex("SecondaryConfirmationText", index)
end

--- 瞄准线参数
---@return string, string, number, number, number
--------------------------
function XBlackRockChessControl:GetLineRenderProperty()
    local template = self._Model:GetClientConfig("LineRenderProperty")
    return template.Values[1], template.Values[2], tonumber(template.Values[3]), tonumber(template.Values[4]), 
    tonumber(template.Values[5])
end

function XBlackRockChessControl:GetWeaponLockText(index)
    return self._Model:GetClientConfigWithIndex("WeaponLockText", index)
end

function XBlackRockChessControl:GetWeaponMoveText(index)
    return self._Model:GetClientConfigWithIndex("WeaponMoveText", index)
end

function XBlackRockChessControl:GetEnergyNotEnoughText(index)
    return self._Model:GetClientConfigWithIndex("EnergyNotEnoughText", index)
end

function XBlackRockChessControl:GetOnSelectRoleTip(index)
    return self._Model:GetClientConfigWithIndex("OnSelectRoleTip", index)
end

function XBlackRockChessControl:GetPieceMoveConfig()
    return self._Model:GetPieceMoveConfig()
end

function XBlackRockChessControl:GetRoundBroadcastText(isPlayer, isExtraRound)
    if isPlayer then
        local index = isExtraRound and 2 or 1
        return self._Model:GetClientConfigWithIndex("RoundBroadcastText", index)
    else
        return self._Model:GetClientConfigWithIndex("RoundBroadcastText", 3)
    end
end

function XBlackRockChessControl:GetReviveBroadcastText()
    return self._Model:GetClientConfigWithIndex("ReviveBroadcastText", 1)
end

function XBlackRockChessControl:GetSkillLockText(index)
    return self._Model:GetClientConfigWithIndex("SkillLockText", index)
end

function XBlackRockChessControl:GetIsMovingText(index)
    return self._Model:GetClientConfigWithIndex("IsMovingText", index)
end

function XBlackRockChessControl:GetSettleText(index)
    return self._Model:GetClientConfigWithIndex("SettleText", index)
end

function XBlackRockChessControl:GetSettleLoseTipId()
    local id = self._Model:GetClientConfigWithIndex("SettleLoseTipId", 1)
    return tonumber(id)
end

function XBlackRockChessControl:GetDizzyEffectId()
    local id = self._Model:GetClientConfigWithIndex("CommonEffectId", 1)
    return tonumber(id)
end

function XBlackRockChessControl:GetDeadEffectId()
    local id = self._Model:GetClientConfigWithIndex("CommonEffectId", 2)
    return tonumber(id)
end

function XBlackRockChessControl:GetWarningEffectId(pieceType)
    local id = self._Model:GetClientConfigWithIndex("PieceWarningEffectId", pieceType)
    return tonumber(id)
end

function XBlackRockChessControl:GetHitEffectId(pieceType)
    local id = self._Model:GetClientConfigWithIndex("PieceHitEffectId", pieceType)
    return tonumber(id)
end

function XBlackRockChessControl:GetPreviewEffectId(pieceType)
    local id = self._Model:GetClientConfigWithIndex("PiecePreviewEffectId", pieceType)
    return tonumber(id)
end

function XBlackRockChessControl:GetDeadEffectDelay(index)
    local delay = self._Model:GetClientConfigWithIndex("DeadEffectDelay", index)
    return tonumber(delay)
end

function XBlackRockChessControl:GetPieceMoveCdText(index)
    return self._Model:GetClientConfigWithIndex("PieceMoveCdText", index)
end

function XBlackRockChessControl:GetChapterScrollOffset()
    local offset = self._Model:GetClientConfigWithIndex("ChapterScrollOffset", 1)
    return tonumber(offset)
end

function XBlackRockChessControl:GetArchiveTypeButtonText(index)
    return self._Model:GetClientConfigWithIndex("ArchiveTypeButtonText", index)
end

function XBlackRockChessControl:GetLuciaBeheadedEffectId(index)
    return tonumber(self._Model:GetClientConfigWithIndex("LuciaBeheadedEffectId", index))
end

function XBlackRockChessControl:IsArchiveOpen()
    local value = self._Model:GetClientConfigWithIndex("IsArchiveOpen", 1)
    return not string.IsNilOrEmpty(value)
end

function XBlackRockChessControl:LoadVirtualEffect(imp, pieceConfigId, isBindRole)
    if not imp then
        return
    end
    local pieceType = self:GetPieceType(pieceConfigId)
    local effectId = self:GetPreviewEffectId(pieceType)
    local vec3 = CS.UnityEngine.Vector3.zero
    isBindRole = isBindRole or false
    imp:LoadEffect(effectId, vec3, vec3, isBindRole)
    imp:SetSkinActive(false)
    
end

function XBlackRockChessControl:HideVirtualEffect(imp, pieceConfigId)
    if not imp then
        return
    end
    local pieceType = self:GetPieceType(pieceConfigId)
    local effectId = self:GetPreviewEffectId(pieceType)
    imp:HideEffect(effectId)
    imp:SetSkinActive(true)
end

function XBlackRockChessControl:GetCameraParam()
    local normal = self._Model:GetClientConfig("ViewOfNormal")
    local down = self._Model:GetClientConfig("ViewOfDown")
    local dAZ = self._Model:GetClientConfig("DragAndZoomSpeed")
    
    local data = {
        NormalMin = tonumber(normal.Values[1]),
        NormalMax = tonumber(normal.Values[2]),
        NormalMaxSpeed = tonumber(normal.Values[3]),
        DownMin = tonumber(down.Values[1]),
        DownMax = tonumber(down.Values[2]),
        DownDragX = tonumber(down.Values[3]),
        DownDragY = tonumber(down.Values[4]),
        DragSpeed = tonumber(dAZ.Values[1]),
        ZoomSpeed = tonumber(dAZ.Values[2]),
    }
    
    return data
end

function XBlackRockChessControl:GetViewOfWin()
    local view = self._Model:GetClientConfig("ViewOfWin")
    local posStr = view.Values[1]
    local pos = string.Split(posStr, "|")
    local pointStr = view.Values[2]
    local point = string.Split(pointStr, "|")
    return tonumber(pos[1]), tonumber(pos[2]), CS.UnityEngine.Vector3(tonumber(point[1]), tonumber(point[2]), 
            tonumber(point[3])), tonumber(view.Values[3])
end

function XBlackRockChessControl:GetLongPressTimer()
    local value = self._Model:GetClientConfigWithIndex("LongPressTimer", 1)
    return tonumber(value)
end

function XBlackRockChessControl:GetPreviewIconAlpha()
    local value = self._Model:GetClientConfigWithIndex("PreviewIconAlpha", 1)
    return tonumber(value)
end

function XBlackRockChessControl:GetPCInterval()
    local template = self._Model:GetClientConfig("PCInterval")
    return tonumber(template.Values[1]), tonumber(template.Values[2]), tonumber(template.Values[3])
end

function XBlackRockChessControl:GetIsAllActorOperaEndTip()
    local template = self._Model:GetClientConfig("IsAllActorOperaEndTip")
    return template.Values[1], template.Values[2], template.Values[3]
end
--endregion------------------客户端配置 finish------------------

--region 商店

function XBlackRockChessControl:OpenShop()
    local shopIds = self:GetShopIds()
    local asyncReq = asynTask(XShopManager.GetShopInfoList, nil, 2)
    RunAsyn(
            function()
                if not XTool.IsTableEmpty(shopIds) then
                    asyncReq(shopIds, nil, XShopManager.ActivityShopType.BlackRockChessShop)
                end
                XLuaUiManager.Open("UiBlackRockChessShop")
            end
    )
end

function XBlackRockChessControl:GetShopIds()
    return self._Model:GetShopIds()
end

function XBlackRockChessControl:GetCurrencyIds()
    return self._Model:GetCurrencyIds()
end

function XBlackRockChessControl:GetShopTabValue()
    return XSaveTool.GetData("BlackRockChessShopTab") or 1
end

function XBlackRockChessControl:SaveShopTabValue(tabIndex)
    XSaveTool.SaveData("BlackRockChessShopTab", tabIndex)
end

--endregion

--region 剧情

function XBlackRockChessControl:GetArchiveData()
    return self._Model:GetArchiveData()
end

function XBlackRockChessControl:SignStoryPlay(storyId)
    local key = string.format("BlackRockChessStory_%s_%s", XPlayer.Id, storyId)
    if XSaveTool.GetData(key) ~= nil then
        return
    end
    XSaveTool.SaveData(key, 1)
end

function XBlackRockChessControl:IsStoryNeedPlay(storyId)
    local key = string.format("BlackRockChessStory_%s_%s", XPlayer.Id, storyId)
    return XSaveTool.GetData(key) == nil
end

function XBlackRockChessControl:MarkCommunicationNeedPlay(communicationId)
    local key = string.format("BlackRockChessCommunication_%s_%s", XPlayer.Id, communicationId)
    if XSaveTool.GetData(key) ~= nil then
        return
    end
    XSaveTool.SaveData(key, 1)
end

function XBlackRockChessControl:IsCommunicationNeedPlay(communicationId)
    local key = string.format("BlackRockChessCommunication_%s_%s", XPlayer.Id, communicationId)
    return XSaveTool.GetData(key) == nil
end

function XBlackRockChessControl:EnterStage(stageId, responseCb)
    local storyId = self._Model:GetStageEnterStoryId(stageId)
    local isPlay = self:IsStoryNeedPlay(storyId)
    local communicationId = self._Model:GetStageEnterCommunicationId(stageId)
    
    --有剧情，优先播放剧情
    if XTool.IsNumberValid(storyId) and isPlay then
        self:SignStoryPlay(storyId)
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.Open("UiBiancaTheatreBlack")
            self:RequestEnterStage(stageId, responseCb)
        end, nil, nil, false)
    elseif XTool.IsNumberValid(communicationId) and self:IsCommunicationNeedPlay(communicationId) then
        self:PlayCommunication(communicationId, true, function()
            self:RequestEnterStage(stageId, responseCb)
        end)
    else
        self:RequestEnterStage(stageId, responseCb)
    end
end

function XBlackRockChessControl:PlayCommunication(communicationId, isMark, cb)
    local template = self._Model:GetCommunicationConfig(communicationId)
    if isMark then
        self:MarkCommunicationNeedPlay(communicationId)
    end
    XLuaUiManager.Open("UiFunctionalOpen", template, false, false, cb)
end

function XBlackRockChessControl:ExitStage(stageId)
    local afterHandle = function()
        local chapterId, difficulty = self:GetStageChapterIdAndDifficulty(stageId)
        XLuaUiManager.PopThenOpen("UiBlackRockChessChapter", chapterId, difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    end
    
    local storyId = self._Model:GetStageExitStoryId(stageId)
    local communicationId = self._Model:GetStageExitCommunicationId(stageId)

    if XTool.IsNumberValid(storyId) 
            and self:IsStoryNeedPlay(storyId) 
    then
        self:SignStoryPlay(storyId)
        XDataCenter.MovieManager.PlayMovie(storyId, afterHandle, nil, nil, false)
    elseif XTool.IsNumberValid(communicationId)
            and self:IsCommunicationNeedPlay(communicationId) 
    then
        self:PlayCommunication(communicationId, true, function()
            --由于界面关闭时，不是立马关闭，需要等通讯界面完全关闭后才能走后面的逻辑
            --否则界面堆栈会异常
            RunAsyn(function()
                while true do
                    if not XLuaUiManager.IsUiLoad("UiFunctionalOpen") then
                        break
                    end
                    asynWaitSecond(0.2)
                end
                afterHandle()
            end)
        end)
    else
        afterHandle()
    end
end

--endregion

--region 图鉴

function XBlackRockChessControl:GetHandbookConfig(handbookType)
    local datas = {}
    local configs = self._Model:GetHandbookConfigs()
    for _, v in pairs(configs) do
        if v.HandbookType == handbookType then
            table.insert(datas, v)
        end
    end
    return datas
end

function XBlackRockChessControl:GetHandbookChessConfigByIndex(index)
    local configs = self._Model:GetHandBookChessConfigs()
    return configs[index] or {}
end

function XBlackRockChessControl:IsChessUnlock(index)
    local config = self:GetHandbookChessConfigByIndex(index)
    if not config or not XTool.IsNumberValid(config.Condition) then
        return true
    end
    return XConditionManager.CheckCondition(config.Condition)
end

function XBlackRockChessControl:IsPassiveSkillUnlock(buffId)
    local config = self._Model:GetBuffConfig(buffId)
    if not config or not XTool.IsNumberValid(config.Condition) then
        return true
    end
    return XConditionManager.CheckCondition(config.Condition)
end

--endregion

--region 技能

function XBlackRockChessControl:GetPassiveSkill()
    return self._Model:GetPassiveSkill()
end

function XBlackRockChessControl:GetBuffConfig(buffId)
    return self._Model:GetBuffConfig(buffId)
end

function XBlackRockChessControl:GetBuffType(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.Type or 0
end

function XBlackRockChessControl:GetBuffParams(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.Params or 0
end

function XBlackRockChessControl:GetBuffDesc(buffId)
    if not XTool.IsNumberValid(buffId) then
        return ""
    end
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.Desc or ""
end

function XBlackRockChessControl:GetBuffIcon(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.Icon or ""
end

function XBlackRockChessControl:GetBuffTargetType(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.TargetType
end

function XBlackRockChessControl:GetGlobalBuffDict()
    return self._Model:GetGlobalBuffDict()
end

function XBlackRockChessControl:GetBuffEffectId(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.EffectId or 0
end

function XBlackRockChessControl:GetBuffName(buffId)
    local template = self._Model:GetBuffConfig(buffId)
    return template and template.Name or ""
end

--endregion

--region   ------------------RedPoint start-------------------

function XBlackRockChessControl:CheckChapterTwoRedPoint()
    return self._Model:CheckChapterTwoRedPoint()
end

function XBlackRockChessControl:MarkChapterTwoRedPoint()
    self._Model:MarkChapterTwoRedPoint()
end

function XBlackRockChessControl:CheckHardRedPoint(hardChapterId)
    return self._Model:CheckHardRedPoint(hardChapterId)
end

function XBlackRockChessControl:MarkHardChapterRedPoint(hardChapterId)
    self._Model:MarkHardChapterRedPoint(hardChapterId)
end

function XBlackRockChessControl:CheckShopRedPoint(shopId)
    return self._Model:CheckShopRedPoint(shopId)
end

function XBlackRockChessControl:ClearShopRedCache()
    self._Model:ClearShopRedCache()
end

--endregion------------------RedPoint finish------------------

--region   ------------------Request And Response start-------------------

-- 统一走此接口
function XBlackRockChessControl:UpdateBlackRockChessData(notifyData)
    self._Model:UpdateBlackRockChessData(notifyData)
    if not self._ChessControl then
        self._ChessControl = self:AddSubControl(XBlackRockChessInfo)
    end
    -- 当前布局信息
    self._ChessControl:UpdateData(notifyData.CurChessInfo)
    local isFight = not XTool.IsTableEmpty(notifyData.CurChessInfo)
    self:GetAgency():SetIsInFight(isFight, isFight and notifyData.CurChessInfo.StageId or 0)
end

--- 请求进入关卡
---@param stageId number 关卡Id
--------------------------
function XBlackRockChessControl:RequestEnterStage(stageId, cb)
    XNetwork.Call("BlackRockChessEnterStageRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:UpdateBlackRockChessData(res.BlackRockChessData)
        self:EnterFight(stageId)
        --self._ChessControl:UpdateReinforce()
        if cb then cb() end
    end)
end

--- 放弃关卡
--------------------------
function XBlackRockChessControl:RequestFinishStage(cb)

    XNetwork.Call("BlackRockChessFinishStageRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:GetAgency():SetIsInFight(false, 0)
        if cb then cb() end
    end)
end

function XBlackRockChessControl:GetReinforceActionList()
    return self._ChessControl:GetReinforceActionList()
end

function XBlackRockChessControl:GetActionList()
    local beforeEnemy, afterEnemy = self:GetChessGamer():GetActionList()
    local enemyList = self:GetChessEnemy():GetActionList()
    local list = {}
    list = XTool.MergeArray(list, beforeEnemy, enemyList, afterEnemy)
    --TODO CodeMoon, 先锋测试日志
    self:DebugRoundSync()
    for _, action in ipairs(beforeEnemy) do
        self:DebugActorOp(action.ObjId, action.ActionType, action.Params)
    end
    return list
end

--- 请求回合同步
---@return
--------------------------
function XBlackRockChessControl:RequestSyncRound(requestCb)
    --回合数增加
    self:ChangeRound(1)
    local gamer = self:GetChessGamer()
    local req = {
        StageId = self:GetStageId(),
        CurRound = self:GetChessRound(),
        ActionList = self:GetActionList(),
    }
    XNetwork.Call("BlackRockChessRoundSyncRequest", req, function(res)
        self:UpdateBlackRockChessData(res.BlackRockChessData)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            --还原
            self._ChessControl:Restore()
            local chessData = res.BlackRockChessData
            local chessInfo = chessData and chessData.CurChessInfo
            self._ChessControl:Retract(chessInfo)
            self:PrintDebugInfo()
        else
            self._ChessControl:Sync()
            if res.SettleResult then
                self:ProcessSettle(req.StageId, res.SettleResult)
                return
            end
        end
        --进入玩家回合
        gamer:OnRoundBegin()
        self:ResetWait()
        --数据更新后，触发引导
        self:ManualTriggeringGuide()
        --触发条件更新
        self:UpdateCondition()
        if requestCb then requestCb() end

        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE)
    end)
end

--- 请求悔棋
---@param responseCb function 协议回调
--------------------------
function XBlackRockChessControl:RequestRetract(responseCb)
    if XLuaUiManager.IsUiShow("UiDialog") then
        return
    end
    --第一回合不给悔棋
    local round = self:GetChessRound()
    if round <= 1 then
        XUiManager.TipMsg(self._Model:GetClientConfigWithIndex("RetractWarnTip", 2))
        return
    end
    if not self:CheckRetract() then
        XUiManager.TipMsg(self._Model:GetClientConfigWithIndex("RetractWarnTip", 3))
        return
    end
    local count = self._Model:GetStageRetractCount(self:GetStageId()) - self._ChessControl:GetRetractCount()
    local msg = string.format(self._Model:GetClientConfigWithIndex("RetractWarnTip", 1), count)
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.ReplaceTextNewLine(msg), 
            nil, nil, 
            function() 
                XNetwork.Call("BlackRockChessRetractRequest", nil, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    local chessData = res.BlackRockChessData
                    self._Model:UpdateBlackRockChessData(chessData)
                    local chessInfo = chessData and chessData.CurChessInfo
                    self._ChessControl:Retract(chessInfo)
                    if responseCb then
                        responseCb()
                    end
        end)
    end)
end

--- 请求重玩本关
---@return
--------------------------
function XBlackRockChessControl:RequestReset(responseCb)
    
    XNetwork.Call("BlackRockChessResetRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 重置战斗
        self:ResetFight()
        -- 更新数据
        self:UpdateBlackRockChessData(res.BlackRockChessData)
        -- 初始化游戏
        self:InitGame(self:GetStageId())

        if responseCb then responseCb() end

        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    end)
end

function XBlackRockChessControl:ManualTriggeringGuide()
    if XTool.IsTableEmpty(self._ManualTriggering) then
        return
    end
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    ---@type XBlackRockChessAgency
    local ag = self:GetAgency()
    for _, guideId in ipairs(self._ManualTriggering) do
        if not XDataCenter.GuideManager.CheckIsGuide(guideId) and ag:IsGuideCurrentCombat(guideId) then
            local guide = XGuideConfig.GetGuideGroupTemplatesById(guideId)
            local conditions = guide.ConditionId or {}
            local passed = true
            for _, conditionId in pairs(conditions) do
                if not XTool.IsNumberValid(conditionId) then
                    goto continue
                end
                local ret, _ = XConditionManager.CheckCondition(conditionId)
                if not ret then
                    passed = false
                    break
                end

                :: continue ::
            end

            if passed then
                XDataCenter.GuideManager.TryActiveGuide(guide)
            end
        end
    end
end

function XBlackRockChessControl:ProcessSettle(stageId, settle)
    local isWin = settle.IsWin
    local topUiName = "UiBlackRockChessBattle"
    self:SetGameRound(false)
    if isWin then
        self:GetChessGamer():DoWin(function()
            while (XLuaUiManager.GetTopUiName() ~= topUiName) do
                XLuaUiManager.Remove(XLuaUiManager.GetTopUiName())
            end
            XLuaUiManager.Open("UiBlackRockChessVictorySettlement", stageId, settle)
        end)
    else
        XLuaUiManager.PopThenOpen("UiBlackRockChessSettleLose", stageId)
    end
    self:GetAgency():SetIsInFight(false, 0)
end

function XBlackRockChessControl:ProcessSettleWithAgency(blackRockChessData, settle)
    local stageId = self:GetStageId()
    if not stageId then
        return
    end
    self:UpdateBlackRockChessData(blackRockChessData)
    self._ChessControl:Sync()
    self:ResetWait()
    self:ProcessSettle(self:GetStageId(), settle)
end

--endregion------------------Request And Response finish------------------

return XBlackRockChessControl