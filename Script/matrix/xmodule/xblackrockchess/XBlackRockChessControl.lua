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

local V2Distance = CS.UnityEngine.Vector2Int.Distance

function XBlackRockChessControl:OnInit()
    --初始化内部变量
    self._BattleScene = XChessScene.New()

    self._GameManager = CS.XBlackRockChess.XBlackRockChessManager
    
    self._FuncDict = {}

    self:ResetWait()
    
    self._IsGamerRound = false
    self._ConditionControl = self:AddSubControl(XChessConditionControl)
    
    local url1, url2, hLine, hPiece, pointCount = self:GetLineRenderProperty()
    CS.XBlackRockChess.XBlackRockChessUtil.InitLine(hPiece, hLine, pointCount, url1, url2)
    
    self._DebugInfo = ""
    self._MultiMoveDebugInfo = ""
    self._DebugPieceType = { "士兵", "骑士", "主教", "城堡", "皇后", "国王" }
end

function XBlackRockChessControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
end

function XBlackRockChessControl:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
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
    self._DebugInfo = ""
end

function XBlackRockChessControl:GetBattleScene()
    return self._BattleScene
end

function XBlackRockChessControl:DebugRoundSync()
    local info = string.format("关卡%s 第%s节点 第%s回合:\n", self:GetStageId(), self:GetChessNodeIdx(), self:GetChessRound() - 1)
    if string.IsNilOrEmpty(self._DebugInfo) then
        self._DebugInfo = "\n"
    end
    self._DebugInfo = self._DebugInfo .. info
end

