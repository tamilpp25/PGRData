---@class XChessActor : XEntity 玩家角色
---@field _Imp XBlackRockChess.XChessRole
---@field _OwnControl XBlackRockChessControl
---@field _TargetOfAttack table<number, UnityEngine.Vector2Int> 攻击到的地板
---@field _SkillDict table<number, XChessSkill> 技能
---@field _RoleSkillDict table<number, XRoleSkill> 被动技能
---@field _BuffDict table<number, XBlackRockChess.XBuff> 技能
---@field _BlendBuffDict table<number, XBlackRockChess.XBuff> 融合buff
---@field _DefenseInfo DefenseInfo
---@field _BlendPieceId number 被附身的友方棋子Id
---@field _InjuryFreeTimes number 附身buff提供的免疫伤害次数
local XChessActor = XClass(XEntity, "XChessActor")

local XChessSkill = require("XModule/XBlackRockChess/XGameObject/XChessSkill")

local XLunaProtectedSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XLunaProtectedSkill")
local XLunaHyperPassive = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XLunaHyperPassive")
local XVeraHyperPassive = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XVeraHyperPassive")

local AttackBatch = {
    Assist = 1, --协助攻击
    Normal = 2, --正常攻击
    Multi  = 3, --多段攻击
}

local VeraWarnEffecOffset = CS.UnityEngine.Vector3(0, 0.1, 0)

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
    self._BlendBuffDict = {}
    self._RoleSkillDict = {} --角色技能
    self._IsInvincible = false --角色受保护无敌（废弃 现在没有支援角色）
    self._ContinuationRound = -1 --召唤角色持续回合
    self._BuffContinuationRound = 0 --全局buff增加的持续回合
    self._AddDamageByPassive = 0 --被动增加伤害，会持续整局游戏
    self._AddRoundDamageByPassive = 0 --大招被动增加伤害 仅持续一回合
    self._AddRoundCost = 0 --大招被动增加能量消耗 仅持续一回合
    self._DefenseInfo = nil --格挡信息
    self._SyncPlayAnimation = asynTask(function(actionId, cb) 
        self:PlayAnimation(actionId, 0, cb)
    end)
    self._PreviewLines = {}
    self._OffsetMap = {}
    self._RotateMap = {}
end

function XChessActor:SetImp(imp)
    self._Imp = imp
    self:UpdateModelByEnergy()
    self:InitImp()
    self:UpdateSkillData()
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
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_SELECT_ACTOR, self._Imp.transform)
end

--region buff

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
                buff:DoTakeEffect()
            end
            ::continue::
        end
    end
end

---融合buff（不会重复触发）
function XChessActor:ApplyBlendBuff()
    if not XTool.IsNumberValid(self._BlendPieceId) then
        return
    end

    ---@type XBlackRockChessPartnerPiece
    local piece = self._OwnControl:GetChessPartner():GetPieceInfo(self._BlendPieceId)
    local buffIds = piece:GetBlendBuffIds()
    
    for _, buffId in pairs(buffIds) do
        local buffType = self._OwnControl:GetBuffType(buffId)
        ---@type XBlackRockChess.XBuff
        local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
        if buff then
            local args = self._OwnControl:GetBuffParams(buffId)
            self._BlendBuffDict[buffId] = buff
            buff:DoApply(buffId, nil, table.unpack(args))
            buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))
            buff:DoTakeEffect()
        end
    end

    local pieceType = self._OwnControl:GetPartnerPieceType(piece:GetConfigId())
    if pieceType == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.BISHOP then
        --附身主教后 国王会立即销毁
        self:BlendPartnerDestory()
    elseif pieceType == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KNIGHT then
        --附身骑士后 需要传二次移动事件
        local point = piece:GetMovedPoint()
        self:AddBlendAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, point.x, point.y, self._WeaponId, 1)
    end

    self:BlendBuffLose()
end

function XChessActor:GetBlendPieceType()
    if not XTool.IsNumberValid(self._BlendPieceId) then
        return nil
    end
    ---@type XBlackRockChessPartnerPiece
    local piece = self._OwnControl:GetChessPartner():GetPieceInfo(self._BlendPieceId)
    return self._OwnControl:GetPartnerPieceType(piece:GetConfigId())
end

function XChessActor:OnBuffTakeEffect(args)
    local buffId = args[0]
    local basePiece = self._OwnControl:GetChessPartner():GetPieceInfo(self._BlendPieceId)
    self._OwnControl:OnBuffTakeEffect(args, self._BlendBuffDict[buffId], basePiece)
end

function XChessActor:SetInjuryFreeTimes(value)
    self._InjuryFreeTimes = value
end

---附身buff失效
function XChessActor:BlendBuffLose()
    local imp = self._BlendBuffDict[self._BlendPieceId]
    if imp then
        imp:Release()
    end
    self._BlendBuffDict[self._BlendPieceId] = nil
end

---销毁附身的友方棋子
function XChessActor:BlendPartnerDestory()
    if not self._BlendPieceId then
        return
    end
    --self._OwnControl:GetChessPartner():RecyclePiece(self._BlendPieceId)
    local piece = self._OwnControl:GetChessPartner():GetPieceInfo(self._BlendPieceId)
    piece:SetHp(0)
    piece:DoDead()
end

