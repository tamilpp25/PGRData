---@class XChessActor : XEntity 玩家角色
---@field _Imp XBlackRockChess.XChessRole
---@field _OwnControl XBlackRockChessControl
---@field _TargetOfAttack table<number, UnityEngine.Vector2Int> 攻击到的地板
---@field _SkillDict table<number, XChessSkill> 技能
---@field _RoleSkillDict table<number, XRoleSkill> 技能
---@field _BuffDict table<number, XBlackRockChess.XBuff> 技能
local XChessActor = XClass(XEntity, "XChessActor")

local XChessSkill = require("XModule/XBlackRockChess/XGameObject/XChessSkill")

local XLunaProtectedSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XLunaProtectedSkill")
local XLunaHyperPassive = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XLunaHyperPassive")

local AttackBatch = {
    Assist = 1, --协助攻击
    Normal = 2, --正常攻击
    Multi  = 3, --多段攻击
}

function XChessActor:OnInit(roleId)
    self._RoleId = roleId
    self._X = 0
    self._Y = 0
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHARACTER_TYPE.MASTER
    self._RoundCount = 1 --玩家操作回合数
    self._RoundMaxCount = 1 --最大操作回合数
    self._PassiveSkill = {} --Buff技能使用次数
    self._TargetOfAttack = {} --攻击到的对象
    self._IsRevive = false --当前回合是否复活
    self._IsTriggerProtect = false --当前回合是否触发保护技能
    self._SkillDict = {} --武器技能
    self._BuffDict = {} --生效Buff
    self._RoleSkillDict = {} --角色技能
    self._IsInvincible = false --角色无敌
    self._ContinuationRound = -1 --召唤角色持续回合
    self._BuffContinuationRound = 0 --buff增加的持续回合
    self._AddDamageByPassive = 0 --被动增加伤害，会持续整局游戏
    self._SyncPlayAnimation = asynTask(function(actionId, cb) 
        self:PlayAnimation(actionId, 0, cb)
    end)
end

function XChessActor:SetImp(imp)
    self._Imp = imp
    self:InitImp()
    self:InitData()
end

function XChessActor:InitImp()
    local checkCouldSelect = function() 
        return self:CheckCouldSelect()
    end
    self._Imp:RegisterLuaCallBack(handler(self, self.DoSelectSkill), handler(self, self.OnMovedEnd), 
            handler(self, self.OnSelect), handler(self, self.OnSkillAttack), 
            handler(self, self.OnSkillStateChanged), checkCouldSelect, handler(self, self.OnIdle))
    self._Imp:InitOnLoad(self._RoleId, self:IsSupport(), self._OwnControl:GetRoleControllerUrl(self._RoleId))
    local idleTime = self._OwnControl:GetChessGrowlsTriggerArgs(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.IdleTime, self._RoleId)
    if not XTool.IsTableEmpty(idleTime) then
        for time, _ in pairs(idleTime) do
            self._IdleInterval = time
            break
        end
        self._Imp:BeginIdle(self._IdleInterval)
    end
end

function XChessActor:ApplyBuff()
    self._BuffDict = {}
    --关卡Buff
    local buffIds = self._OwnControl:GetStageBuffIds(self._OwnControl:GetStageId())
    if not XTool.IsTableEmpty(buffIds) then
        for _, buffId in ipairs(buffIds) do
            if not self._OwnControl:GetChessGamer():CheckIsActorBuff(buffId) then
                goto continue
            end

            local buff = self._OwnControl:GetChessGamer():CreateBuff(buffId, self._Imp.Weapon)
            if not buff then
                goto continue
            end
            
            self._BuffDict[buffId] = buff
            if buff:IsEffectiveByStageInit() then
                buff:TakeEffect()
            end
            ::continue::
        end
    end
end

function XChessActor:InitData()
    --先初始化技能
    self:InitSkill()
    --在初始化Buff
    self:ApplyBuff()
end

function XChessActor:UpdateData(formation)
    if not formation then
        return
    end
    local characterInfo = formation.CharacterInfo
    self._X = formation.X
    self._Y = formation.Y
    self._MemberType = formation.Type
    self._WeaponId = characterInfo.WeaponId
    self._SummonRound = characterInfo.SummonRound
    self._SummonSkillId = characterInfo.SummonSkillId
    
    --如果是支援角色并且在场上
    if self:IsSupport() and self:IsInBoard() then
        local round = self._OwnControl:GetChessRound()
        if self._SummonRound + self._ContinuationRound == round then
            self:PlayWalkOut()
        end
    end
    local skillCdList = characterInfo.SkillCds or {}
    for _, skillCd in ipairs(skillCdList) do
        local skillId = skillCd.SkillId
        local skill = self:TryGetSkill(skillId)
        skill:UpdateData(skillCd.Cd)
    end

    local characterSkillCountDict = characterInfo.CharacterSkillCountDict or {}
    local roleSkillIds = self._OwnControl:GetRoleSkillIds(self._RoleId)
    for _, skillId in ipairs(roleSkillIds) do
        local count = characterSkillCountDict[skillId] or 0
        local skill = self:TryGetRoleSkill(skillId)
        skill:UpdateData(count)
    end
    
    --清空
    self._TargetOfAttack = {}