function XBlackRockChessControl:DebugActorOp(id, actionType, params)
    local info = ""
    if actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE then
        info = string.format("\t角色移动到坐标（%s, %s）\n", params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK then
        info = string.format("\t角色释放技能[%s], 技能中心点（%s, %s）\n", params[2], params[3], params[4])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND then
        info = string.format("\t跳过回合\n")
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE then
        info = string.format("\t角色复活到坐标（%s, %s）\n", params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PASSIVE_SKILL then
        info = string.format("\t角色使用被动技能[%s] 使用次数[%s]\n", params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK then
        info = string.format("\t角色反击\n")
    end
    self._DebugInfo = self._DebugInfo .. info
end

function XBlackRockChessControl:DebugEmenyOp(id, objType, actionType, params)
    local info
    if objType == XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS then
        info = string.format("\tBOSS[%s] ", id)
    else
        info = string.format("\t敌棋[%s] ", id)
    end
    if actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE then
        info = info .. string.format("移动到坐标（%s, %s）\n", params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON then
        local configId = params[1]
        local pieceType = self:GetPieceType(configId)
        local pieceTypeStr = self._DebugPieceType[pieceType]
        info = info .. string.format("触发buffId[%s] 召唤%s[configId:%s]到坐标（%s, %s）\n", params[5], pieceTypeStr, configId, params[3], params[4])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.TRANSFORM then
        local pieceType = self:GetPieceType(params[2])
        local pieceTypeStr = self._DebugPieceType[pieceType]
        info = info .. string.format("触发buff 将棋子[%s]转化为%s[configId:%s]\n", params[1], pieceTypeStr, params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK then
        info = info .. string.format("使用武器[%s]释放技能[%s] 对坐标（%s, %s）造成[%s]次伤害\n", params[1], params[2], params[3], params[4], params[5])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.DELAY_SKILL then
        info = info .. string.format("延迟使用武器[%s]的技能[%s]\n", params[1], params[2])
    elseif actionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SUMMON_VIRTUAL then
        info = info .. string.format("使用技能[%s]召唤虚影[%s]到坐标（%s, %s）\n", params[5], params[2], params[3], params[4])
    else
        info = ""
    end
    self._DebugInfo = self._DebugInfo .. info
end

function XBlackRockChessControl:DebugMutilMove(actionId, actionType)
    local info = string.format("BeforeEnemy ActionId:%s ActionType:%s\n", actionId, actionType)
    self._MultiMoveDebugInfo = self._MultiMoveDebugInfo .. info
end

function XBlackRockChessControl:DebugActionChange(eventName, actionId)
    local info = string.format("%s 事件Id发生变化 当前Id:%s\n", eventName, actionId)
    self._MultiMoveDebugInfo = self._MultiMoveDebugInfo .. info
end

function XBlackRockChessControl:PrintDebugInfo()
    XLog.Error(self._DebugInfo)
    self._DebugInfo = ""
    XLog.Error(self._MultiMoveDebugInfo)
    self._MultiMoveDebugInfo = ""
end

function XBlackRockChessControl:RunAsynWithPCall(callBack)
    if not callBack then
        return
    end
    RunAsyn(function()
        self:XPCall(callBack)
    end)
end

function XBlackRockChessControl:XPCall(func)
    if XMain.IsWindowsEditor then
        xpcall(func, function(error)
            XLog.Error(error)
        end)
    else
        func()
    end
end

function XBlackRockChessControl:EnterFight(stageId, isNewGame)
    self:ResetWait()
    local curNodeCfg = self:GetCurNodeCfg()
    local scenePath = curNodeCfg.ScenePrefab
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

    if XLuaUiManager.IsUiLoad("UiBlackRockChessChapterDetail") then
        XLuaUiManager.Remove("UiBlackRockChessChapterDetail")
    end
    
    XLuaUiManager.OpenWithCallback("UiBlackRockChessComponent", function()
        --展示场景
        self._BattleScene:Display(scenePath)
        --初始化游戏
        self:InitGame(stageId)

        XLuaUiManager.Close("UiBiancaTheatreBlack")
        XLuaUiManager.Open("UiBlackRockChessBattle", isNewGame)
    end)
end

function XBlackRockChessControl:ExitFight()
    XLuaUiManager.SafeClose("UiBlackRockChessComponent")
    self:ResetFight()
    self._BattleScene:Dispose()
end

function XBlackRockChessControl:ResetFight()
    self._DebugInfo = ""
    self._MultiMoveDebugInfo = ""
    self._ChessControl:ExitFight()
    self._GameManager.Instance:EndOfGame()
    if self._CvAudio then
        self._CvAudio:Stop()
        self._CvAudio = nil
    end
    self:RemoveSubControl(self._ChessControl)
    self._ChessControl = nil
    self._Model:SetChessControl(nil)
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

function XBlackRockChessControl:GetPartnerPieceMoveCd(pieceConfigId)
    local template = self._Model:GetPartnerPieceById(pieceConfigId)
    return template and template.MoveCd or 0
end

---@return XBlackRockChessGamer
function XBlackRockChessControl:GetChessGamer()
    return self._ChessControl:GetGamerInfo()
end

---@return XBlackRockChessEnemy
function XBlackRockChessControl:GetChessEnemy()
    return self._ChessControl:GetEnemyInfo()
end

function XBlackRockChessControl:GetChessPartner()
    return self._ChessControl:GetPartnerInfo()
end

function XBlackRockChessControl:GetShopInfo()
    return self._ChessControl:GetShopInfo()
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

function XBlackRockChessControl:IsEnterRedModel()
    return self:GetChessGamer():IsEnterRedModel()
end

function XBlackRockChessControl:OnSelectSkill(roleId, skillId)
    local actor = self:GetChessGamer():GetRole(roleId)
    if not actor then
        return
    end
    actor:OnSelectSkill(skillId)
end

function XBlackRockChessControl:OnCancelSkill(isEnterMove)
    local actor = self:GetChessGamer():GetSelectActor()
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

function XBlackRockChessControl:GetChessNodeIdx()
    return self._ChessControl:GetNodeIdx()
end

function XBlackRockChessControl:GetChessBuffList()
    return self._ChessControl:GetBuffList()
end

function XBlackRockChessControl:GetChessBuffIds()
    local buffList = self:GetChessBuffList()
    local ids = {}
    for i, buff in pairs(buffList) do
        if buff.RemainRound > 0 then
            table.insert(ids, buff.BuffId)
        end
    end
    return ids
end

function XBlackRockChessControl:GetChessNodeGroupId()
    return self._ChessControl:GetNodeGroupId()
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

function XBlackRockChessControl:ConsumeEnergy(roleId, skillId, extraCost)
    local cost = self:GetWeaponSkillCost(roleId, skillId)
    self:GetChessGamer():ConsumeEnergy(cost + extraCost)
end

---角色技能造成伤害回复能量
---@param attackTimes number 技能造成伤害的次数
function XBlackRockChessControl:SkillAttackRecoverEnergy(skillId, attackTimes)
    local skillCfg = self._Model:GetWeaponSkillConfig(skillId)
    local skillType = skillCfg.Type
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_ATTACK then
        if attackTimes > 0 then
            local energy = skillCfg.Params[4] or 0
            self:GetChessGamer():ConsumeEnergy(-energy)
        end
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL2 then
        local last = 0
        local energy = 0
        for i = 1, attackTimes do
            last = skillCfg.Params[2 + i] or last
            energy = energy + last
        end
        self:GetChessGamer():ConsumeEnergy(-energy)
    end
end

---角色格挡敌人进攻回复能量
function XBlackRockChessControl:SkillDefenseRecoverEnergy(energy)
    self:GetChessGamer():ConsumeEnergy(-energy)
end

--- 友方棋子触发战斗回复能量
function XBlackRockChessControl:PartnerFightRecoverEnergy()
    local fightNode = self:GetCurNodeCfg()
    if not fightNode or not XTool.IsNumberValid(fightNode.PartnerAddEnergy) then
        return
    end
    self:GetChessGamer():ConsumeEnergy(-fightNode.PartnerAddEnergy)
end

function XBlackRockChessControl:OnForceEndRound()
    self:GetChessGamer():DoForceEndOfTurn()
    self:EndGamerRound()
end

function XBlackRockChessControl:EndGamerRound()
    self:RunAsynWithPCall(function()
        --玩家回合结束
        local gamer = self:GetChessGamer()
        gamer:OnRoundEnd()
        gamer:ApplyBlendBuffAfter()
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
        --移除角色格挡数据（只持续到回合结束）
        gamer:RemoveDefenseState()
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

function XBlackRockChessControl:IsWaittingPlaySkill(value)
    self._IsWattingPlaySkill = value
end

function XBlackRockChessControl:IsWaiting()
    return self._WaitingCount ~= 0 or self:GetChessGamer():IsMoving() or self._IsWattingPlaySkill
end

--能否操作
function XBlackRockChessControl:IsOperate()
    if self:IsWaiting() then
        return false
    end

    if self._IsWattingPlaySkill then
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

-- 设置敌方棋子选中状态
function XBlackRockChessControl:SetEnemySelect(isSelected)
    self.IsEnemySelected = isSelected
end

-- 获取敌方棋子选中状态
function XBlackRockChessControl:IsEnemySelect()
    return self.IsEnemySelected == true
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

---等待回退操作执行完毕后再开始友方棋子行动
function XBlackRockChessControl:SyncWaitRestoreMoveEnd()
    self:RunAsynWithPCall(function()
        while true do
            if not self:IsWaiting() then
                self:StartGameRound()
                break
            end
            asynWaitSecond(0.2)
        end
    end)
end

--- 根据位置获取棋盘上的棋子
---@param vec2Int UnityEngine.Vector2Int
---@return XBlackRockChessPiece | XChessActor | XBlackRockChessPartnerPiece
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
    --当前位置为boss
    elseif piece.IsBoss and piece:IsBoss() then
        return self:GetChessEnemy():GetBossInfo(piece.ChessBoss.RoleId)
    else
        if piece.Id and piece.Id <= 0 then
            return self:GetChessEnemy():GetPieceInfoByPoint(vec2Int)
        elseif piece.IsPartner then
            return self:GetChessPartner():GetPieceInfo(piece.Id)
        else
            return self:GetChessEnemy():GetPieceInfo(piece.Id)
        end
    end
end

function XBlackRockChessControl:VirtualPieceAtCoord(vec2Int)
    return self._GameManager.Instance:VirtualPieceAtCoord(vec2Int)
end

function XBlackRockChessControl:PartnerPieceAtCoord(vec2Int)
    return self._GameManager.Instance:PartnerPieceAtCoord(vec2Int)
end

function XBlackRockChessControl:IsSafeCoordinate(col, row)
    return CS.XBlackRockChess.XBlackRockChessUtil.IsSafeCoordinate(col, row)
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
    self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BROADCAST_ROUND, self:GetRoundBroadcastText(isPlayer, isExtraRound))
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
    self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BROADCAST_ROUND, self:GetReviveBroadcastText())
end

function XBlackRockChessControl:ShowBubbleText(imp, text)
    if not imp then
        return
    end
    self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_DIALOG_BUBBLE, imp.transform, text)
end

function XBlackRockChessControl:GetChessGrowlsConfig(belong, trigger, belongArg, triggerArg)
    return self._Model:GetChessGrowlsConfig(belong, trigger, belongArg, triggerArg)
end

function XBlackRockChessControl:PlayGrowls(belong, trigger, belongArg, triggerArg)
    local template = self._Model:GetChessGrowlsConfig(belong, trigger, belongArg, triggerArg)
    if not template then
        self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_GROWLS)
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
            self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_GROWLS, triggerArg)
        end
        if cvId then
            if self._CvAudio then
                self._CvAudio:Stop()
            end
            if duration <= 0 then
                self._CvAudio = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId, hideFunc)
            else
                self._CvAudio = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId)
            end
            self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_GROWLS, cvText, triggerArg, duration)
        else
            self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_GROWLS, cvText, triggerArg, duration)
        end
    elseif belong == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PIECE then
        if cvId then
            self._CvAudio = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId)
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