function XChessActor:RemoveBlendBuff()
    for _, imp in pairs(self._BlendBuffDict) do
        imp:Release()
    end
    self._BlendBuffDict = {}
    self._BlendPieceId = nil
    self._InjuryFreeTimes = 0
end

---受击时触发buff
---@return boolean 角色是否无敌
function XChessActor:TriggerAttackedBuff(attackTimes)
    local isInvincible = false
    for _, buff in pairs(self._BuffDict) do
        --被攻击时生效(主动)
        if buff:IsEffectiveByAttacked() then
            --触发每个buff
            buff:DoTakeEffect()
            if buff:CheckIsImmuneInjury(attackTimes) then
                isInvincible = true
            end
        end
    end
    return isInvincible
end

--endregion

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
    self._CharacterInfo = formation.CharacterInfo
    self._X = formation.X
    self._Y = formation.Y
    self._MemberType = formation.Type
    self:UpdateModelByEnergy()
    if self._Imp then
        self:UpdateSkillData()
    end
    --清空
    self._TargetOfAttack = {}
end

function XChessActor:UpdateSkillData()
    local characterSkillDict = self._CharacterInfo.WeaponSkillDict or {}
    local skillCdList = self._CharacterInfo.SkillCds or {}
    for _, skillCd in ipairs(skillCdList) do
        -- 共享Cd
        local skillIds = self._OwnControl:GetWeaponSkillById(skillCd.Id).SkillIds
        for _, skillId in pairs(skillIds) do
            local skill = self:TryGetSkill(skillId)
            local times = characterSkillDict[skillId] and characterSkillDict[skillId].Count or 0
            skill:UpdateData(skillCd.Cd, times)
            skill:TriggerPassive(true)
        end
    end

    local characterSkillCountDict = self._CharacterInfo.SkillCountDict or {}
    local roleSkillIds = self._OwnControl:GetRoleSkillIds(self._RoleId)
    for _, skillId in ipairs(roleSkillIds) do
        local count = characterSkillCountDict[skillId] or 0
        local skill = self:TryGetRoleSkill(skillId)
        if skill then
            skill:UpdateData(count)
        end
    end
end

function XChessActor:Retract(formation)
    self:UpdateData(formation)
    self:InitData()
    self:Sync()
    
    self:OnEndOfTurn()
end

function XChessActor:InitSkill()
    -- 技能的被动
    local normalWeapon = XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.VERA_NORMAL
    for _, skillId in ipairs(self._OwnControl:GetWeaponSkillIds(normalWeapon)) do
        local skill = self:TryGetSkill(skillId)
        skill:TriggerPassive(true)
    end
    local redModelWeapon = XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.VERA_REDMODEL
    for _, skillId in ipairs(self._OwnControl:GetWeaponSkillIds(redModelWeapon)) do
        local skill = self:TryGetSkill(skillId)
        skill:TriggerPassive(true)
    end
    -- 角色的被动
    local roleSkillIds = self._OwnControl:GetRoleSkillIds(self._RoleId)
    for _, skillId in ipairs(roleSkillIds) do
        local skill = self:TryGetRoleSkill(skillId)
        if skill then
            skill:SetImp(self._Imp:CreateRoleSkill(skillId, skill:GetSkillType()))
            if skill:IsTriggerOnEnterFight() then
                skill:Trigger(true)
            end
        end
    end
end

---@return XChessSkill
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
    local weapon = self._Imp.NormalWeapon
    local skillType = self._OwnControl:GetWeaponSkillType(skillId)
    local weaponType = self._OwnControl:GetWeaponTypeBySkillId(skillId)
    if weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.VERA_REDMODEL then
        weapon = self._Imp.RedModelWeapon
    end
    skill:SetImp(weapon:CreateSkill(skillId, skillType))
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
        return math.max(0, self._ContinuationRound - self._OwnControl:GetChessRound())
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

--技能表现期间屏蔽玩家操作角色移动
function XChessActor:SetForceExitMove(bo)
    self._IsForceDontMove = bo
end

function XChessActor:OnMovedEnd(col, row, isManual)
    if not self._Imp then
        return
    end

    local current = self:GetCurrentPoint()
    local isRemove = col == current.x and row == current.y
    
    -- 手动操作才记录位置
    if isManual then
        -- 薇拉大招有位移 但是不需要发送移动事件
        if self._CurUsedSkillType ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
            self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, isRemove, col, row, self._WeaponId, 1)
        end
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

    self:UpdateBlendPiece()
    -- 角色移动回原地 不会再次触发附身buff
    if isRemove then
        self._BlendPieceId = nil
    end

    if self._IsForceDontMove then
        CS.XBlackRockChess.XBlackRockChessManager.Instance:ExitMove()
    end

    if self._OwnControl:IsEnterRedModel() then
        self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.TELEPOR_MOVE)
    else
        self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.JUMP_MOVE)
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END)
end