end

function XChessActor:Retract(formation)
    self:UpdateData(formation)
    self:InitData()
    self:Sync()
    
    self:OnEndOfTurn()
end

function XChessActor:InitSkill()
    local skillIds = self._OwnControl:GetWeaponSkillIds(self._WeaponId)
    for _, skillId in ipairs(skillIds) do
        local skill = self:TryGetSkill(skillId)
        skill:TriggerPassive(true)
    end
    
    local roleSkillIds = self._OwnControl:GetRoleSkillIds(self._RoleId)
    for _, skillId in ipairs(roleSkillIds) do
        local skill = self:TryGetRoleSkill(skillId)
        skill:SetImp(self._Imp:CreateRoleSkill(skillId, skill:GetSkillType()))
        if skill and skill:IsTriggerOnEnterFight() then
            skill:Trigger(true)
        end
    end

    if self._ContinuationRound < 0
            and XTool.IsNumberValid(self._SummonSkillId) then
        self._ContinuationRound = self:GetSummonContinuationRound(self._SummonSkillId)
    end
end

function XChessActor:TryGetSkill(skillId)
    local skill = self._SkillDict[skillId]
    if skill then
        if not skill:IsInitImp() then
            self:TrySetSkillImp(skillId)
        end
        return skill
    end
    skill = XChessSkill.New(self._OwnControl, skillId, self._RoleId)

    self._SkillDict[skillId] = skill
    self:TrySetSkillImp(skillId)
    return skill
end

function XChessActor:TrySetSkillImp(skillId)
    if not self._Imp then
        return
    end
    
    local skill = self._SkillDict[skillId]
    if not skill then
        return
    end
    local skillType = self._OwnControl:GetWeaponSkillType(skillId)
    skill:SetImp(self._Imp.Weapon:CreateSkill(skillId, skillType))
end

function XChessActor:AddSkillCost(value)
    for _, skill in pairs(self._SkillDict) do
        skill:AddSkillCost(value)
    end
end

function XChessActor:AddSkillCd(value)
    for _, skill in pairs(self._SkillDict) do
        skill:AddSkillCd(value)
    end
end

function XChessActor:IsSupport()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.ASSISTANT
end

function XChessActor:IsMaster()
    return self._MemberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER 
end

function XChessActor:IsInBoard()
    if not self._Imp then
        return false
    end
    return self._Imp.IsInBoard
end

--是否沉默攻击类的Buff
function XChessActor:IsSilentAttackedBuff()
    if not self._Imp then
        return false
    end
    if not self._Imp:IsEquipped() then
        return false
    end
    
    return self._Imp.Weapon.IsSilentAttackedBuff
end

function XChessActor:GetWeaponId()
    return self._WeaponId
end

function XChessActor:GetRoleId()
    return self._RoleId
end

--- 获取存活次数，主控角色为剩余生命，协助角色为剩余回合
---@return number
--------------------------
function XChessActor:GetSurvivalCount()
    if self:IsSupport() then
        return math.max(0, self._ContinuationRound - (self._OwnControl:GetChessRound() - self._SummonRound))
    end
    return self._OwnControl:GetGamerLeftReviveCount()
end

function XChessActor:SetInvincible(value)
    self._IsInvincible = value
end

--region   ------------------Position start-------------------

--当前移动的点位
function XChessActor:GetMovedPoint()
    if not self._Imp or not self._Imp:IsEquipped() then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.Weapon.MovedPoint
end

--当前回合初始的点位
function XChessActor:GetCurrentPoint()
    if not self._Imp or not self._Imp:IsEquipped() then
        return CS.UnityEngine.Vector2Int.zero
    end
    
    return self._Imp.Weapon.CurrentPoint
end

function XChessActor:GetRolePoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.RolePoint
end

--服务器更新的位置
function XChessActor:GetPos()
    return self._X, self._Y
end

function XChessActor:MoveTo(col, row, action)
    if not self._Imp then
        return
    end
    if not self._Imp:IsEquipped() then
        return
    end
    self._Imp:MoveTo(col, row, action)
end