---@param piece XBlackRockChessPiece
function XBlackRockChessControl:AddKillCount(pieceType, actorId)
    --增加击杀人数
    self:GetChessGamer():AddKillCount(pieceType)
    if actorId then
        -- 角色击杀敌人回复能量
        local template = self._Model:_GetActivityConfig()
        local count = template.KillEnergyAdd or 0
        self:GetChessGamer():ConsumeEnergy(count * -1)
    end
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
        ObjId = objId, --主体id
        ActionType = actionType,--行动类型
        ObjType = objType, --主体类型 对应XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE
        Params = { ... } --行动参数
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

function XBlackRockChessControl:GetGridValueByHp(hp, maxBloodGridCount)
    local left = 0
    if hp > 0 then
        local value = hp % maxBloodGridCount
        left = value == 0 and maxBloodGridCount or value
    end
    return left
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

function XBlackRockChessControl:GetWeaponCircleIcon(weaponId)
    return self._Model:GetWeaponCircleIcon(weaponId)
end

function XBlackRockChessControl:GetWeaponCircleIcon(weaponId)
    return self._Model:GetWeaponCircleIcon(weaponId)
end

function XBlackRockChessControl:GetWeaponModelUrl(weaponId)
    return self._Model:GetWeaponModelUrl(weaponId)
end

function XBlackRockChessControl:GetWeaponControllerUrl(weaponId)
    return self._Model:GetWeaponControllerUrl(weaponId)
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

function XBlackRockChessControl:GetWeaponDesc2(weaponId)
    return self._Model:GetWeaponDesc2(weaponId)
end

function XBlackRockChessControl:GetWeaponUnlockDesc(weaponId)
    return self._Model:GetWeaponUnlockDesc(weaponId)
end

function XBlackRockChessControl:GetWeaponMapIcon(weaponId)
    return self._Model:GetWeaponMapIcon(weaponId)
end

function XBlackRockChessControl:GetWeaponMapIcon2(weaponId)
    return self._Model:GetWeaponMapIcon2(weaponId)
end

function XBlackRockChessControl:GetWeaponSkillIds(weaponId)
    return self._Model:GetWeaponSkillIds(weaponId)
end

function XBlackRockChessControl:GetWeaponSkillIcon(skillId)
    return self._Model:GetWeaponSkillIcon(skillId)
end