---附身友方棋子
---@param isCheckBorn boolean 检查是否附身在本回合转实体的友方上
function XChessActor:UpdateBlendPiece(isCheckBorn)
    ---@type XBlackRockChessPartnerPiece
    local piece
    local pieceGuid
    local piece = self._OwnControl:GetChessPartner():GetPieceAtCoord(self:GetMovedPoint())
    if piece and piece:IsAlive() then
        pieceGuid = piece:GetId()
        if not piece:IsVirtual() and (not isCheckBorn or piece:GetPartnerBornCd() == -1) then
            self:PlayAnimation("Mix")
            self:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_BLEND)
        end
    end
    
    if pieceGuid ~= self._BlendPieceId then
        self:RemoveBlendBuff()
        --虚影不会有附身buff
        if piece and not piece:IsVirtual() then
            self._BlendPieceId = pieceGuid
            self._OwnControl:GetChessGamer():ApplyBlendBuffBefore()
        end
    end

    local partners = self._OwnControl:GetChessPartner():GetPieceInfoDict()
    for id, piece in pairs(partners) do
        if piece:IsAlive() then
            local isPossessed = id == pieceGuid
            piece:SetPossessed(isPossessed)
            if not isPossessed then
                piece:UpdatePreview()
                self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, id, piece:GetIconFollow())
            end
        end
    end
    
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_POSSESS, self._BlendPieceId)
end

function XChessActor:IsBlendPieceId()
    return self._BlendPieceId ~= nil
end

function XChessActor:GetBlendPieceId()
    return self._BlendPieceId
end

function XChessActor:TakeBuffEffect()
    if CS.XBlackRockChess.XBlackRockChessManager.Instance.IsWin then
        return
    end
    --移除临时效果
    self._Imp:ResetBeforeUseSkill()
    --攻击前触发Buff
    for _, buff in pairs(self._BuffDict) do
        -- 攻击者攻击之前
        if buff and buff:IsEffectiveBeforeAttacked() then
            buff:DoTakeEffect()
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
    
    -- 处于备战界面时屏蔽角色移动
    if not self._OwnControl:GetChessPartner():IsPassPreparationStage() then
        return
    end
    
    self._OwnControl:GetChessGamer():UpdateSelect(self._RoleId)
    
    self:EnterMove()
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_PLAYER)
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

function XChessActor:EnterMoveAgain()
    if not self._Imp then
        return
    end

    if not self:IsInBoard() then
        return
    end

    if self:IsMoving() then
        return
    end

    CS.XBlackRockChess.XBlackRockChessManager.Instance:EnterMoveAgain(self._Imp.Weapon)
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
    self._Imp.Weapon.CurrentPoint = movePoint
    self:UpdateBlendPiece()
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

function XChessActor:CreateAction(actionType, ...)
    return {
        ObjId = self._RoleId,
        ActionType = actionType,
        ObjType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER, --角色固定为1
        Params = { ... }
    }
end

function XChessActor:AddAction(actionType, isRemove, ...)
    local action = self:CreateAction(actionType, ...)
    self._OwnControl:GetChessGamer():AddAction(action, isRemove)
end

function XChessActor:AddBlendAction(actionType, ...)
    local action = self:CreateAction(actionType, ...)
    self._OwnControl:GetChessGamer():AddBlendSpecialAction(actionType, action)
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
    self:RecyclePreviewWarnLine()
    self:HideVeraWarnEffect()
end

function XChessActor:OnSelectSkill(skillId)
    if not self._Imp then
        return
    end
    self._Imp:OnSelectSkill(skillId)
    self:DoSelectSkill(skillId)
    
    self:DoInDanger()
end

function XChessActor:ShowPreviewWarnLine()
    --检查被瞄准的敌人死亡后 其他棋子是否能攻击到角色
    local lineInfoDict = {}
    local enemys = self._OwnControl:GetChessEnemy():GetPieceInfoDict()
    for _, pieceInfo in pairs(enemys) do
        if pieceInfo:IsAlive() and not pieceInfo:IsPreviewDead() and not pieceInfo:IsVirtual() and pieceInfo:IsAttackActorPreview(self:GetMovedPoint()) then
            table.insert(lineInfoDict, pieceInfo:GetMovedPoint())
            pieceInfo:Prepare4Attack()
        end
    end
    for _, startPos in pairs(lineInfoDict) do
        local line = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:GenerateLineRender(2, startPos, self:GetMovedPoint())
        table.insert(self._PreviewLines, line)
    end
end

function XChessActor:RecyclePreviewWarnLine()
    for _, line in pairs(self._PreviewLines) do
        CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:RecycleLineRender(2, line)
    end
    self._PreviewLines = {}
end

---@param skill XChessSkill
function XChessActor:ShowVeraWarnEffect(skill)
    self:HideVeraWarnEffect()
    local skillType = skill:GetSkillType()
    if skillType ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        return
    end

    local shotCenter = skill:GetShotCenter()
    local enemys = self._OwnControl:GetChessEnemy():GetPieceInfoDict()
    for _, pieceInfo in pairs(enemys) do
        if pieceInfo:IsAlive() and not pieceInfo:IsPreviewDead() and not pieceInfo:IsVirtual() and pieceInfo:IsAttackPointPreview(shotCenter) and not pieceInfo:IsPieceNoAttack() then
            self:SetVeraWarnEffect(shotCenter)
            return
        end
    end
    
    local bosses = self._OwnControl:GetChessEnemy():GetBossInfoDict()
    for _, bossInfo in pairs(bosses) do
        if bossInfo:CheckAttackPoint(shotCenter) then
            self:SetVeraWarnEffect(shotCenter)
            return
        end
    end
end