--看向胜利的机位
function XChessActor:LookAtWinCamera()
    if not self._Imp then
        return
    end
    --相机看向角色
    CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:AddWinCamFollowAndLookAt(self._Imp.transform)
    --角色看向相机
    local position = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard.SceneCamera.transform.position
    self._Imp.Weapon:TurnRound(position)
end

function XChessActor:OnMovedEnd(col, row, isManual)
    if not self._Imp then
        return
    end

    -- 手动操作才记录位置
    if isManual then
        local current = self:GetCurrentPoint()
        local isRemove = col == current.x and row == current.y

        self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, isRemove, col, row, self._WeaponId, self._RoundCount)
    end

    if self._OwnControl:ContainStageBuff(XMVCA.XBlackRockChess.BuffType.StandInBlackBlock) then
        local isBlackBlock = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsBlackBlock(col, row)
        if isBlackBlock then
            self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.STAND_BLACK)
            self._Imp:LoadEffectFixedAngle(CS.XBlackRockChess.XChessBoard.XBoardEffectId.StandInBlackBlock)
        end
    end
    if self._OwnControl:ContainStageBuff(XMVCA.XBlackRockChess.BuffType.StandInWhiteBlock) then
        local isWhiteBlock = CS.XBlackRockChess.XBlackRockChessManager.Instance:IsWhiteBlock(col, row)
        if isWhiteBlock then
            self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.STAND_WHITE)
            self._Imp:LoadEffectFixedAngle(CS.XBlackRockChess.XChessBoard.XBoardEffectId.StandInWhiteBlock)
        end
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END)
end

function XChessActor:TakeBuffEffect()
    if CS.XBlackRockChess.XBlackRockChessManager.Instance.IsWin then
        return
    end
    --移除临时效果
    self._Imp:ResetBeforeUseSkill()
    --攻击前触发Buff
    for _, buff in pairs(self._BuffDict) do
        if buff and buff:IsEffectiveBeforeAttacked() then
            buff:TakeEffect()
        end
    end
end

function XChessActor:IsMoving()
    if not self._Imp then
        return false
    end
    if not self._Imp:IsEquipped() then
        return false
    end
    return self._Imp.Weapon:IsMoving()
end

--选中角色了
function XChessActor:OnSelect()
    if not self:CheckChangeRole() then
        return
    end
    self._OwnControl:GetChessGamer():UpdateSelect(self._RoleId)
    
    self:EnterMove()
    
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.FOCUS_SELECT_ACTOR, self._Imp.transform)
end

--能否选中角色
function XChessActor:CheckCouldSelect()
    if not self:IsInBoard() then
        XUiManager.TipMsg(self._OwnControl:GetOnSelectRoleTip(1))
        return false
    end

    if self:IsOperaEnd() then
        XUiManager.TipMsg(self._OwnControl:GetOnSelectRoleTip(2))
        return false
    end
    
    return true
end

--取消选中
function XChessActor:DoCancelSelect()
    if not self:IsOperaEnd() then
        self:Restore()
    end
    self._Imp:OnCancelSkill(false)
end

function XChessActor:CallCOnClick()
    if not self:CheckChangeRole() then
        return
    end
    
    if not self._Imp then
        return
    end
    self._Imp.Weapon:OnClick()
end

function XChessActor:CheckChangeRole()
    if not self._OwnControl:IsGamerRound() then
        return false
    end

    if self.IsSkillRunning then
        return false
    end

    if self._OwnControl:IsWaitingCvEnd() then
        return false
    end
    
    return true
end

function XChessActor:EnterMove()
    if not self._Imp then
        return
    end

    if not self:IsInBoard() then
        return
    end

    if self:IsMoving() then
        return
    end

    CS.XBlackRockChess.XBlackRockChessManager.Instance:EnterMove(self._Imp.Weapon)
end

function XChessActor:Revive()
    self._IsRevive = true
    --剩下复活次数
    local count = self._OwnControl:GetGamerLeftReviveCount()
    if count < 0 then
        self._OwnControl:EndGamerRound()
        return
    end
    self._Imp:Revive()
    local movePoint = self:GetMovedPoint()
    
    self._OwnControl:UpdateCondition()
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE, false, movePoint.x, movePoint.y)

    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.CheckMate, self._RoleId, 0)
end

function XChessActor:IsRevive()
    return self._IsRevive
end

function XChessActor:IsTriggerProtect()
    return self._IsTriggerProtect
end

function XChessActor:AddAction(actionType, isRemove, ...)
    local action = {
        ObjId = self._RoleId,
        ActionType = actionType,
        ObjType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER, --角色固定为1
        Params = { ... }
    }
    
    self._OwnControl:GetChessGamer():AddAction(action, isRemove)
end

--endregion------------------Position finish------------------

--region   ------------------Battle start-------------------

