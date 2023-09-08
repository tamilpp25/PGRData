---@class XBlackRockChessControl : XControl
---@field private _Model XBlackRockChessModel
---@field private _ChessControl XBlackRockChessInfo
---@field private _BattleScene XChessScene
---@field private _GameManager XBlackRockChess.XBlackRockChessManager 玩法管理器
local XBlackRockChessControl = XClass(XControl, "XBlackRockChessControl")

local XChessScene = require("XModule/XBlackRockChess/XGameObject/XChessScene")

local TargetConditionType = {
    ReviveTimes = 1,
    KillTimes = 2,
    RoundTimes = 3
}

function XBlackRockChessControl:OnInit()
    --初始化内部变量
    self._BattleScene = XChessScene.New()

    self._GameManager = CS.XBlackRockChess.XBlackRockChessManager
    
    self._FuncDict = {}
    
    self._ConditionCheck = {
        [TargetConditionType.ReviveTimes] = handler(self, self.OnCheckReviveTimes),
        [TargetConditionType.KillTimes] = handler(self, self.OnCheckKillTimes),
        [TargetConditionType.RoundTimes] = handler(self, self.OnCheckRoundTimes)
    }
    
    self._OnStartAttack = handler(self, self.OnStartAttack)
    
    self._WaitingCount = 0
    
    --难度缓存
    self._DifficultCache = {
        [XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_ONE] = true,
        [XEnumConst.BLACK_ROCK_CHESS.CHAPTER_ID.CHAPTER_TWO] = true,
    }
end

function XBlackRockChessControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册

    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_BLACK_ROCK_CHESS_START_ATTACK, self._OnStartAttack)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
end

function XBlackRockChessControl:RemoveAgencyEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_BLACK_ROCK_CHESS_START_ATTACK, self._OnStartAttack)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_FIGHT_SETTLE, self.ProcessSettleWithAgency, self)
end

function XBlackRockChessControl:RegisterFunc(funName, func)
    self._FuncDict[funName] = func
end

function XBlackRockChessControl:UnRegisterFunc(funcName)
    self._FuncDict[funcName] = nil
end

function XBlackRockChessControl:DispatchEvent(funcName, ...)
    local func = self._FuncDict[funcName]
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
    self._ConditionCheck = nil
    self._BattleScene = nil
    self._FuncDict = nil
    self._GameManager.Instance:Clear()
    self._GameManager = nil
    self._DifficultCache = nil
end

function XBlackRockChessControl:EnterFight(stageId)
    self._WaitingCount = 0
    local scenePath = self:GetStageScenePrefab(stageId)
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
        self:InitGame()
    end)
    
    XLuaUiManager.Close("UiBiancaTheatreBlack")
    XLuaUiManager.Open("UiBlackRockChessBattle")
end

function XBlackRockChessControl:ExitFight()
    XLuaUiManager.SafeClose("UiBlackRockChessComponent")
    self._ChessControl:ExitFight() 
    self._GameManager.Instance:EndOfGame()
    self._BattleScene:Dispose()
end

--region   ------------------活动数据 start-------------------

function XBlackRockChessControl:GetActivityStopTime()
    return self._Model:GetActivityStopTime()
end

function XBlackRockChessControl:GetActivityName()
    return self._Model:GetActivityName()
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

--endregion------------------活动数据 finish------------------

--region   ------------------对局数据 start-------------------

function XBlackRockChessControl:GetPlayerPoint()
    local player = self:GetChessGamer()
    return player:GetCoordinate()
end

function XBlackRockChessControl:GetPlayerMovePoint()
    local player = self:GetChessGamer()
    return player:GetMovePoint()
end

function XBlackRockChessControl:GetPieceType(pieceConfigId)
    return self._Model:GetPieceType(pieceConfigId)
end