function XChessActor:SetVeraWarnEffect(shotCenter)
    local ChessBoard = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard
    local pointKey = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Int(shotCenter.x, shotCenter.y)
    if XTool.UObjIsNil(self._VeraWarnEffect) then
        self._VeraWarnEffect = ChessBoard:LoadGridEffect(pointKey, XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.DANGER_EFFECT, VeraWarnEffecOffset, CS.UnityEngine.Vector3.zero)
    else
        local world = CS.XBlackRockChess.XBlackRockChessUtil.Convert2WorldPoint(pointKey)
        self._VeraWarnEffect.gameObject:SetActiveEx(true)
        self._VeraWarnEffect.localPosition = VeraWarnEffecOffset + ChessBoard.PathRoot:InverseTransformPoint(world)
    end
end

function XChessActor:HideVeraWarnEffect()
    if XTool.UObjIsNil(self._VeraWarnEffect) then
        return
    end
    self._VeraWarnEffect.gameObject:SetActiveEx(false)
end

function XChessActor:DoSelectSkill(skillId)
    self:TakeBuffEffect()
    --刷新战斗界面
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
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

---@param isCenter boolean 是否为攻击中心点
---@param isExtraTurn boolean 是否为额外回合
---@param isAssist boolean 是否为支援
---@param isMulti boolean 是否为多段攻击
---@param isHypotenuse boolean 是否为斜角
function XChessActor:GetSkillDamage(skillId, isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    --纯技能伤害
    local skill = self:TryGetSkill(skillId)
    local damage = skill:GetDamage(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local finalDamage = self:GetFinalDamage(damage, isAssist)
    if skill:GetSkillType() == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        finalDamage = finalDamage + self._AddRoundDamageByPassive
    end
    return finalDamage
end

---根据被动及加成 计算最终伤害
---@param damage number 初始伤害
---@param isAssist boolean 是否为支援
function XChessActor:GetFinalDamage(damage, isAssist)
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

--- 使用角色技能
function XChessActor:UseWeaponSkill(skillId)
    -- 薇拉大招为仅红怒状态下使用 但是普通状态下也会显示 不过策划配置释放条件为怒气满的时候 而怒气满了必定会切换到红怒模式 所以不用做特殊处理
    if not self._OwnControl:CouldUseSkill(self._RoleId, skillId) then
        return false
    end
    self.IsSkillRunning = true
    local skill = self:TryGetSkill(skillId)
    local addRoundCost = self:GetAddRoundCost(skillId)
    self._CurUsedSkillType = skill:GetSkillType()
    --小刀被动技能
    if skill:IsPassive() then
        self:UsePassiveSkill(skill)
        self._OwnControl:ConsumeEnergy(self._RoleId, skillId, addRoundCost)
        return false
    end
    skill:AddSkillUsedTimes()
    self._CurAttackTimes = 0 -- 当前技能造成伤害的次数
    self:UseActiveSkill(skill)
    -- 技能造成伤害回复能量
    self._OwnControl:SkillAttackRecoverEnergy(skillId, self._CurAttackTimes)
    --移除被动技能效果
    self:ResetSkill()
    --能量消耗 检查是否进入/退出红莲状态
    self._OwnControl:ConsumeEnergy(self._RoleId, skillId, addRoundCost)
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
    local aim
    if skill:GetSkillType() == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL2 then
        --薇拉普通咖喱棒特殊处理 服务端需要最远的坐标
        local point = skill._Imp.ShotCenter
        local actorPoint = self:GetMovedPoint()
        local direction = point - actorPoint
        local col = direction.x * skill._Imp.ShotRange + actorPoint.x
        local row = direction.y * skill._Imp.ShotRange + actorPoint.y
        aim = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Coordinate(col, row)
    else
        aim = skill:GetShotCenter()
    end
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
    --缓存原先的武器Id
    local tempWeaponId = self._WeaponId
    --使用技能（怒气满足会切换武器）
    self._Imp:UseActiveSkill(skillId)
    --正式攻击
    local isAttack = self:CauseDamage(skill, sputtering, attackInfo, false, false, AttackBatch.Normal)
    --协助攻击
    self:CauseDamage(skill, assistSputtering, attackInfo, false, true, AttackBatch.Assist)
    --多段伤害
    local isAttackMulti = self:CauseDamage(skill, multiSputtering, attackInfo, false, false, AttackBatch.Multi)
    
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK, false, tempWeaponId, skillId, aim.x, aim.y, 1)
    --部分特殊技能会在击杀敌方棋子时刷新技能cd
    local killPieces = self:GetAttackKillPiece()
    if skill:IsKillRefresh() then
        if XTool.IsTableEmpty(killPieces) or not skill:IsEnoughEnergy() then
            skill:DoUse()
        end
    else
        skill:DoUse()
    end
    --触发技能被动效果
    if skill:GetSkillType() == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        skill:TriggerPassive(false, killPieces)
    else
        skill:TriggerPassive()
    end
    self:CheckDefenseSkill(skill)
    if (isAttack or isAttackMulti) and skill:IsExtraTurn(self._RoundCount) then
        self:AddMaxRoundCount()
    end
    self:AddRoundCount()
end

---使用格挡技能
---@param skill XChessSkill
function XChessActor:CheckDefenseSkill(skill)
    local skillType = skill:GetSkillType()
    local params = self._OwnControl:GetWeaponSkillParams(skill:GetId())
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL1 then
        self._DefenseInfo = {
            DefenseTimes = tonumber(params[1]),
            AttackTimes = 0,
            AddEnergy = tonumber(params[2]),
            DriveBackDistance = 0,
            BeheadedAtk = 0,
            CollisionAtk = 0,
        }
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_RED_SKILL1 then
        self._DefenseInfo = {
            DefenseTimes = tonumber(params[1]),
            AttackTimes = tonumber(params[2]),
            AddEnergy = 0,
            DriveBackDistance = tonumber(params[3]),
            BeheadedAtk = tonumber(params[4]),
            CollisionAtk = tonumber(params[5]),
        }
    end
end

---格挡伤害
---@return boolean 是否格挡成功
function XChessActor:CheckDefense()
    if not self._DefenseInfo or self._DefenseInfo.DefenseTimes <= 0 then
        return false
    end
    self._DefenseInfo.DefenseTimes = self._DefenseInfo.DefenseTimes - 1
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.DEFENSE_SUCCESS)
    return true