function XChessActor:OnCancelSkill(enterMove)
    if not self._Imp then
        return
    end
    enterMove = enterMove ~= false 
    if self:IsMoving() then
        enterMove = false
    end
    self._Imp:OnCancelSkill(enterMove)
end

function XChessActor:OnSelectSkill(skillId)
    if not self._Imp then
        return
    end
    self._Imp:OnSelectSkill(skillId)
    self:DoSelectSkill(skillId)
    
    self:DoInDanger()
end

function XChessActor:DoSelectSkill(skillId)
    self:TakeBuffEffect()
    --刷新战斗界面
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    --播放音效
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.CHANGE_PIECE_TARGET)
    local skill = self:TryGetSkill(skillId)
    if not skill or skill:IsPassive() then
        return
    end
    --一段溅射
    local sputtering = self._Imp.Sputtering
    --多段溅射
    local multiSputtering = self._Imp.MultiSputtering
    --协助溅射
    local assistSputtering = self._Imp.AssistSputtering

    local attackTimes = {}
    self:CauseDamage(skill, sputtering, attackTimes, true, false, AttackBatch.Normal)
    self:CauseDamage(skill, assistSputtering, attackTimes, true, true, AttackBatch.Assist)
    self:CauseDamage(skill, multiSputtering, attackTimes, true, false, AttackBatch.Multi)
end

function XChessActor:GetSkillDamage(skillId, isCenter, isExtraTurn, isAssist, isMulti)
    --纯技能伤害
    local damage = self:TryGetSkill(skillId):GetDamage(isCenter, isExtraTurn, isAssist, isMulti)
    --buff增伤
    for id, count in pairs(self._PassiveSkill) do
        local type = self._OwnControl:GetWeaponSkillType(id)
        if type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL1 then
            local params = self._OwnControl:GetWeaponSkillParams(id)
            local addDamage = params[2] * count
            damage = damage + addDamage
        end
    end
    --站格子增伤
    local blockAdd = 0
    --协助角色不增伤
    if self._Imp and not isAssist then
        blockAdd = self._Imp.Weapon.BlockDpsAdd
    end
    local passiveAdd = 0
    if not isAssist then
        passiveAdd = self._AddDamageByPassive
    end
    --被动增伤
    damage = damage + passiveAdd + blockAdd

    return math.max(0, damage)
end

function XChessActor:UseWeaponSkill(skillId)
    if not self._OwnControl:CouldUseSkill(self._RoleId, skillId) then
        return false
    end
    self.IsSkillRunning = true
    local skill = self:TryGetSkill(skillId)
    self._OwnControl:ConsumeEnergy(self._RoleId, skillId)
    --小刀被动技能
    if skill:IsPassive() then
        self:UsePassiveSkill(skill)
        return false
    end
    self:UseActiveSkill(skill)
    --移除被动技能效果
    self:ResetSkill()

    --操作还未结束
    if not self:IsOperaEnd() then
        return false
    end
    return true
end

--- 使用被动技能(Buff技能)
---@param skill XChessSkill
---@return
--------------------------
function XChessActor:UsePassiveSkill(skill)
    local params = self._OwnControl:GetWeaponSkillParams(skill:GetId())
    local addMoveRange = params[1]
    skill:AddMoveRange(addMoveRange)
    local useCount = self._PassiveSkill[skill:GetId()] or 0
    useCount = useCount + 1
    
    self._PassiveSkill[skill:GetId()] = useCount
    self._Imp:UsePassiveSkill(skill:GetId())
    skill:DoUse()
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PASSIVE_SKILL, false, skill:GetId(), useCount, self._RoundCount)
end

--- 使用主动技能
---@param skill XChessSkill
---@return
--------------------------
function XChessActor:UseActiveSkill(skill)
    --攻击点中心
    local aim = skill:GetShotCenter()
    self._ShotCenter = aim
    --技能溅射
    local sputtering = self._Imp.Sputtering
    --多段溅射
    local multiSputtering = self._Imp.MultiSputtering
    --协助溅射
    local assistSputtering = self._Imp.AssistSputtering
    local attackInfo = {}
    --攻击对象
    self._TargetOfAttack = {}
    local skillId = skill:GetId()
    self:TakeBuffEffect()
    -- 攻击前需要触发
    self._Imp:OnUseBeforeDamage(skillId)
    --正式攻击
    local isAttack = self:CauseDamage(skill, sputtering, attackInfo, false, false, AttackBatch.Normal)
    --协助攻击
    self:CauseDamage(skill, assistSputtering, attackInfo, false, true, AttackBatch.Assist)
    --多段伤害
    local isAttackMulti = self:CauseDamage(skill, multiSputtering, attackInfo, false, false, AttackBatch.Multi)
    --使用技能
    self._Imp:UseActiveSkill(skillId)
    if not self:IsSupport() then
        --协助者位置
        local assistActor = self._OwnControl:GetChessGamer():GetRole(self._OwnControl:GetAssistantRoleId())
        local assistPoint = assistActor:GetRolePoint()
        local summonPoint = assistActor:GetCurrentPoint()
        self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK, false, self._WeaponId,
                skillId, aim.x, aim.y, self._RoundCount, assistPoint.x, assistPoint.y, summonPoint.x, summonPoint.y)
    else
        self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK, false, self._WeaponId, skillId, 
                aim.x, aim.y, self._RoundCount, 0, 0, 0, 0, self._OwnControl:GetMasterRoleId())
    end
    skill:DoUse()
    --触发技能被动效果
    skill:TriggerPassive()
    if (isAttack or isAttackMulti) and skill:IsExtraTurn(self._RoundCount) then
        self:AddMaxRoundCount()
    end
    self:AddRoundCount()