function XBlackRockChessControl:GetWeaponSkillBg(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.IconBg or ""
end

function XBlackRockChessControl:GetWeaponSkillCost(roleId, skillId, isDefault)
    if not XMVCA.XBlackRockChess:IsInFight() or isDefault then
        return self._Model:GetWeaponSkillCost(skillId)
    end
    local role = self:GetChessGamer():GetRole(roleId)
    return role:TryGetSkill(skillId):GetCost() + role:GetAddRoundCost(skillId)
end

function XBlackRockChessControl:GetWeaponSkillCd(roleId, skillId, isDefault)
    if not XMVCA.XBlackRockChess:IsInFight() or isDefault then
        return self._Model:GetWeaponSkillCd(skillId).Cd
    end
    return self:GetChessGamer():GetRole(roleId):TryGetSkill(skillId):GetCd()
end

function XBlackRockChessControl:GetWeaponSkillById(id)
    return self._Model:GetWeaponSkillById(id)
end

function XBlackRockChessControl:GetWeaponSkillInitCd(skillId)
    local template = self._Model:GetWeaponSkillCd(skillId)
    return template and template.InitCd or 0
end

function XBlackRockChessControl:GetWeaponSkillSkillIds(skillId)
    local template = self._Model:GetWeaponSkillById(skillId)
    return template and template.SkillIds or 0
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

function XBlackRockChessControl:GetWeaponSkillName2(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Name2 or ""
end

function XBlackRockChessControl:GetWeaponSkillDesc(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Desc or ""
end

function XBlackRockChessControl:GetWeaponSkillDesc2(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Desc2 or ""
end

function XBlackRockChessControl:GetWeaponSkillMapIcon(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.MapIcon or ""
end

function XBlackRockChessControl:GetWeaponSkillMapIcon2(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.MapIcon2 or ""
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

function XBlackRockChessControl:GetWeaponTypeBySkillId(skillId)
    return self._Model:GetWeaponTypeBySkillId(skillId)
end

--endregion------------------武器 finish------------------

--region   ------------------棋子 start-------------------

function XBlackRockChessControl:GetPieceHeadIconByType(pieceConfigId, type)
    if type == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY then
        return self:GetPieceHeadIcon(pieceConfigId)
    end
    return self:GetPartnerPieceHeadIcon(pieceConfigId)
end

function XBlackRockChessControl:GetPieceHeadIcon(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.HeadIcon or ""
end

function XBlackRockChessControl:GetPartnerPieceHeadIcon(pieceConfigId)
    local template = self._Model:GetPartnerPieceById(pieceConfigId)
    return template and template.HeadIcon or ""
end

function XBlackRockChessControl:GetPieceMaxLifeByType(pieceConfigId, type)
    if type == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY then
        return self:GetPieceMaxLife(pieceConfigId)
    end
    return self._Model:GetPartnerPieceById(pieceConfigId).MaxLife
end

function XBlackRockChessControl:GetPieceMaxLife(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.MaxLife or 1
end

function XBlackRockChessControl:GetPartnerMaxLife(pieceConfigId)
    local template = self._Model:GetPartnerPieceById(pieceConfigId)
    return template and template.MaxLife or 1
end

function XBlackRockChessControl:GetPieceAtkLife(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.AtkLife or 0
end

function XBlackRockChessControl:GetPromotionPieceId(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.PromotionPiece or 0
end

function XBlackRockChessControl:GetPromotionPartnerPieceIds(pieceConfigId)
    local template = self._Model:GetPartnerPieceById(pieceConfigId)
    return template and template.PromotionPieces or 0
end

function XBlackRockChessControl:GetPiecePrefab(pieceConfigId)
    return self._Model:GetPiecePrefab(pieceConfigId)
end

function XBlackRockChessControl:GetPartnerPiecePrefab(pieceConfigId)
    return self:GetPartnerPieceById(pieceConfigId).Prefab
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

function XBlackRockChessControl:GetPieceBuffIdsByType(pieceConfigId, type)
    if type == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY then
        return self:GetPieceBuffIds(pieceConfigId)
    end
    return self:GetPartnerBuffIds(pieceConfigId)
end

function XBlackRockChessControl:GetPieceBuffIds(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.BuffIds or {}
end

function XBlackRockChessControl:GetPartnerBuffIds(pieceConfigId)
    local template = self._Model:GetPartnerPieceById(pieceConfigId)
    return template and template.BuffIds or {}
end

function XBlackRockChessControl:GetPieceDescByType(pieceConfigId, type)
    if type == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY then
        return self:GetPieceDesc(pieceConfigId)
    end
    return self._Model:GetPartnerPieceById(pieceConfigId).Name
end

function XBlackRockChessControl:GetPieceDesc(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.Desc or "???"
end

function XBlackRockChessControl:GetPieceTransPartnerPiece(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.TransPartnerPiece
end

function XBlackRockChessControl:GetPieceType(pieceConfigId)
    return self._Model:GetPieceType(pieceConfigId)
end

function XBlackRockChessControl:GetPartnerPieceType(pieceConfigId)
    return self:GetPartnerPieceById(pieceConfigId).Type
end

function XBlackRockChessControl:GetPartnerPieceBornCd(pieceConfigId)
    return self:GetPartnerPieceById(pieceConfigId).BornCd
end

function XBlackRockChessControl:GetPartnerPieceDesc(pieceConfigId)
    return self:GetPartnerPieceById(pieceConfigId).Desc
end

function XBlackRockChessControl:GetPartnerPieceById(id)
    return self._Model:GetPartnerPieceById(id)
end

function XBlackRockChessControl:IsPartnerLevelUp(configId)
    return self._ChessControl:GetPartnerInfo():IsLevelUp(configId)
end

function XBlackRockChessControl:UpdatePartnerPieceByCSharp(guid, pieceId, x, y, index, operate)
    self:GetChessPartner():UpdatePieceByCSharp(guid, pieceId, x, y, index, operate)
end

function XBlackRockChessControl:AutoPartnerLayout2Site(guid, pieceId, isMoved)
    local siteIdx = self:GetChessPartner():GetEmptyPrepareBattleSite()
    self:GetChessPartner():SetPieceToSite(siteIdx, guid, pieceId)
    if isMoved then
        local piece = self:GetChessPartner():GetPieceInfo(guid)
        if piece then
            self._GameManager.Instance:MoveTo(piece._Imp, siteIdx, 0, function()
                self._GameManager.Instance:ExitMove();
            end)
        end
    end
end

function XBlackRockChessControl:IsPartnerLevelMax(configId)
    return self._Model:IsPartnerLevelMax(configId)
end

---血量 > 距离 > y更小 > x更大
---@param a XBlackRockChessPiece
---@param b XBlackRockChessPiece
function XBlackRockChessControl:PieceCommonSort(point, a, b)
    if a:GetHp() ~= b:GetHp() then
        return a:GetHp() < b:GetHp()
    end
    local aPoint = a:GetMovedPoint()
    local bPoint = b:GetMovedPoint()
    local aDistance = V2Distance(point, aPoint)
    local bDistance = V2Distance(point, bPoint)
    if aDistance ~= bDistance then
        return aDistance < bDistance
    end
    if aPoint.y ~= bPoint.y then
        return aPoint.y < bPoint.y
    end
    if aPoint.x ~= bPoint.x then
        return aPoint.x > bPoint.x
    end
    return a:GetId() < b:GetId()
end

---@param a XBlackRockChessPiece
---@param b XBlackRockChessPiece
function XBlackRockChessControl:PieceDistanceSort(point, a, b)
    local aPoint = a:GetMovedPoint()
    local bPoint = b:GetMovedPoint()
    local aDistance = V2Distance(point, aPoint)
    local bDistance = V2Distance(point, bPoint)
    if aDistance ~= bDistance then
        return aDistance < bDistance
    end
    return a:GetId() < b:GetId()
end

function XBlackRockChessControl:GetReinforceCd(id)
    return self._ChessControl:GetReinforceCd(id)
end

--endregion------------------棋子 finish------------------

--region   ------------------角色 start-------------------

function XBlackRockChessControl:GetSelectActor()
    return self:GetChessGamer():GetSelectActor()
end

function XBlackRockChessControl:GetCharacterConfig(roleId)
    return self._Model:GetCharacterConfig(roleId)
end

function XBlackRockChessControl:GetRoleModelUrl(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.ModelUrl or ""
end

function XBlackRockChessControl:GetRoleName(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.Name or ""
end

function XBlackRockChessControl:GetRoleDesc(roleId)
    local template = self._Model:GetCharacterConfig(roleId)
    return template and template.Desc or ""
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
    local roleIds = self:GetChessGamer():GetRoleIds()
    for _, roleId in pairs(roleIds) do
        local template = self._Model:GetCharacterConfig(roleId)
        if template.Type == XEnumConst.BLACK_ROCK_CHESS.CHARACTER_TYPE.MASTER then
            return roleId
        end
    end
    return 0
end

function XBlackRockChessControl:GetMasterRole()
    return self:GetChessGamer():GetRole(self:GetMasterRoleId())
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

function XBlackRockChessControl:GetEnterRedModelEnergy()
    local conditions = self._Model:GetConditionByType(XEnumConst.BLACK_ROCK_CHESS.CONDITION_TYPE.ENTER_RED_MODEL)
    return tonumber(conditions[1].Params[1])
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

function XBlackRockChessControl:GetMovePauseDistance()
    local template = self._Model:GetClientConfig("MovePauseDistance")
    return template and tonumber(template.Values[1]) or 0
end

function XBlackRockChessControl:GetStageExitStoryId(stageId)
    return self._Model:GetStageExitStoryId(stageId)
end

function XBlackRockChessControl:GetStageExitCommunicationId(stageId)
    return self._Model:GetStageExitCommunicationId(stageId)
end

function XBlackRockChessControl:GetActiveConditionId()
    return self._ChessControl and self._ChessControl:GetConditionId() or 0
end

function XBlackRockChessControl:GetTargetDescription()
    return self._ConditionControl and self._ConditionControl:GetStageTargetDesc() or ""
end


--- 正在战斗的关卡是否结束
---@return boolean
--------------------------
function XBlackRockChessControl:IsFightingStageEnd()
    --国王已死
    if self:GetChessEnemy():IsKingPieceDead() then
        return true
    end
    --BOSS已死
    if self:GetChessEnemy():IsBosseDead() then
        return true
    end
    --保底 全部棋子死亡时结束关卡
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
        --[[if XTool.IsNumberValid(template.FirstPassWeaponId) then
            table.insert(rewards, { reward = template.FirstPassWeaponId, isWeapon = true })
        end
        if XTool.IsNumberValid(template.FirstPassSkillId) then
            table.insert(rewards, { reward = template.FirstPassSkillId, isPassSkill = true })
        end
        if not XTool.IsTableEmpty(template.FirstPassBuffIds) then
            for _, buffId in pairs(template.FirstPassBuffIds) do
                table.insert(rewards, { reward = buffId, isBuff = true })
            end
        end]]
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

function XBlackRockChessControl:GetChapterProgress()
    -- 已完成章节/章节总数
    local finish, total = 0, 0
    local dict = self._Model:GetChapterDifficultyMap()
    for chapterId, datas in pairs(dict) do
        for difficulty, chapter in pairs(datas) do
            if difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL then
                for _, stageId in pairs(chapter.StageIds) do
                    total = total + 1
                    if self._Model:IsStagePass(stageId) then
                        finish = finish + 1
                    end
                end
            end
        end
    end
    if total == 0 then
        return 0
    end
    return finish / total
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

function XBlackRockChessControl:GetClientConfigWithIndex(key, index)
    return self._Model:GetClientConfigWithIndex(key, index)
end

---备战席位置数
function XBlackRockChessControl:GetPrapareBattleSiteCount()
    return self._Model:_GetActivityConfig().MaxPartnerCount
end

function XBlackRockChessControl:GetBuyPartnerPieceCount()
    return self._ChessControl:GetShopInfo():GetBuyPieceCount()
end

function XBlackRockChessControl:GetPartnerLayoutCount()
    local datas = self:GetChessPartner():GetLayoutDict()
    return XTool.GetTableCount(datas)
end

function XBlackRockChessControl:CheckLayoutLimitByCSharp()
    local count = self:GetPartnerLayoutCount()
    if count >= self:GetCurNodeCfg().PartnerPieceLimit then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessLayoutLimitTip"))
        return true
    end
    return false
end

function XBlackRockChessControl:CloseStageRedPoint(stageId)
    self._Model:CloseStageRedPoint(stageId)
end

function XBlackRockChessControl:IsEverBeenEnterStage(stageId)
    return self._Model:IsEverBeenEnterStage(stageId)
end

--endregion------------------关卡 finish------------------

--region 节点

function XBlackRockChessControl:GetNodeCfgsByNodeGroupId(nodeGroupId)
    return self._Model:GetNodeCfgsByNodeGroupId(nodeGroupId)
end

function XBlackRockChessControl:GetCurNodeCfg()
    return self._Model:GetCurNodeCfg()
end

--endregion

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

function XBlackRockChessControl:SetViewPosToLocalPosition(uiTrans, position, offset, pivot)
    if not self._GameManager then
        return
    end
    self._GameManager.Instance:SetViewPosToLocalPosition(uiTrans, position, offset, pivot)
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
    local curNodeCfg = self:GetCurNodeCfg()
    local chessboardType = curNodeCfg.ChessBoardType
    self._GameManager.Instance.FuncChessTypeById = handler(self, self.GetPieceType)
    self._GameManager.Instance.FuncPrefabById = handler(self, self.GetPiecePrefab)
    self._GameManager.Instance.FuncPartnerPrefabById = handler(self, self.GetPartnerPiecePrefab)
    self._GameManager.Instance.FuncPartnerChessTypeById = handler(self, self.GetPartnerPieceType)
    self._GameManager.Instance:EnterGame(xBoard, interval, jumpHigh, chessboardType)
    self._GameManager.Instance:RegisterCameraDistance(handler(self, self.OnCameraDisChanged))
    self._GameManager.Instance.Partner.FuncChangePiecePos = handler(self, self.UpdatePartnerPieceByCSharp)
    self._GameManager.Instance.Partner.FuncCheckLayoutLimit = handler(self, self.CheckLayoutLimitByCSharp)
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

function XBlackRockChessControl:SwitchCameraToDown()
    self._GameManager.Instance:SwitchCameraToDown()
end

function XBlackRockChessControl:SwitchCameraToNormal()
    self._GameManager.Instance:SwitchCameraToNormal()
end

function XBlackRockChessControl:OnCameraDisChanged(scale)
    self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_CAMERA_DISTANCE_CHANGED, scale)
end

function XBlackRockChessControl:PlaySound(cueId)
    if not XTool.IsNumberValid(cueId) then
        return
    end
    
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
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

function XBlackRockChessControl:GetClashEffectId(pieceType)
    local id = self._Model:GetClientConfigWithIndex("ClashEffectId", pieceType)
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

function XBlackRockChessControl:GetEnergyBgByActorRedModel()
    local isRedModel = self:GetChessGamer():IsEnterRedModel()
    return self._Model:GetClientConfigWithIndex("EnergyBg", isRedModel and 2 or 1)
end

function XBlackRockChessControl:LoadVirtualEffect(imp, pieceConfigId, isBindRole)
    if not imp then
        return
    end
    local pieceType = imp.IsPartner and self:GetPartnerPieceType(pieceConfigId) or self:GetPieceType(pieceConfigId)
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
    local pieceType = imp.IsPartner and self:GetPartnerPieceType(pieceConfigId) or self:GetPieceType(pieceConfigId)
    local effectId = self:GetPreviewEffectId(pieceType)
    imp:HideEffect(effectId)
    imp:SetSkinActive(true)
end

function XBlackRockChessControl:LoadClashEffect(imp, pieceConfigId, isBindRole)
    if not imp then
        return
    end
    local pieceType = imp.IsPartner and self:GetPartnerPieceType(pieceConfigId) or self:GetPieceType(pieceConfigId)
    local effectId = self:GetClashEffectId(pieceType)
    local vec3 = CS.UnityEngine.Vector3.zero
    isBindRole = isBindRole or false
    imp:LoadEffect(effectId, vec3, vec3, isBindRole)
    imp:SetSkinActive(false)
end

function XBlackRockChessControl:HideClashEffect(imp, pieceConfigId)
    if not imp then
        return
    end
    local pieceType = imp.IsPartner and self:GetPartnerPieceType(pieceConfigId) or self:GetPieceType(pieceConfigId)
    local effectId = self:GetClashEffectId(pieceType)
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

function XBlackRockChessControl:GetClientConfig(key, index)
    index = index or 1
    local configs = self._Model:GetClientConfig(key)
    return configs.Values[index]
end

function XBlackRockChessControl:GetClientConfigValues(key)
    local config = self._Model:GetClientConfig(key)
    return config.Values
end

function XBlackRockChessControl:GetEffectConfig(id)
    return self._Model:GetEffectConfig(id)
end
--endregion------------------客户端配置 finish------------------

--region 章节

function XBlackRockChessControl:GetChapterDifficultyMap()
    return self._Model:GetChapterDifficultyMap()
end

function XBlackRockChessControl:GetStageConfig(stageId)
    return self._Model:GetStageConfig(stageId)
end

function XBlackRockChessControl:GetStageScore(stageId)
    return self._Model:GetStgaeScore(stageId)
end

function XBlackRockChessControl:IsChapterInTime(chapterId, difficulty)
    return self._Model:IsChapterInTime(chapterId, difficulty, true)
end

function XBlackRockChessControl:GetChapterIds()
    return self._Model:_GetActivityConfig().Chapters
end

function XBlackRockChessControl:GetChapterConfig(chapterId, difficulty)
    return self._Model:GetChapterConfig(chapterId, difficulty)
end

--endregion

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

function XBlackRockChessControl:GetBattleShopGoodById(id)
    return self._Model:GetBattleShopGoodById(id)
end

function XBlackRockChessControl:GetBattleShopById(id)
    return self._Model:GetBattleShopById(id)
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

    --进入非正在挑战的关卡时 需要重新播引导
    if not XMVCA.XBlackRockChess:IsCurStageId(stageId) then
        XMVCA.XBlackRockChess:ClearCurrentCombat()
    end
    
    --有剧情，优先播放剧情
    if XTool.IsNumberValid(storyId) and isPlay then
        self:SignStoryPlay(storyId)
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.Open("UiBiancaTheatreBlack")
            self:RequestEnterStage(stageId, responseCb, true)
        end, nil, nil, false)
    elseif XTool.IsNumberValid(communicationId) and self:IsCommunicationNeedPlay(communicationId) then
        self:PlayCommunication(communicationId, true, function()
            self:RequestEnterStage(stageId, responseCb, true)
        end)
    else
        self:RequestEnterStage(stageId, responseCb, true)
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
        --local chapterId, difficulty = self:GetStageChapterIdAndDifficulty(stageId)
        --XLuaUiManager.PopThenOpen("UiBlackRockChessChapter", chapterId, difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
    end
    
    local storyId = self._Model:GetStageExitStoryId(stageId)
    local communicationId = self._Model:GetStageExitCommunicationId(stageId)

    if XTool.IsNumberValid(storyId) and self:IsStoryNeedPlay(storyId) then
        self:SignStoryPlay(storyId)
        XDataCenter.MovieManager.PlayMovie(storyId, afterHandle, nil, nil, false)
    elseif XTool.IsNumberValid(communicationId) and self:IsCommunicationNeedPlay(communicationId) then
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

---@param buffImp XBlackRockChess.XBuff
---@param piece XBlackRockChessPiece
function XBlackRockChessControl:OnBuffTakeEffect(args, buffImp, piece)
    local buffId, buffType = args[0], args[1]
    local BuffType = XMVCA.XBlackRockChess.BuffType
    local gamer = self:GetChessGamer()
    local enemy = self:GetChessEnemy()
    local partner = self:GetChessPartner()
    local masterRole = self:GetMasterRole()
    
    if buffType == BuffType.SkillEnergyCostAdd then
        local count, roleId = args[2], args[3]
        gamer:GetRole(roleId):AddSkillCost(count)
        
    elseif buffType == BuffType.InitContinuationRound then
        local count, roleId = args[2], args[3]
        gamer:GetRole(roleId):SetBuffContinuationRound(count)
        
    elseif buffType == BuffType.CallAfterDeathWithAround or buffType == BuffType.CallAfterWithAttacked or buffType == BuffType.CallAfterMoveWithAround then
        local effectCount = buffImp and buffImp.EffectCount or 0
        if piece:IsPartner() then
            partner:Summon(piece:GetId(), buffId, args[2], args[3] or gamer:IsExtraTurn(), effectCount, piece:GetHitActorId(), piece:GetHitRoundCount())
        else
            enemy:Summon(piece:GetId(), buffId, args[2], args[3] or gamer:IsExtraTurn(), effectCount, piece:GetHitActorId(), piece:GetHitRoundCount())
        end

    elseif buffType == BuffType.CallAfterDeath then
        local impList = args[2]
        local virtualList = args[3]
        local effectCount = buffImp and buffImp.EffectCount or 0
        for i = 0, impList.Count - 1 do
            local imp = impList[i]
            local isVirtual = virtualList[i] or gamer:IsExtraTurn()
            if piece:IsPartner() then
                partner:SummonOne(piece:GetId(), buffId, imp, isVirtual, effectCount, piece:GetHitActorId(), piece:GetHitRoundCount())
            else
                enemy:SummonOne(piece:GetId(), buffId, imp, isVirtual, effectCount, piece:GetHitActorId(), piece:GetHitRoundCount())
            end
        end
        
    elseif buffType == BuffType.TransformerWithDeath then
        if piece:IsPartner() then
            partner:TransformPiece(piece:GetId(), args[2], args[3], piece:GetHitActorId(), piece:GetHitRoundCount())
        else
            enemy:TransformPiece(piece:GetId(), args[2], args[3], piece:GetHitActorId(), piece:GetHitRoundCount())
        end

    elseif buffType == BuffType.ChangeSkillPropertyWithDeath then
        local cd, energy = args[2], args[3]
        gamer:ConsumeEnergy(-energy)
        if XTool.IsNumberValid(piece:GetHitActorId()) then
            local actor = self._OwnControl:GetChessGamer():GetRole(piece:GetHitActorId())
            --不在场，则获取主控角色
            if not actor or not actor:IsInBoard() then
                actor = masterRole
            end
            actor:AddSkillCd(cd)
        end
        
    elseif buffType == BuffType.AddFriendlyHpWithDeath then
        -- List<int> List<int[]> List<int>
        local addHpList, pieceTypeList, memberList = args[2], args[3], args[4]
        for idx = 0, addHpList.Count - 1 do
            local addHp = addHpList[idx]
            local isPartner = memberList[idx]
            local pieceTypes = pieceTypeList[idx]
            for i = 0, pieceTypes.Length - 1 do
                local pieceType = pieceTypes[i]
                if isPartner then
                    partner:AddHpOverflowByType(pieceType, addHp)
                else
                    enemy:AddHpOverflowByType(pieceType, addHp)
                end
            end
        end
        
    elseif buffType == BuffType.DestoryAddHp then
        --自毁并将当前血量加到所有棋子上
        local hpAdd = math.ceil(piece:GetHp() * args[2] / 10000)
        local dict = partner:GetPieceInfoDict()
        local blendPieceId = gamer:GetSelectActor():GetBlendPieceId()
        for _, piece in pairs(dict) do
            if piece:GetId() ~= blendPieceId then
                piece:AddHpOverflow(hpAdd)
            end
        end
        
    elseif buffType == BuffType.SkillCdChange then
        --技能cd减少
        masterRole:AddSkillCd(args[2])
        
    elseif buffType == BuffType.MoveTimesAdd then
        --再次移动
        masterRole:EnterMoveAgain()
        
    elseif buffType == BuffType.EnergyAdd then
        --怒气值增加
        gamer:AddEnergy(args[2])
        self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_ERENGY_UPDATE)
        
    elseif buffType == BuffType.DestoryInjuryFree then
        --免疫伤害
        masterRole:SetInjuryFreeTimes(args[2])
    end
end

--endregion

--region 排行榜

function XBlackRockChessControl:GetRankData(chapterId)
    return self._Model:GetRankData(chapterId)
end

function XBlackRockChessControl:GetMyRankData(chapterId)
    return self._Model:GetMyRankData(chapterId)
end

function XBlackRockChessControl:GetRankingSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then
        return
    end
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. rank)
end

-- 每次进入排行榜界面都重新刷新数据
function XBlackRockChessControl:PreReqRank()
    local chapterIds = self:GetChapterIds()
    for _, chapterId in ipairs(chapterIds) do
        local config = self:GetChapterConfig(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
        if config.IsRank then
            self:RequestBlackRockChessQueryRank(chapterId)
            return
        end
    end
end

function XBlackRockChessControl:ClearRankData()
    self._Model._MyRankData = nil
    self._Model._RankDatas = nil
end

--endregion

--region   ------------------RedPoint start-------------------

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
        self._Model:SetChessControl(self._ChessControl)
    end
    -- 当前布局信息
    self._Model:UpdateNodeInfo(notifyData.CurChessInfo)
    self._ChessControl:UpdateData(notifyData.CurChessInfo)
    local isFight = not XTool.IsTableEmpty(notifyData.CurChessInfo)
    self:GetAgency():SetIsInFight(isFight, isFight and notifyData.CurChessInfo.StageId or 0)
end

--- 请求进入关卡
---@param stageId number 关卡Id
--------------------------
function XBlackRockChessControl:RequestEnterStage(stageId, cb, isNewGame)
    XNetwork.Call("BlackRockChessEnterStageRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:UpdateBlackRockChessData(res.BlackRockChessData)
        self:EnterFight(stageId, isNewGame)
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

        XMVCA.XBlackRockChess:SetIsInFight(false, 0)
        if cb then cb(res) end
    end)
end

function XBlackRockChessControl:GetReinforceActionList()
    return self._ChessControl:GetReinforceActionList()
end

function XBlackRockChessControl:GetActionList()
    local beforeActor, afterActor, finally = self:GetChessGamer():GetActionList()
    local beforeEnemy, afterEnemy = self:GetChessEnemy():GetActionList()
    local partnerList = self:GetChessPartner():GetActionList()
    local list = {}
    list = XTool.MergeArray(partnerList, beforeActor, beforeEnemy, afterActor, afterEnemy, finally)

    --region CodeMoon, 先锋测试日志
    self:DebugRoundSync()
    for _, action in ipairs(beforeActor) do
        self:DebugActorOp(action.ObjId, action.ActionType, action.Params)
    end
    for _, action in ipairs(beforeEnemy) do
        self:DebugEmenyOp(action.ObjId, action.ObjType, action.ActionType, action.Params)
    end
    for _, action in ipairs(afterActor) do
        self:DebugActorOp(action.ObjId, action.ActionType, action.Params)
    end
    for _, action in ipairs(afterEnemy) do
        self:DebugEmenyOp(action.ObjId, action.ObjType, action.ActionType, action.Params)
    end
    for _, action in ipairs(finally) do
        self:DebugActorOp(action.ObjId, action.ActionType, action.Params)
    end
    --endregion
    
    return list
end

---服务端给请求回合同步定了1s的cd
---在点击【跳过回合】时 会先执行敌方棋子逻辑 然后是BOSS 最后才是发协议 所以不能在按钮上加cd 得特殊处理
function XBlackRockChessControl:IsPassNetworkCd()
    if not self._SendNetworkTime then
        return true
    end
    return CS.UnityEngine.Time.unscaledTime - self._SendNetworkTime > 1
end

function XBlackRockChessControl:StartGameRound()
    self:OnCancelSkill(true)
    self:GetChessGamer():OnRoundBegin()
end

--- 请求回合同步
---@return
--------------------------
function XBlackRockChessControl:RequestSyncRound(requestCb)
    local nodeIdx = self:GetChessNodeIdx()
    --回合数增加
    self:ChangeRound(1)
    local partner = self:GetChessPartner()
    local req = {
        StageId = self:GetStageId(),
        CurRound = self:GetChessRound(),
        ActionList = self:GetActionList(),
    }
    XNetwork.Call("BlackRockChessRoundSyncRequest", req, function(res)
        self._SendNetworkTime = CS.UnityEngine.Time.unscaledTime
        if res.Code ~= XCode.Success then
            self:UpdateBlackRockChessData(res.BlackRockChessData)
            XUiManager.TipCode(res.Code)
            --还原
            self._ChessControl:Restore()
            local chessData = res.BlackRockChessData
            local chessInfo = chessData and chessData.CurChessInfo
            self._Model:UpdateNodeInfo(chessInfo)
            self._ChessControl:Retract(chessInfo)
            self:PrintDebugInfo()
            self:SyncWaitRestoreMoveEnd()
        else
            local isSettle = res.SettleResult ~= nil
            local isNextNode = nodeIdx <= res.BlackRockChessData.CurChessInfo.NodeIdx
            if not isNextNode then
                self:UpdateBlackRockChessData(res.BlackRockChessData)
                self._ChessControl:Sync()
            end
            if isSettle then
                self:ProcessSettle(req.StageId, res.SettleResult)
                return
            elseif isNextNode then
                -- 进入下一个节点
                self:EnterNextNode(req.StageId, res.BlackRockChessData)
                return
            end
        end
        --数据更新后，触发引导
        self:ManualTriggeringGuide()
        --触发条件更新
        self:UpdateCondition()
        if requestCb then
            requestCb()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE)
        -- 角色开始行动
        self:StartGameRound()
    end)
end

function XBlackRockChessControl:EnterNextNode(stageId, blackRockChessData)
    local actor = self:GetMasterRole()
    actor:PlayAnimation("NodeVictory")
    actor:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.NODE_SUCCESS)
    XLuaUiManager.OpenWithCloseCallback("UiBlackRockChessToastClear", function()
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        local actor = self:GetChessGamer():GetSelectActor()
        self:OnCancelSkill(false)
        self:ResetFight()
        self:UpdateBlackRockChessData(blackRockChessData)
        --加载场景
        local curNodeCfg = self:GetCurNodeCfg()
        self._BattleScene:Display(curNodeCfg.ScenePrefab)
        self:InitGame(stageId)
        XLuaUiManager.Close("UiBiancaTheatreBlack")
        self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, true)
    end, XUiHelper.GetText("BlackRockChessFightNodeEnter"))
end

--- 请求悔棋
---@param responseCb function 协议回调
--------------------------
--[[function XBlackRockChessControl:RequestRetract(responseCb)
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
                    XLuaUiManager.Open("UiBiancaTheatreBlack")
                    -- 重置战斗
                    self:ResetFight()
                    -- 更新数据
                    self:UpdateBlackRockChessData(res.BlackRockChessData)
                    -- 初始化游戏
                    self:InitGame(self:GetStageId())
                    
                    if responseCb then responseCb() end

                    XLuaUiManager.Close("UiBiancaTheatreBlack")
        end)
    end)
end]]

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
        --加载场景
        local curNodeCfg = self:GetCurNodeCfg()
        self._BattleScene:Display(curNodeCfg.ScenePrefab)
        -- 初始化游戏
        self:InitGame(self:GetStageId())

        if responseCb then responseCb() end

        self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH, true)
    end)
end

function XBlackRockChessControl:ManualTriggeringGuide()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    XDataCenter.GuideManager.CheckGuideOpen()
    
    if XTool.IsTableEmpty(self._ManualTriggering) then
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
        self:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PLAY_WIN)
        self:GetChessGamer():DoWin(function()
            while (XLuaUiManager.GetTopUiName() ~= topUiName) do
                XLuaUiManager.Remove(XLuaUiManager.GetTopUiName())
            end
            XLuaUiManager.Open("UiBlackRockChessVictorySettlement", stageId, settle)
        end)
    else
        while (XLuaUiManager.GetTopUiName() ~= topUiName) do
            XLuaUiManager.Remove(XLuaUiManager.GetTopUiName())
        end
        XLuaUiManager.Open("UiBlackRockChessVictorySettlement", stageId, settle)
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

--- 查询排行榜请求
function XBlackRockChessControl:RequestBlackRockChessQueryRank(chapterId, cb)
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessQueryRankRequest", { ChapterId = chapterId }, function(res)
        self._Model:SetRankData(chapterId, res)
        if cb then
            cb()
        end
    end)
end

--- 布阵请求
function XBlackRockChessControl:RequestBlackRockChessPartnerLayout(cb)
    local layouts = {}
    local dict = self:GetChessPartner():GetLayoutDict()
    for _, data in pairs(dict) do
        table.insert(layouts, {
            X = data.X,
            Y = data.Y,
            Guid = data.Guid,
            PieceId = data.PieceId,
        })
    end
    local pieces = self:GetChessPartner():GetPieceBagData()
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessPartnerLayoutRequest", { PartnerLayouts = layouts, PartnerPieces = pieces }, function(res)
        self._Model:UpdateNodeInfo(res.CurChessInfo)
        self._ChessControl:UpdateData(res.CurChessInfo)
        if cb then
            cb()
        end
    end)
end

--- 商店刷新请求
function XBlackRockChessControl:RequestBlackRockChessRefreshGoods(cb)
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessRefreshGoodsRequest", {}, function(res)
        self:GetShopInfo():UpdateCoin(res.Coin)
        self:GetShopInfo():UpdateShopData(res.ShopData)
        if cb then
            cb()
        end
    end)
end

--- 购买商品请求
function XBlackRockChessControl:RequestBlackRockChessBuyGoods(goodsIndex, count, cb)
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessBuyGoodsRequest", { GoodsIndex = goodsIndex, Count = count }, function(res)
        self._Model:UpdateNodeInfo(res.CurChessInfo)
        self._ChessControl:UpdateData(res.CurChessInfo)
        self:GetChessPartner():ModifyPrepareData()
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ExitMove()
        if cb then
            cb()
        end
    end)
end

--- 完成商店购买请求
function XBlackRockChessControl:RequestBlackRockChessFinishShop(cb)
    local layouts = {}
    local dict = self:GetChessPartner():GetLayoutDict()
    for _, data in pairs(dict) do
        table.insert(layouts, {
            X = data.X,
            Y = data.Y,
            Guid = data.Guid,
            PieceId = data.PieceId,
        })
    end
    local pieces = self:GetChessPartner():GetPieceBagData()
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessFinishShopRequest", { PartnerLayouts = layouts, PartnerPieces = pieces }, function(res)
        self._Model:UpdateNodeInfo(res.CurChessInfo)
        self._ChessControl:UpdateData(res.CurChessInfo)
        self:GetChessPartner():DoEnterFight()
        self:StartGameRound()
        if cb then
            cb()
        end
    end)
end

--- 回收棋子请求
function XBlackRockChessControl:RequestBlackRockChessRecyclePiece(guid, cb)
    XNetwork.CallWithAutoHandleErrorCode("BlackRockChessRecyclePieceRequest", { PieceGuid = guid }, function(res)
        -- 如果出售的是备战位的棋子 需要刷新下备战位
        local sellPrepareSiteIdx = self:GetChessPartner():GetPrepareSiteIndex(guid)
        self._Model:UpdateNodeInfo(res.CurChessInfo)
        self._ChessControl:UpdateData(res.CurChessInfo)
        self:GetChessPartner():UpdatePrepareData(sellPrepareSiteIdx)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ExitMove()
        if cb then
            cb()
        end
    end)
end

--endregion------------------Request And Response finish------------------

return XBlackRockChessControl