end

function XChessActor:DoDefense()
    if self._DefenseInfo.AttackTimes > 0 then
        self:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_REDMODEL_DEFENCE_ATTACK_1)
        self._SyncPlayAnimation("BlockSuccess")
        self:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_REDMODEL_DEFENCE_ATTACK_2)
        self._SyncPlayAnimation("RedBlockAtk")
    else
        self._SyncPlayAnimation("BlockSuccess")
        self:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_DEFENCE_SUCCESS, nil, nil, true)
    end
    self._OwnControl:SkillDefenseRecoverEnergy(self._DefenseInfo.AddEnergy)
end

function XChessActor:GetDefenseInfo()
    return self._DefenseInfo
end

---（融合buff）免伤
function XChessActor:DoInjuryFree()
    if not self._InjuryFreeTimes or self._InjuryFreeTimes <= 0 then
        return false
    end
    self._InjuryFreeTimes = self._InjuryFreeTimes - 1
    if self._InjuryFreeTimes == 0 then
        self:BlendPartnerDestory()
    end
    return true
end

---保护免受攻击
function XChessActor:IsInvincible()
    return self._IsInvincible
end

---格挡反击
function XChessActor:DoCounterattack()
    if not self._DefenseInfo or self._DefenseInfo.AttackTimes <= 0 then
        return
    end
    ---@type UnityEngine.Vector2Int
    local tempVec2 = CS.UnityEngine.Vector2Int(0, 0)
    local pieceMoveMap = {}
    ---@type table<XBlackRockChessPiece,boolean>
    local pieceMap = {}
    local pieceAttackBackMap = {}
    ---@type XBlackRockChessPiece[]
    local blockList = {}
    --主角周围一圈
    for x = -1, 1 do
        for y = -1, 1 do
            if x == 0 and y == 0 then
                goto continue
            end
            local actorPoint = self:GetMovedPoint()
            tempVec2:Set(x + actorPoint.x, y + actorPoint.y)
            local piece = self._OwnControl:PieceAtCoord(tempVec2)
            if piece and piece.IsPartner and not piece:IsPartner() then
                -- 敌方被击退
                local finalPointX, finalPointY = nil, nil
                local isMoved = true
                local points = piece:GetPositionBehind(self:GetMovedPoint(), self._DefenseInfo.DriveBackDistance)
                for _, point in ipairs(points) do
                    tempVec2:Set(point[1], point[2])
                    local block = self._OwnControl:PieceAtCoord(tempVec2)
                    local virtualBlock = self._OwnControl:VirtualPieceAtCoord(tempVec2)
                    if block then
                        if block.IsPartner and not block:IsPartner() then
                            -- 被其他敌方棋子阻挡 其他敌方棋子也受到撞击伤害
                            table.insert(blockList, block)
                        end
                        isMoved = false
                    end
                    if not self._OwnControl:IsSafeCoordinate(point[1], point[2]) then
                        -- 超出了地图范围
                        isMoved = false
                    end
                    if virtualBlock then
                        -- 被虚影阻挡了
                        isMoved = false
                    end
                    if isMoved then
                        finalPointX, finalPointY = point[1], point[2]
                    end
                end
                if finalPointX ~= nil and finalPointY ~= nil then
                    -- 击退
                    pieceAttackBackMap[piece] = CS.UnityEngine.Vector2Int(finalPointX, finalPointY)
                end
                -- 反击伤害
                pieceMap[piece] = piece:IsInvincible(self._RoleId)
                -- 是否存在撞击伤害
                pieceMoveMap[piece] = isMoved
            end
            :: continue ::
        end
    end

    -- 棋子被击飞
    for piece, point in pairs(pieceAttackBackMap) do
        piece:AttackBack(point, true)
    end
    
    -- 所有棋子受反击伤害
    for piece, isInvincible in pairs(pieceMap) do
        local damage = isInvincible and 0 or self:GetFinalDamage(self._DefenseInfo.BeheadedAtk)
        piece:AttackEd(damage, false, false, self._RoleId, self._RoundCount)
        if damage > 0 then
            piece:OnSkillHit()
        end
    end
    
    -- 提前检查免疫buff
    ---@type table<XBlackRockChessPiece,number>
    local pieceImpactMap = {}
    for piece, _ in pairs(pieceMap) do
        local isMoved = pieceMoveMap[piece]
        if not isMoved then
            pieceImpactMap[piece] = piece:IsInvincible(self._RoleId) and 0 or self:GetFinalDamage(self._DefenseInfo.CollisionAtk)
        end
    end
    
    -- 提前检查阻挡棋子免疫buff
    ---@type table<XBlackRockChessPiece,number>
    local blockPieceDamageMap = {}
    for _, block in pairs(blockList) do
        blockPieceDamageMap[block] = block:IsInvincible(self._RoleId) and 0 or self:GetFinalDamage(self._DefenseInfo.CollisionAtk)
    end

    -- 所有棋子撞击伤害
    for piece, damage in pairs(pieceImpactMap) do
        piece:AttackEd(damage, false, false, self._RoleId, self._RoundCount, true)
        if damage > 0 then
            piece:OnSkillHit()
        end
    end
    
    -- 所有阻挡棋子受击
    for block, damage in pairs(blockPieceDamageMap) do
        block:AttackEd(damage, false, false, self._RoleId, self._RoundCount)
        if damage > 0 then
            block:OnSkillHit()
        end
    end
    
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.DEFENSE_ATTACK)
    self._DefenseInfo.AttackTimes = self._DefenseInfo.AttackTimes - 1
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK, false, 1)
end