end

--- 预览/造成伤害
---@param skill XChessSkill
---@param list System.Collections.Generic
---@param attackInfo table<number, number>
---@param isPreview boolean
---@param isAssist boolean 是否为支援
---@param batch number 伤害批次，伤害可能是多段，每段敌人不同
---@return boolean 是否攻击到敌人,对预览不生效
--------------------------
function XChessActor:CauseDamage(skill, list, attackInfo, isPreview, isAssist, batch)
    if not list then
        return false
    end
    --攻击点中心
    local aim = skill:GetShotCenter()
    --是否为额外回合
    local isExtraTurn = self:IsExtraTurn()
    --角色所站位置
    local actorPoint = self:GetMovedPoint()
    --该批次攻击到棋子
    local attackPieces = {}
    local isAttack = false
    local count = list.Count
    if isPreview then
        local piece = self._OwnControl:PieceAtCoord(aim)
        --中心点有地方棋子
        if piece and piece.IsPiece and piece:IsPiece() then
            self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.FOCUS_ENEMY, piece:GetId())
        end
    end
    local convertKey = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Int
    for i = 0, count - 1 do
        local point = list[i]
        local piece = self._OwnControl:PieceAtCoord(point)
        local pointKey = convertKey(point.x, point.y)
        local info = attackInfo[pointKey]
        --当前回合被攻击的次数
        local attackTime
        --判断是否为无敌
        local isInvincible

        --是否为攻击中心点
        local isCenter = CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(point, aim)
        --当次技能造成的伤害
        local damage = self:GetSkillDamage(skill:GetId(), isCenter, isExtraTurn, isAssist, batch == AttackBatch.Multi)
        --显示在地板上的伤害
        local displayDamage = damage + (info and info.DisplayDamage or 0)
        --实际造成的伤害
        local actualDamage = 0
        
        if not piece or not piece.IsPiece or not piece:IsPiece() then
            attackTime = info and info.AttackTimes or 0
        else
            attackTime = math.max(info and info.AttackTimes or 0,  piece:GetAttackTimes())
            local isInvincible = piece:IsInvincible(self._RoleId, attackTime)
            if isPreview then
                piece:LookAt(actorPoint.x, actorPoint.y)
                actualDamage = (isInvincible and 0 or damage) + (info and info.ActualDamage or 0)
                self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.PREVIEW_DAMAGE, piece:GetId(), actualDamage)
            else
                actualDamage = isInvincible and 0 or damage
                local attacked = piece:AttackEd(actualDamage, skill:IsDizzy(), false, self._RoleId, self._RoundCount)
                isAttack = isAttack or attacked
            end
        end

        --攻击次数+1
        attackTime = attackTime + 1
        attackInfo[pointKey] = {
            DisplayDamage = displayDamage,
            AttackTimes = attackTime,
            ActualDamage = actualDamage,
        }
        --加入攻击到的坐标
        attackPieces[pointKey] = point
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ShowDpsOnGrid(point.x, point.y, displayDamage)
    end
    
    self._TargetOfAttack[batch] = attackPieces
    
    return isAttack
end

--- 召唤支援
---@param skillId number 技能Id
--------------------------
function XChessActor:SummonAssistant(skillId)
    if not self._Imp then
        return
    end
    local callerId = self._OwnControl:GetWeaponSkillAssistRoleId(skillId)
    if not XTool.IsNumberValid(callerId) then
        XLog.Warning("当前技能不支持召唤，SkillId = " .. skillId)
        return
    end
    local actor = self._OwnControl:GetChessGamer():GetRole(callerId)
    if not actor then
        XLog.Warning("不存在支援角色, RoleId = " .. callerId)
        return
    end
    local continuationRound = self:GetSummonContinuationRound(skillId)
    actor:PlaySummon(continuationRound)