function XBlackRockChessControl:GetPieceInitCd(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.InitMoveCd or 0
end

function XBlackRockChessControl:GetChessGamer()
    return self._ChessControl:GetGamerInfo()
end

function XBlackRockChessControl:GetCurrentWeaponId()
    return self:GetChessGamer():GetWeaponId()
end

function XBlackRockChessControl:GetEnergy()
    return self:GetChessGamer():GetEnergy()
end

function XBlackRockChessControl:OnSelectSkill(skillIndex)
    self:GetChessGamer():OnSelectSkill(skillIndex)
end

function XBlackRockChessControl:OnCancelSkill(isEnterMove)
    self:GetChessGamer():OnCancelSkill(isEnterMove)
    self:GetChessEnemy():HideWarningEffect()
end

function XBlackRockChessControl:IsGamerMoving()
    return self:GetChessGamer():IsMoving()
end

function XBlackRockChessControl:GetChessEnemy()
    return self._ChessControl:GetEnemyInfo()
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

function XBlackRockChessControl:CouldUseSkill(skillId)
    local cost = self:GetWeaponSkillCost(skillId)
    local energy = self:GetEnergy()
    
    return energy >= cost
end

function XBlackRockChessControl:ConsumeEnergy(skillId)
    local cost = self:GetWeaponSkillCost(skillId)
    self:GetChessGamer():ConsumeEnergy(cost)
end

function XBlackRockChessControl:UseWeaponSkill(skillId)
    return self:GetChessGamer():UseWeaponSkill(skillId)
end

function XBlackRockChessControl:OnForceEndRound()
    self:GetChessGamer():OnForceEndRound()
    self:EndGamerRound()
end

--- 根据位置获取棋盘上的棋子
---@param vec2Int UnityEngine.Vector2Int
---@return XBlackRockChessPiece
--------------------------
function XBlackRockChessControl:PieceAtCoord(vec2Int)
    local piece = self._GameManager.Instance:PieceAtCoord(vec2Int)
    if not piece then
        return
    end
    --这个位置为玩家
    if piece.Id == XEnumConst.BLACK_ROCK_CHESS.PLAYER_MEMBER_ID then
        return self:GetChessGamer()
    end
    return self:GetChessEnemy():GetPieceInfo(piece.Id)
end

function XBlackRockChessControl:RemovePiece(pieceId)
    self:GetChessEnemy():RemovePieceInfo(pieceId)
end

function XBlackRockChessControl:UpdateReinforce()
    if not self._ChessControl then
        return
    end
    self._ChessControl:UpdateReinforce()
end

function XBlackRockChessControl:BroadcastRound(isPlayer, isExtraRound) 
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.BROADCAST_ROUND, self:GetRoundBroadcastText(isPlayer, isExtraRound))
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
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.BROADCAST_ROUND, self:GetReviveBroadcastText())
end

function XBlackRockChessControl:GetIncId()
    if not self._ChessControl then
        return 0
    end
    return self._ChessControl:GetIncId()
end

function XBlackRockChessControl:PlayGamerAnimation(animName, cb)
    local gamer = self:GetChessGamer()
    gamer:PlayAnimation(animName, cb)
end

function XBlackRockChessControl:PlayGamerTimeAnimation(animName, cb)
    local gamer = self:GetChessGamer()
    gamer:PlayTimeLineAnimation(animName, cb)
end

function XBlackRockChessControl:GetKillTotal()
    if not self._ChessControl then
        return 0
    end
    return self._ChessControl:GetKillTotal()
end

function XBlackRockChessControl:AddKillCount(pieceType)
    self._ChessControl:AddKillCount(pieceType)
    self:AddEnergyWhenKill()
end

function XBlackRockChessControl:IsWaiting()
    return self._WaitingCount ~= 0
end

function XBlackRockChessControl:ConfirmWaiting()
    self._WaitingCount = self._WaitingCount + 1
end

function XBlackRockChessControl:CancelWaiting()
    self._WaitingCount = self._WaitingCount - 1
end

function XBlackRockChessControl:GetTargetDescription()
    local stageId = self:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return ""
    end
    local template = self._Model:GetStageConfig(stageId)
    local targetConditionIds = template.TargetConditions or {}
    local targetConditionId = targetConditionIds[1]
    if not XTool.IsNumberValid(targetConditionId) then
        return ""
    end
    local condition = self._Model:GetConditionConfig(targetConditionId)
    local desc = condition.Desc
    if condition.Type == TargetConditionType.ReviveTimes then
        return string.format(desc, self:GetChessGamer():GetReviveCount() .. "/" .. condition.Params[1])
    elseif condition.Type == TargetConditionType.KillTimes then
        local pieceType = condition.Params[2]
        local count = XTool.IsNumberValid(pieceType) and 
                self._ChessControl:GetKillCount(pieceType) or self._ChessControl:GetKillTotal()
        return string.format("%s(%s/%s)", desc, count, condition.Params[1])
    elseif condition.Type == TargetConditionType.RoundTimes then
        return string.format("%s(%s/%s)", desc, self:GetChessRound(), condition.Params[1])
    end
end

function XBlackRockChessControl:OnStartAttack(evt, objs)
    local skillId = objs[0]
    self:GetChessGamer():StartAttack(skillId)