---格挡反击Boss
function XChessActor:DoCounterattackBoss()
    if not self._DefenseInfo or self._DefenseInfo.AttackTimes <= 0 then
        return
    end

    ---@type UnityEngine.Vector2Int
    local tempVec2 = CS.UnityEngine.Vector2Int(0, 0)
    --主角周围一圈
    for x = -1, 1 do
        for y = -1, 1 do
            if x == 0 and y == 0 then
                goto continue
            end
            local actorPoint = self:GetMovedPoint()
            tempVec2:Set(x + actorPoint.x, y + actorPoint.y)
            local piece = self._OwnControl:PieceAtCoord(tempVec2)
            if piece then
                -- 反击伤害
                piece:AttackEd(self:GetFinalDamage(self._DefenseInfo.BeheadedAtk), false, false, self._RoleId, self._RoundCount)
                piece:OnSkillHit()
            end
            :: continue ::
        end
    end

    self._DefenseInfo.AttackTimes = self._DefenseInfo.AttackTimes - 1
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_ATTACK_BACK, false, 1)
end

---回合结束/格挡次数为0时移除格挡
function XChessActor:RemoveDefenseState()
    self._DefenseInfo = nil
    self:PlayAnimation("Stand")
    self:HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_DEFENCE)
    self:HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_DEFENCE_SUCCESS)
    self:HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_REDMODEL_DEFENCE)
    self:HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_REDMODEL_DEFENCE_ATTACK_1)
    self:HideEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_REDMODEL_DEFENCE_ATTACK_2)
end

---根据能量切换普通和红怒模式
function XChessActor:UpdateModelByEnergy()
    if not self._Imp then
        return
    end
    local energy = self._OwnControl:GetChessGamer():GetEnergy()
    local target = self._OwnControl:GetEnterRedModelEnergy()
    local redModelWeaponId = self._OwnControl:GetRoleWeaponId(self._RoleId, 2)
    local oldWeaponId = self._Imp.Weapon and self._Imp.Weapon.Id
    if XTool.IsNumberValid(redModelWeaponId) and energy >= target then
        if self._Imp.Weapon and self._Imp.RedModelWeapon and self._Imp.Weapon ~= self._Imp.RedModelWeapon then
            self._Imp.Weapon.CurrentPoint = self:GetMovedPoint()
        end
        self._Imp:SwitchToRedModelWeapon()
    else
        if self._Imp.Weapon and self._Imp.NormalWeapon and self._Imp.Weapon ~= self._Imp.NormalWeapon then
            self._Imp.Weapon.CurrentPoint = self:GetMovedPoint()
        end
        self._Imp:SwitchToNormalWeapon()
    end
    self:UpdateEnergyEffect()
    self._WeaponId = self._Imp.Weapon.Id
    if oldWeaponId and oldWeaponId ~= self._WeaponId then
        -- 切换了武器 清掉原先的技能选中数据
        self._OwnControl:OnCancelSkill(false)
    end
    --刷新UI上的技能显示
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