end

function XChessActor:PlaySummon(continuationRound)
    if not self._Imp then
        return
    end
    for _, skill in pairs(self._SkillDict) do
        skill:OnSummon()
    end
    self._ContinuationRound = continuationRound
    self._SummonRound = self._OwnControl:GetChessRound()
    self._Imp:PlaySummon()
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_SELECT_ROLE, self._RoleId)
end

function XChessActor:PlayWalkOut()
    if not self._Imp then
        return
    end
    self._ContinuationRound = 0
    local x, y = self._OwnControl:GetMemberInitPos(self._RoleId)
    self._Imp:DoWalkOut(x, y)
end

--获取召唤出来的角色持续回合 = 技能默认 + 全局被动增加
function XChessActor:GetSummonContinuationRound(skillId)
    local skill = self:TryGetSkill(skillId)
    local callerId = self._OwnControl:GetWeaponSkillAssistRoleId(skillId)
    local actor = self._OwnControl:GetChessGamer():GetRole(callerId)
    local buffCount = actor:GetBuffContinuationRound()
    
    return skill:GetSummonContinuationRound() + buffCount
end

function XChessActor:SetBuffContinuationRound(value)
    self._BuffContinuationRound = value
end

function XChessActor:GetBuffContinuationRound()
    return self._BuffContinuationRound
end

--- 保护免受攻击
---@param skillId number 技能Id
---@param roleId number 保护[我]的角色Id
---@param piece XBlackRockChessPiece 攻击棋子
---@return
--------------------------
function XChessActor:Protect(skillId, roleId, piece)
    self._IsTriggerProtect = true
    --设置为无敌
    self:SetInvincible(true)
    local movePoint = self:GetMovedPoint()
    local originPoint = piece:GetMovedPoint()
    
    local syncJump = asynTask(function(cb)
        local onJumpComplete = function()
            local skill = self:TryGetRoleSkill(skillId)
            piece:AttackEd(skill:GetDamage(), false, true, roleId, 0)
            if cb then cb() end
        end
        local oldPoint = piece:GetMovedPoint()
        CS.XBlackRockChess.XBlackRockChessManager.Instance:RemovePiece(oldPoint, false)
        piece:JumpTo(movePoint.x, movePoint.y, nil, onJumpComplete)
    end)
    
    local syncPlay = asynTask(function(cb)
        self._OwnControl:GetChessGamer():GetRole(roleId):PlayProtect(self._RoleId, skillId, movePoint.x, movePoint.y,
                cb)
    end)
    
    --跳到目标角色头上
    syncJump()
    --保护角色表演
    syncPlay()
    --棋子死亡
    piece:OnSkillHitManual(self._OwnControl:GetLuciaBeheadedEffectId(1))
    
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_SKILL, false, originPoint.x, originPoint.y, skillId, roleId)
end
 
function XChessActor:PlayProtect(roleId, skillId, x, y, cb)
    if not self._Imp then
        return
    end
    self._Imp.Weapon:TurnRound(x, y)
    self._Imp:PlayProtect(roleId, skillId, cb)
end

--- 技能攻击到敌人
---@param skillId number 技能Id
---@param batch number 技能伤害批次
--------------------------
function XChessActor:OnSkillAttack(skillId, batch)
    if XTool.IsTableEmpty(self._TargetOfAttack) then
        return
    end
    --当前批次攻击到位置不为空
    local attackPieces = self._TargetOfAttack[batch]
    if XTool.IsTableEmpty(attackPieces) then
        return
    end
    --攻击到的位置不为空
    local isAssist = batch == AttackBatch.Assist
    local hitEffectIds = self._OwnControl:GetWeaponHitEffectIds(skillId, isAssist)
    if XTool.IsTableEmpty(hitEffectIds) then
        hitEffectIds = { 0 }
    end
    local hitFrom = self:GetAttackFrom(isAssist)
    for pointKey, point in pairs(attackPieces) do
        for _, effectId in ipairs(hitEffectIds) do
            self:ShowHitEffect(pointKey, point, effectId, hitFrom, isAssist)
        end
    end
end

function XChessActor:GetAttackFrom(isAssist)
    if not isAssist then
        return self:GetMovedPoint()
    end
    local roleId = self._OwnControl:GetAssistantRoleId()
    local actor = self._OwnControl:GetChessGamer():GetRole(roleId)
    
    return actor:GetRolePoint()
end

--- 技能攻击到敌人之后执行的逻辑
---@param skillId number
--------------------------
function XChessActor:AfterSkillAttack(skillId)
    local skill = self:TryGetSkill(skillId)
    local skillType = skill:GetSkillType()

    --召唤协助
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3 then
        self:SummonAssistant(skillId)
    end