end

function XBlackRockChessControl:AddEnergyWhenRound()
    local template = self._Model:_GetActivityConfig()
    local count = template.RoundEnergyAdd or 0
    self:GetChessGamer():ConsumeEnergy(count * -1)
end

function XBlackRockChessControl:AddEnergyWhenKill()
    local template = self._Model:_GetActivityConfig()
    local count = template.KillEnergyAdd or 0
    self:GetChessGamer():ConsumeEnergy(count * -1)
end

function XBlackRockChessControl:UpdateEnergy()
    self._Model:UpdateEnergy(self:GetChessGamer():GetEnergy())
end

function XBlackRockChessControl:UpdateIsExtraRound()
    self._Model:UpdateExtraRound(self:GetChessGamer():IsExtraTurn())
end

--endregion------------------对局数据 finish------------------

--region   ------------------武器 start-------------------

function XBlackRockChessControl:GetWeaponType(weaponId)
    return self._Model:GetWeaponType(weaponId)
end

function XBlackRockChessControl:GetWeaponIcon(weaponId)
    return self._Model:GetWeaponIcon(weaponId)
end

function XBlackRockChessControl:GetWeaponIds()
    local list = self._Model:GetWeaponIds()
    table.sort(list, function(a, b) 
        return a < b
    end)
    
    return list
end

function XBlackRockChessControl:GetWeaponIdByType(weaponType)
    return self._Model:GetWeaponIdByType(weaponType)
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

function XBlackRockChessControl:GetWeaponSkillCost(skillId, isDefault)
    if isDefault or not self._ChessControl then
        return self._Model:GetWeaponSkillCost(skillId)
    end
    local gamer = self:GetChessGamer()
    if not gamer then
        return self._Model:GetWeaponSkillCost(skillId)
    end
    local skill = gamer:GetSkill(skillId)
    return skill and skill.MonaCost or self._Model:GetWeaponSkillCost(skillId)
end