---刷新红怒特效显示
function XChessActor:UpdateEnergyEffect()
    local energy = self._OwnControl:GetChessGamer():GetEnergy()
    local target = self._OwnControl:GetEnterRedModelEnergy()
    local maxEnergy = self._OwnControl:GetMaxEnergy()
    local effectNotFull = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_ENERGY_NOTFULL
    local effectFull = XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.VERA_ENERGY_FULL
    if energy < target then
        self:HideEffect(effectNotFull)
        self:HideEffect(effectFull)
    elseif energy < maxEnergy then
        self:HideEffect(effectFull)
        self:LoadEffect(effectNotFull, nil, nil, true)
    elseif energy >= maxEnergy then
        self:HideEffect(effectNotFull)
        self:LoadEffect(effectFull, nil, nil, true)
    end
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
    --是否有棋子在这次攻击中死亡
    local isPieceDead = false
    local isAttack = false
    local count = list.Count
    if isPreview then
        local piece = self._OwnControl:PieceAtCoord(aim)
        --中心点有地方棋子
        if piece and piece.IsPiece and piece:IsPiece() then
            self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_FOCUS_ENEMY, piece:GetId())
        end
    end
    local convertKey = CS.XBlackRockChess.XBlackRockChessUtil.Convert2Int
    --先判断棋子是否无敌
    --角色技能对多个棋子造成伤害是同时发生的 所以无敌Buff不会因为目标棋子在这一次攻击中死亡而失效（角色的红莲反击技能就会 因为造成的伤害有先后顺序）
    ---@type XBlackRockChessPiece[]
    local pieceMap = {}
    local invincibleMap = {}
    for i = 0, count - 1 do
        local point = list[i]
        local piece = self._OwnControl:PieceAtCoord(point)
        if piece then
            pieceMap[i] = piece
            invincibleMap[i] = piece:IsInvincible(self._RoleId)
        end
    end
    for i = 0, count - 1 do
        local point = list[i]
        local piece = pieceMap[i]
        local pointKey = convertKey(point.x, point.y)
        local info = attackInfo[pointKey]
        --当前回合被攻击的次数
        local attackTime
        --判断是否为无敌
        local isInvincible

        --是否为攻击中心点
        local isCenter = CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(point, aim)
        --是否为斜角
        local isHypotenuse = actorPoint.x ~= point.x and actorPoint.y ~= point.y
        --当次技能造成的伤害
        local damage = self:GetSkillDamage(skill:GetId(), isCenter, isExtraTurn, isAssist, batch == AttackBatch.Multi, isHypotenuse)
        --追加被动技能伤害加成
        for _, tempSkill in pairs(self._RoleSkillDict) do
            if tempSkill:IsTriggerOnAttack() then
                damage = damage + tempSkill:Trigger(piece)
            end
        end
        
        --显示在地板上的伤害
        local displayDamage = damage + (info and info.DisplayDamage or 0)
        --实际造成的伤害
        local actualDamage = 0
        
        if not piece or not piece.IsPiece or not piece:IsPiece() then
            attackTime = info and info.AttackTimes or 0
        else
            attackTime = math.max(info and info.AttackTimes or 0,  piece:GetAttackTimes())
            local isInvincible = invincibleMap[i]
            if isPreview then
                piece:LookAt(actorPoint.x, actorPoint.y)
                actualDamage = (isInvincible and 0 or damage) + (info and info.ActualDamage or 0)
                self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, piece:GetId(), actualDamage, false)
            else
                actualDamage = isInvincible and 0 or damage
                local attacked = piece:AttackEd(actualDamage, skill:IsDizzy(), false, self._RoleId, self._RoundCount)
                isAttack = isAttack or attacked
                --造成伤害次数+1
                if displayDamage > 0 then
                    self._CurAttackTimes = self._CurAttackTimes + 1
                end
            end
            if piece:IsPreviewDead() then
                isPieceDead = true
            end
        end
        -- 对友方棋子造成影响
        --if piece and piece.IsPartner and piece:IsPartner() then
        --    local params = self._OwnControl:GetWeaponSkillParams(skill:GetId())
        --    if skill:GetSkillType() == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_RED_SKILL2 then
        --        local addHp = params[3]
        --        if isPreview then
        --            self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, piece:GetId(), -addHp, true)
        --        else
        --            -- 给友方回血
        --            piece:AddHp(addHp)
        --        end
        --    end
        --end
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

    if isPreview and isPieceDead then
        self:ShowPreviewWarnLine()
    else
        self:RecyclePreviewWarnLine()
    end
    
    self:ShowVeraWarnEffect(skill)
    
    self._TargetOfAttack[batch] = attackPieces
    
    return isAttack
end

--- 角色释放技能是否击杀了敌方棋子
function XChessActor:GetAttackKillPiece()
    local pieces = {}
    if XTool.IsTableEmpty(self._TargetOfAttack) then
        return pieces
    end
    for _, datas in pairs(self._TargetOfAttack) do
        for _, point in pairs(datas) do
            local piece = self._OwnControl:PieceAtCoord(point)
            if piece and piece:IsPiece() and not piece:IsAlive() then
                table.insert(pieces, piece)
            end
        end
    end
    return pieces
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
    self._CurUsedSkillType = nil
    self:UpdateModelByEnergy()
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

--- 获得角色/技能被动
function XChessActor:TryGetRoleSkill(roleSkillId)
    local skill = self._RoleSkillDict[roleSkillId]
    if skill then
        return skill
    end
    
    local roleSkillType = XMVCA.XBlackRockChess.RoleSkillType
    local type = self._OwnControl:GetRoleSkillType(roleSkillId)
    if type == roleSkillType.LunaProtect then
        skill = XLunaProtectedSkill.New(self._OwnControl, roleSkillId, self._RoleId)
    elseif type == roleSkillType.LunaHyperAddDps or type == roleSkillType.LunaHyperAddMove or type == roleSkillType.LunaHyperAddRange then
        skill = XLunaHyperPassive.New(self._OwnControl, roleSkillId, self._RoleId)
    elseif type == roleSkillType.VeraHyperAddDps or type == roleSkillType.VeraHyperAddCost or type == roleSkillType.VeraHyperSummon then
        skill = XVeraHyperPassive.New(self._OwnControl, roleSkillId, self._RoleId)
    elseif type == roleSkillType.VeraPosAddDps then
        local XVeraPosAddDpsSkill = require("XModule/XBlackRockChess/XGameObject/XRoleSkill/XVeraPosAddDpsSkill")
        skill = XVeraPosAddDpsSkill.New(self._OwnControl, roleSkillId, self._RoleId)
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
    -- 受到致命伤害才会触发
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
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, true)
    self._SyncPlayAnimation("Defeated")
    --标记复活
    self._OwnControl:GetChessGamer():Revive(self._RoleId)
    self._SyncPlayAnimation("Fall")
    --if self._OwnControl:GetGamerLeftReviveCount() >= 0 then
    --    self._SyncPlayAnimation("Reborn")
    --end
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, false)
end