end

--- 技能帧事件状态变化
---@param value boolean true: 技能开始释放，false ,技能释放完
--------------------------
function XChessActor:OnSkillStateChanged(skillId, value)
    if value then
        self._OwnControl:AddWaitCount()
    else
        self._OwnControl:SubWaitCount()
    end
    self.IsSkillRunning = value
end

function XChessActor:CheckIsSkillRunning()
    return self.IsSkillRunning
end

--- 被敌人瞄准了
--------------------------
function XChessActor:DoInDanger()
    if not self._Imp then
        return
    end
    if not self._Imp:CheckInDanger() then
        return
    end
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER, 
            XMVCA.XBlackRockChess.GrowlsTriggerType.SelectSkillInDanger, self._RoleId, 0)
end

--- 发呆未操作
--------------------------
function XChessActor:OnIdle()
    if not self._IdleInterval or self._IdleInterval <= 0 then
        return
    end
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.IdleTime, self._RoleId, self._IdleInterval)
end

--- 棋子受击表现
---@param pointKey number
---@param point UnityEngine.Vector2Int
---@param effectId number 特效Id
---@param hitFrom UnityEngine.Vector2Int 攻击者位置
--------------------------
function XChessActor:ShowHitEffect(pointKey, point, effectId, hitFrom, isAssist)
    if XTool.IsNumberValid(effectId) then
        local rotate
        if CS.XBlackRockChess.XBlackRockChessUtil.IsDirection(effectId) then
            rotate = CS.XBlackRockChess.XBlackRockChessUtil.CalCoordinateRotate(hitFrom, point)
            --有方向的特效需要对齐方向
            rotate.y = rotate.y + CS.XBlackRockChess.XBlackRockChessUtil.GetEffectInitAngle(effectId)
        else
            rotate =  CS.UnityEngine.Vector3.zero
        end
        local offset = CS.UnityEngine.Vector3.zero
        CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:LoadGridEffect(pointKey, effectId, offset, rotate)
    end
    local piece = self._OwnControl:PieceAtCoord(point)
    if piece and piece.IsPiece and piece:IsPiece() then
        piece:OnSkillHit()
    end
    if isAssist then
        self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.THUNDER_BREAK)
    end
    
end

function XChessActor:IsUsePassiveSkill()
    return not XTool.IsTableEmpty(self._PassiveSkill)
end

function XChessActor:TryGetRoleSkill(roleSkillId)
    local skill = self._RoleSkillDict[roleSkillId]
    if skill then
        return skill
    end
    
    local type = self._OwnControl:GetRoleSkillType(roleSkillId)
    if type == XMVCA.XBlackRockChess.RoleSkillType.LunaProtect then
        skill = XLunaProtectedSkill.New(self._OwnControl, roleSkillId, self._RoleId)
    elseif type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddDps 
            or type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddMove 
            or type == XMVCA.XBlackRockChess.RoleSkillType.LunaHyperAddRange 
    then
        skill = XLunaHyperPassive.New(self._OwnControl, roleSkillId, self._RoleId)
    end

    self._RoleSkillDict[roleSkillId] = skill
    
    return skill
end

--- 被攻击, 为了保证调用顺序，需要在RunAsync中执行
---@param piece XBlackRockChessPiece
---@param syncMove function 同步移动函数
---@return
--------------------------
function XChessActor:AsyncAttacked(piece, syncMove)
    for _, skill in pairs(self._RoleSkillDict) do
        if skill:IsTriggerOnAttacked() then
            skill:Trigger(piece)
        end
    end
    --无敌
    if self._IsInvincible then
        return
    end
    --被击杀
    syncMove(piece, self:GetMovedPoint(), true)
    --展示CheckMate
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_CHECK_MATE, true)
    self._SyncPlayAnimation("Defeated")
    --标记复活
    self._OwnControl:GetChessGamer():Revive(self._RoleId)
    self._SyncPlayAnimation("Fall")
    self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_CHECK_MATE, false)
end

--增加射程
function XChessActor:AddShotRange(value)
    if not self._Imp or not self._Imp:IsEquipped() then
        return
    end
    self._Imp.Weapon:SetShotRange(value)
end

--增加移动距离
function XChessActor:AddMoveRange(value)
    if not self._Imp or not self._Imp:IsEquipped() then
        return
    end
    self._Imp.Weapon:SetMoveRange(value)
end

--增加被动伤害
function XChessActor:AddDamage(value)
    self._AddDamageByPassive = value
end

function XChessActor:DispatchBuff(skillId, value)
    if not self._Imp then
        return
    end
    if value > 0 then
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.SHOW_BUFF_HUD, self._RoleId,
                self._Imp.transform, skillId, value)
    else
        self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_BUFF_HUD, self._RoleId, skillId)
    end