function XBlackRockChessControl:GetWeaponSkillRange(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Range or 0
end

function XBlackRockChessControl:GetWeaponSkillType(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Type or 0
end

function XBlackRockChessControl:GetWeaponSkillIcon(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.Icon or ""
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

function XBlackRockChessControl:WeaponSkillIsDefault(skillId)
    return self._Model:WeaponSkillIsDefault(skillId)
end

function XBlackRockChessControl:IsPassive(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.IsPassive == 1 or false
end

function XBlackRockChessControl:IsAttack(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    local type = template and template.Type or false
    return type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK 
            or type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK
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

-- 技能额外回合
function XBlackRockChessControl:GetWeaponSkillExtraTurn(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    if template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK 
            and template.Type ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL2 then
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

function XBlackRockChessControl:GetWeaponAttackTimeLine(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.AttackTimeLine or ""
end

function XBlackRockChessControl:GetWeaponEffectIds(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.EffectId or {}
end

function XBlackRockChessControl:GetWeaponEffectDelay(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.EffectDelay or {}
end

function XBlackRockChessControl:GetWeaponHitEffectIds(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.HitEffectId or {}
end

function XBlackRockChessControl:GetWeaponAttackAnimName(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.AttackAnimName or ""
end

function XBlackRockChessControl:GetWeaponSkillCueId(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.CueId or 0
end

function XBlackRockChessControl:GetWeaponSkillHitCueId(skillId)
    local template = self._Model:GetWeaponSkillConfig(skillId)
    return template and template.HitCueId or 0
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
    return template and template.Type or XEnumConst.BLACK_ROCK_CHESS.REINFORCE_TYPE.KING_RANDOM
end

function XBlackRockChessControl:GetReinforcePreviewCd(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.PreviewCd or -1
end

function XBlackRockChessControl:GetReinforceTriggerCd(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.TriggerCd or -1
end

function XBlackRockChessControl:GetReinforceLocations(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.Locations or {}
end

function XBlackRockChessControl:GetReinforcePieceIds(reinforceId)
    local template = self._Model:GetReinforceConfig(reinforceId)
    return template and template.PieceIds or {}
end

function XBlackRockChessControl:GetPieceBuffIds(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.BuffIds or {}
end

function XBlackRockChessControl:GetPieceDesc(pieceConfigId)
    local template = self._Model:GetPieceConfig(pieceConfigId)
    return template and template.Desc or "???"
end

function XBlackRockChessControl:GetPieceLife(id)
    local piece = self:GetChessEnemy():GetPieceInfo(id)
    if not piece then
        return 0
    end
    return piece:GetHp()
end

--endregion------------------棋子 finish------------------

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

function XBlackRockChessControl:GetStageScenePrefab(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.ScenePrefab or ""
end

function XBlackRockChessControl:GetReinforceIds(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.ReinforceIds or {}
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

function XBlackRockChessControl:GetStageEnterStotyId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.EnterStoryId or 0
end

function XBlackRockChessControl:GetStageExitStotyId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.ExitStoryId or 0
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

--- 正在战斗的关卡是否结束
---@return
--------------------------
function XBlackRockChessControl:IsFightingStageEnd()
    local stageId = self._ChessControl:GetStageId()
    local template = self._Model:GetStageConfig(stageId)
    local targetConditionIds = template.TargetConditions or {}
    local pass = true
    for _, conditionId in ipairs(targetConditionIds) do
        if not self:CheckStagePassCondition(conditionId) then
            pass = false
            break
        end
    end
    return pass
end

function XBlackRockChessControl:CheckStagePassCondition(conditionId)
    local template = self._Model:GetConditionConfig(conditionId)
    local fun = self._ConditionCheck[template.Type]
    if not fun then
        return false, ""
    end
    return fun(template)
end

--- 复活次数小于x次
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XBlackRockChessControl:OnCheckReviveTimes(template)
    local reviveTimes = template.Params[1]
    local gamerReviveTimes = self:GetChessGamer():GetReviveCount()
    
    return gamerReviveTimes <= reviveTimes, template.Desc
end

--- 击杀棋子数量达到（数量，棋子类型-可不配，不配为任意棋子）
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XBlackRockChessControl:OnCheckKillTimes(template)
    local killCount = template.Params[1]
    local killPieceType = template.Params[2]
    local current = 0
    if XTool.IsNumberValid(killPieceType) then
        current = self._ChessControl:GetKillCount(killPieceType)
    else
        current = self._ChessControl:GetKillTotal()
    end
    
    return current >= killCount, template.Desc
end

--- 回合数达到
---@param template XTableBlackRockChessCondition
---@return boolean, string
--------------------------
function XBlackRockChessControl:OnCheckRoundTimes(template)
    local round = template.Params[1]
    return self:GetChessRound() >= round, template.Desc
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
    return template and template.TargetDesc or ""
end

function XBlackRockChessControl:GetStageStarRewardTemplateId(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.StarRewardTemplateId or 0
end

function XBlackRockChessControl:GetStageBuffIds(stageId)
    local template = self._Model:GetStageConfig(stageId)
    return template and template.BuffIds or {}
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
    local key = string.format("Chapter%sPrefab", chapterId)
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

function XBlackRockChessControl:InitGame()
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
    local interval, jumpHigh = self:GetPieceMoveConfig()
    self._GameManager.Instance.FuncChessTypeById = handler(self, self.GetPieceType)
    self._GameManager.Instance.FuncPrefabById = handler(self, self.GetPiecePrefab)
    self._GameManager.Instance:EnterGame(xBoard, interval, jumpHigh)
    self._GameManager.Instance:RegisterCameraDistance(handler(self, self.OnCameraDistance))
    local param = self:GetCameraParam()
    self._GameManager.Instance:SetCameraParam(param.NormalMin, param.NormalMax, param.DownMin, 
            param.DownMax, param.ZoomSpeed, param.DragSpeed, param.NormalMaxSpeed, param.DownDragX, param.DownDragY)
    self._ChessControl:SetEnemyImp(self._GameManager.Instance.Enemy)
    
    --初始化棋子布局
    local pieceDict = self._ChessControl:GetPieceDict()
    local prepareRemove = {}
    for _, piece in pairs(pieceDict) do
        local x, y = piece:GetPos()
        local configId = piece:GetConfigId()
        local isPiece = piece:IsPiece()
        local imp = self._GameManager.Instance:AddPiece(configId, x, y, not isPiece)
        if imp then
            piece:SetImp(imp)
        else
            prepareRemove[piece:GetId()] = true
        end
    end
    for id, value in pairs(prepareRemove) do
        self:RemovePiece(id)
    end
    --初始化玩家布局
    local gamer = self:GetChessGamer()
    local prefab = self:GetPiecePrefab(gamer:GetId())
    local cX, cY = gamer:GetPos()
    local imp = self._GameManager.Instance:AddGamer(prefab, cX, cY)
    gamer:SetImp(imp)
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_HP_HUD, gamer:GetId(), imp.transform)
    --玩家回合开始
    gamer:OnRoundBegin()
end

function XBlackRockChessControl:SwitchWeapon()
    local player = self:GetChessGamer()
    player:SwitchWeapon()
end

function XBlackRockChessControl:SwitchCamera()
    self._GameManager.Instance:SwitchCamera()
end

function XBlackRockChessControl:IsShotgun()
    local player = self:GetChessGamer()
    return player:IsShotgun()
end

function XBlackRockChessControl:IsKnife()
    local player = self:GetChessGamer()
    return player:IsKnife()
end

function XBlackRockChessControl:EndGamerRound()
    RunAsyn(function()
        
        local gamer = self:GetChessGamer()
        if gamer then
            gamer:OnRoundEnd()
        end
        while true do
            --等待玩家的操作结束
            if not self:IsWaiting() then
                break
            end
            asynWaitSecond(0.1)
        end
        if self:IsFightingStageEnd() then
            self:RequestSyncRound()
            return
        end
        local enemy = self:GetChessEnemy()
        if enemy then
            enemy:OnRoundBegin()
        end
    end)
end

function XBlackRockChessControl:OnCameraDistance(scale)
    self:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CAMERA_DISTANCE_CHANGED, scale)
end

function XBlackRockChessControl:PlaySound(cueId)
    if not XTool.IsNumberValid(cueId) then
        return
    end
    
    CS.XAudioManager.PlaySound(cueId)
end

--endregion------------------游戏设置 finish------------------

--region   ------------------客户端配置 start-------------------

function XBlackRockChessControl:GetForbidSwitchWeaponText(index)
    return self._Model:GetClientConfigWithIndex("ForbidSwitchWeaponText", index)
end

function XBlackRockChessControl:GetPieceController()
    return self._Model:GetClientConfigWithIndex("PieceController", 1)
end

function XBlackRockChessControl:GetLineRenderProperty()
    local template = self._Model:GetClientConfig("LineRenderProperty")
    return template.Values[1], tonumber(template.Values[2]), tonumber(template.Values[3]), tonumber(template.Values[4])
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

function XBlackRockChessControl:GetEffectConfig(effectId)
    local template = self._Model:GetEffectConfig(effectId)
    local url = template.EffectPrefab
    local offset = CS.UnityEngine.Vector3.zero
    local offsetStr = template.Offset
    if not string.IsNilOrEmpty(offsetStr) then
        local split = string.Split(offsetStr, "|")
        offset.x = tonumber(split[1])
        offset.y = tonumber(split[2])
        offset.z = tonumber(split[3])
    end
    local rotate = CS.UnityEngine.Vector3.zero
    local rotateStr = template.Rotate
    if not string.IsNilOrEmpty(rotateStr) then
        local split = string.Split(rotateStr, "|")
        rotate.x = tonumber(split[1])
        rotate.y = tonumber(split[2])
        rotate.z = tonumber(split[3])
    end
    
    return url, offset, rotate
end

function XBlackRockChessControl:LoadEffect(imp, effectId, offset, rotate, delay)
    if not imp then
        return
    end
    local url, configOffset, configRotate = self:GetEffectConfig(effectId)
    offset = offset or configOffset
    rotate = rotate or configRotate
    if delay and delay > 0 then
        XScheduleManager.ScheduleOnce(function()
            if not imp or XTool.UObjIsNil(imp.gameObject) then
                return
            end
            imp:LoadEffect(url, offset, rotate)
        end, delay)
        return
    end
    
    imp:LoadEffect(url, offset, rotate)
end

function XBlackRockChessControl:FireEffect(imp, effectId, offset, rotate, delay, shotCenter, hitCb)
    if not imp then
        return
    end
    local url, configOffset, configRotate = self:GetEffectConfig(effectId)
    offset = offset or configOffset
    rotate = rotate or configRotate

    if delay and delay > 0 then
        XScheduleManager.ScheduleOnce(function()
            if not imp or XTool.UObjIsNil(imp.gameObject) then
                return
            end
            imp:FireEffect(url, offset, rotate, shotCenter, hitCb)
        end, delay)
        return
    end

    imp:FireEffect(url, offset, rotate, shotCenter, hitCb)
end

function XBlackRockChessControl:LoadVirtualEffect(imp, pieceConfigId)
    if not imp then
        return
    end
    local pieceType = self:GetPieceType(pieceConfigId)
    local effectId = self:GetPreviewEffectId(pieceType)
    self:LoadEffect(imp, effectId)
    imp:SetSkinActive(false)
end

function XBlackRockChessControl:HideVirtualEffect(imp, pieceConfigId)
    if not imp then
        return
    end
    local pieceType = self:GetPieceType(pieceConfigId)
    local effectId = self:GetPreviewEffectId(pieceType)
    imp:HideEffect(self:GetEffectUrl(effectId))
    imp:SetSkinActive(true)
end

function XBlackRockChessControl:GetEffectUrl(effectId)
    local template = self._Model:GetEffectConfig(effectId)
    return template and template.EffectPrefab or ""
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
    return tonumber(pos[1]), tonumber(pos[2]), tonumber(view.Values[2])
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
    local template = self._Model:GetClientConfig("CurrencyIds")
    local ids = {}
    for _, id in pairs(template.Values or {}) do
        table.insert(ids, tonumber(id))
    end
    return ids
end

function XBlackRockChessControl:GetShopTabValue()
    return XSaveTool.GetData("BlackRockChessShopTab") or 1
end

function XBlackRockChessControl:SaveShopTabValue(tabIndex)
    XSaveTool.SaveData("BlackRockChessShopTab", tabIndex)
end

function XBlackRockChessControl:MarkShopRedPoint()
    if not XSaveTool.GetData("BlackRockChessFirstOpenShop") then
        XSaveTool.SaveData("BlackRockChessFirstOpenShop", true)
    end
    local shopIds = self:GetShopIds()
    for _, id in pairs(shopIds) do
        local key = string.format("BlackRockChessShop_%s", id)
        if not XSaveTool.GetData(key) then
            XSaveTool.SaveData(key, true)
        end
    end
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

function XBlackRockChessControl:EnterStage(stageId, responseCb)
    local storyId = self:GetStageEnterStotyId(stageId)
    local isPlay = self:IsStoryNeedPlay(storyId)
    if XTool.IsNumberValid(storyId) and isPlay then
        self:SignStoryPlay(storyId)
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            XLuaUiManager.Open("UiBiancaTheatreBlack")
            self:RequestEnterStage(stageId, responseCb)
        end, nil, nil, false)
    else
        self:RequestEnterStage(stageId, responseCb)
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
    return template and template.TargetType or 0
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

--endregion------------------RedPoint finish------------------

--region   ------------------Request And Response start-------------------

-- 统一走此接口
function XBlackRockChessControl:UpdateBlackRockChessData(notifyData)
    self._Model:UpdateBlackRockChessData(notifyData)
    if not self._ChessControl then
        self._ChessControl = self:AddSubControl(require("XModule/XBlackRockChess/XEntity/XBlackRockChessInfo"))
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
            --校验失败，回合数还原
            self:ChangeRound(-1)
            --还原
            self._ChessControl:Restore()
        else
            self._ChessControl:Sync()
            if res.SettleResult then
                self:ProcessSettle(req.StageId, res.SettleResult)
                --隐藏遮罩
                if XLuaUiManager.IsMaskShow(XEnumConst.BLACK_ROCK_CHESS.MASK_KEY) then
                    XLuaUiManager.SetMask(false, XEnumConst.BLACK_ROCK_CHESS.MASK_KEY)
                end
                return
            end
        end
        --进入玩家回合
        gamer:OnRoundBegin()
        self._WaitingCount = 0
        --数据更新后，触发引导
        self:ManualTriggeringGuide()
        if requestCb then requestCb() end

        XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_ROUND_CHANGE)
        --隐藏遮罩
        if XLuaUiManager.IsMaskShow(XEnumConst.BLACK_ROCK_CHESS.MASK_KEY) then
            XLuaUiManager.SetMask(false, XEnumConst.BLACK_ROCK_CHESS.MASK_KEY)
        end
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
                
                ::continue::
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
    if isWin then
        self:GetChessGamer():DoWin()
        while (XLuaUiManager.GetTopUiName() ~= topUiName) do
            XLuaUiManager.Remove(XLuaUiManager.GetTopUiName())
        end
        XLuaUiManager.Open("UiBlackRockChessVictorySettlement", stageId, settle)
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
    self._WaitingCount = 0
    self:ProcessSettle(self:GetStageId(), settle)
    if XLuaUiManager.IsMaskShow(XEnumConst.BLACK_ROCK_CHESS.MASK_KEY) then
        XLuaUiManager.SetMask(false, XEnumConst.BLACK_ROCK_CHESS.MASK_KEY)
    end
end

--endregion------------------Request And Response finish------------------

return XBlackRockChessControl