-- 被攻击
function XChessActor:Attacked(piece)
    for _, skill in pairs(self._RoleSkillDict) do
        if skill:IsTriggerOnAttacked() then
            skill:Trigger(piece)
        end
    end
    --无敌
    if self._IsInvincible then
        return
    end
    --展示CheckMate
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, true)
    self._SyncPlayAnimation("Defeated")
    --标记复活
    self._OwnControl:GetChessGamer():Revive(self._RoleId)
    self._SyncPlayAnimation("Fall")
    --if self._OwnControl:GetGamerLeftReviveCount() >= 0 then
    --    self._SyncPlayAnimation("Reborn")
    --end
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, false)
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

---增加被动伤害
function XChessActor:AddDamage(value)
    self._AddDamageByPassive = value
end

---增加被动伤害（持续一回合）
function XChessActor:AddRoundDamage(value)
    self._AddRoundDamageByPassive = value
end

---增加能量消耗（持续一回合）
function XChessActor:AddRoundCost(value)
    self._AddRoundCost = value
end

function XChessActor:GetAddRoundCost(skillId)
    local skillType = self._OwnControl:GetWeaponSkillType(skillId)
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        return self._AddRoundCost
    end
    return 0
end

function XChessActor:DispatchBuff(skillId, value)
    if not self._Imp then
        return
    end
    if value > 0 then
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BUFF_HUD, self._RoleId,
                self._Imp.transform, skillId, value)
    else
        self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BUFF_HUD, self._RoleId, skillId)
    end
end
--endregion------------------Battle finish------------------

--region   ------------------ExtraRound start-------------------

--角色回合操作结束
function XChessActor:AddRoundCount()
    self._RoundCount = self._RoundCount + 1
    self._AddRoundDamageByPassive = 0
    self._AddRoundCost = 0
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
    local config = self._OwnControl:GetEffectConfig(effectId)

    if not offset then
        if string.IsNilOrEmpty(config.Offset) then
            offset = CS.UnityEngine.Vector3.zero
        else
            offset = self._OffsetMap[config.Offset]
            if not offset then
                local strs = string.Split(config.Offset, "|")
                offset = CS.UnityEngine.Vector3(tonumber(strs[1]), tonumber(strs[2]), tonumber(strs[3]))
                self._OffsetMap[config.Offset] = offset
            end
        end
    end

    if not rotate then
        if string.IsNilOrEmpty(config.Rotate) then
            rotate = CS.UnityEngine.Vector3.zero
        else
            rotate = self._RotateMap[config.Rotate]
            if not rotate then
                local strs = string.Split(config.Rotate, "|")
                rotate = CS.UnityEngine.Vector3(tonumber(strs[1]), tonumber(strs[2]), tonumber(strs[3]))
                self._RotateMap[config.Rotate] = rotate
            end
        end
    end
    
    isBindRole = isBindRole or false
    self._Imp.Weapon:LoadEffect(effectId, offset, rotate, isBindRole)
end

function XChessActor:HideEffect(effectId)
    self._Imp.Weapon:HideEffect(effectId)
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
    -- 特殊判断：Stand动作不要打断RedModel动作播放 因为效果不好看
    -- PS:状态名叫RedModel 但动作名叫Refuse01
    local clipName = self._Imp:GetCurrentClipName()
    if clipName == "Refuse01" and actionId == "Stand" then
        return
    end
    --local newCb = self:DoCommonWait(cb)
    crossTime = crossTime or 0
    self._Imp:PlayAnimation(actionId, crossTime, cb)
end

function XChessActor:PlayTimeline(actionId, cb)
    --local newCb = self:DoCommonWait(cb)
    self._Imp:PlayTimelineAnimation(actionId, cb)
end

function XChessActor:PlayWinMove(col, row, cb)
    self._Imp:SwitchToNormalWeapon()
    self:MoveTo(col, row, cb)
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
    --self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_HIDE_BUFF_HUD, self._RoleId)
end

--- 回合结束
function XChessActor:OnEndOfTurn()
    self:ResetRoundCount()
    self:ResetSkill()
    self:SetInvincible(false)
    self._VeraWarnEffect = nil
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

function XChessActor:DoWin()
    self._OwnControl:PlayGrowls(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER, XMVCA.XBlackRockChess.GrowlsTriggerType.OnWin, self:GetRoleId())
end

--endregion------------------Sync-Restore finish------------------

return XChessActor

---@class DefenseInfo 格挡信息
---@field DefenseTimes number 免伤次数
---@field AttackTimes number 反击次数
---@field AddEnergy number 格挡后增加能量
---@field DriveBackDistance number 击退格数
---@field BeheadedAtk number 斩击伤害
---@field CollisionAtk number 碰撞伤害