end
--endregion------------------Battle finish------------------

--region   ------------------ExtraRound start-------------------

--角色回合操作结束
function XChessActor:AddRoundCount()
    self._RoundCount = self._RoundCount + 1
    self:UpdateRoundCount()
end

--玩家整体回合结束
function XChessActor:ResetRoundCount()
    self._RoundCount = 1
    self._RoundMaxCount = 1
    self:UpdateRoundCount()
end

--更新角色回合
function XChessActor:UpdateRoundCount()
    if self._Imp then
        self._Imp.RoundCount = self._RoundCount
    end
    self._OwnControl:UpdateIsExtraRound(self:IsExtraTurn())
end

--操作是否结束
function XChessActor:IsOperaEnd()
    return self._RoundCount > self._RoundMaxCount
end

function XChessActor:IsExtraTurn()
    return self._RoundCount > 1 and self._RoundMaxCount > 1
end

--添加额外回合
function XChessActor:AddMaxRoundCount()
    self._RoundMaxCount = self._RoundMaxCount + 1
    self._OwnControl:UpdateIsExtraRound(self:IsExtraTurn())
    self._OwnControl:GetChessGamer():TempSync()
end

--endregion------------------ExtraRound finish------------------


--region   ------------------Effect start-------------------

--加载特效
function XChessActor:LoadEffect(effectId, offset, rotate, isBindRole)
    offset = offset or CS.UnityEngine.Vector3.zero
    rotate = rotate or CS.UnityEngine.Vector3.zero
    isBindRole = isBindRole or false
    self._Imp.Weapon:LoadEffect(effectId, offset, rotate, isBindRole)
end

function XChessActor:ShowBubbleText(text)
    if not self._Imp then
        return
    end
    self._OwnControl:ShowBubbleText(self._Imp, text)
end

--endregion------------------Effect finish------------------

--region   ------------------Animation start-------------------

function XChessActor:DoCommonWait(cb)
    if not self._Imp then
        if cb then cb(false) end
    end
    local newCb = function()
        if self._OwnControl then
            self._OwnControl:SubWaitCount()
        end
        if cb then cb() end
    end
    self._OwnControl:AddWaitCount()
    
    return newCb
end

function XChessActor:PlayAnimation(actionId, crossTime, cb)
    local newCb = self:DoCommonWait(cb)
    crossTime = crossTime or 0
    self._Imp:PlayAnimation(actionId, crossTime, newCb)
end

function XChessActor:PlayTimeline(actionId, cb)
    local newCb = self:DoCommonWait(cb)
    self._Imp:PlayTimelineAnimation(actionId, newCb)
end

--endregion------------------Animation finish------------------


--region   ------------------Sync-Restore start-------------------

function XChessActor:TempSync()
    local movePoint = self:GetMovedPoint()
    self._X, self._Y = movePoint.x, movePoint.y
    self:Sync()
end

function XChessActor:Sync()
    if not self._Imp or not self._Imp:IsEquipped() then
        return
    end
    self._Imp.Weapon:Sync(self._X, self._Y)
    self:ResetSkill()
    self._IsRevive = false
    self._IsTriggerProtect = false
end

function XChessActor:Restore()
    if not self._Imp or not self._Imp:IsEquipped() then
        return
    end

    self._Imp.Weapon:Restore(self._X, self._Y)
    self:ResetSkill()
    self._IsRevive = false
    self._IsTriggerProtect = false
end

function XChessActor:ResetSkill()
    self._PassiveSkill = {}
    if self._Imp and self._Imp:IsEquipped() then
        self._Imp.Weapon:ResetSkill()
    end
    --self._OwnControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.HIDE_BUFF_HUD, self._RoleId)
end

function XChessActor:OnEndOfTurn()
    self:ResetRoundCount()
    self:ResetSkill()
    self:SetInvincible(false)
end

function XChessActor:OnForceEndOfTurn()
    self:OnEndOfTurn()
    if self:IsInBoard() then
        self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND, false, self._WeaponId)
    end
end

function XChessActor:OnRelease()
    self._Imp = nil
    self._TargetOfAttack = nil
    self._X = 0
    self._Y = 0
    self._IsRevive = false
    self._IsTriggerProtect = false

    for _, skill in pairs(self._SkillDict) do
        skill:OnRelease()
    end
    self._SkillDict = nil
    self:ResetSkill()
    self:ResetRoundCount()
end

function XChessActor:DoWin(targetConditionId)
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.OnWin, self:GetRoleId(), targetConditionId)
end

--endregion------------------Sync-Restore finish------------------

return XChessActor