---@class XChessBoss : XEntity 敌方Boss
---@field _Imp XBlackRockChess.XChessBoss
---@field _OwnControl XBlackRockChessControl
---@field _BuffDict table<number, XBlackRockChess.XBuff> 技能
---@field _LuaWeapon XBlackRockChessWeapon
local XChessBoss = XClass(XEntity, "XChessBoss")

function XChessBoss:OnInit(roleId)
    self._RoleId = roleId
    self._X = 0
    self._Y = 0
    self._MemberType = nil
    self._BuffDict = {} --生效Buff
    self._SyncPlayAnimation = asynTask(function(actionId, cb)
        self:PlayAnimation(actionId, 0, cb)
    end)
    self._MoveCd = 0
    self._AttackedTimes = 0
end

function XChessBoss:SetImp(imp)
    self._Imp = imp
    self:InitImp()
    self._LuaWeapon = self:GetLuaWeapon()
    self:TurnRoundRole()
    self:RefreshEffects()
end

function XChessBoss:GetImp()
    return self._Imp
end

function XChessBoss:GetIsMoved()
    return self._IsMoved == true
end

function XChessBoss:GetIsAttacked()
    return self._IsAttacked == true
end

function XChessBoss:InitImp()
    self._Imp:RegisterLuaCallBack(handler(self, self.DoSelectSkill), handler(self, self.OnMovedEnd), 
            handler(self, self.OnSelect), nil, nil, nil, handler(self, self.OnIdle))
    local idleTime = self._OwnControl:GetChessGrowlsTriggerArgs(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER,
            XMVCA.XBlackRockChess.GrowlsTriggerType.IdleTime, self._RoleId)
    if not XTool.IsTableEmpty(idleTime) then
        for time, _ in pairs(idleTime) do
            self._IdleInterval = time
            break
        end
        self._Imp:BeginIdle(self._IdleInterval)
    end

    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_BOSS_HEAD_HUD, self._RoleId, self._Imp.transform)
end

-- 重新加载boss模型
function XChessBoss:ReloadBossModel(weaponId)
    local modelUrl = self._OwnControl:GetWeaponModelUrl(weaponId)
    local controllerUrl = self._OwnControl:GetWeaponControllerUrl(weaponId)
    self._Imp:LoadBossModel(modelUrl, controllerUrl)
end

-- 获取Lua的武器脚本
function XChessBoss:GetLuaWeapon()
    local luaWeapon = nil
    local weaponId = self._WeaponId
    local weaponType = self._OwnControl:GetWeaponType(weaponId)
    if weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.BANSHOU then
        local XBlackRockChessWeaponBanshou = require("XModule/XBlackRockChess/XWeapon/XBlackRockChessWeaponBanshou")
        luaWeapon = XBlackRockChessWeaponBanshou.New(self)
    elseif weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_BLACK then
        local XBlackRockChessWeaponZhetianBlack = require("XModule/XBlackRockChess/XWeapon/XBlackRockChessWeaponZhetianBlack")
        luaWeapon = XBlackRockChessWeaponZhetianBlack.New(self)
    elseif weaponType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_TYPE.ZHETIAN_WHITE then
        local XBlackRockChessWeaponZhetianWhite = require("XModule/XBlackRockChess/XWeapon/XBlackRockChessWeaponZhetianWhite")
        luaWeapon = XBlackRockChessWeaponZhetianWhite.New(self)
    end
    
    -- 设置LuaSearch函数回调
    self._Imp.Weapon.LuaSearch = function(csharpList)
        luaWeapon:Search(csharpList)
    end
    -- 设置LuaSearchAttack函数回调
    self._Imp.Weapon.LuaSearchAttack = function(csharpList)
        luaWeapon:SearchAttack(csharpList)
    end
    return luaWeapon
end

function XChessBoss:UpdateData(formation)
    if not formation then
        return
    end
    local characterInfo = formation.CharacterInfo
    self._X = formation.X
    self._Y = formation.Y
    self._Life = formation.Life
    self._MemberType = formation.Type
    self._WeaponId = characterInfo.WeaponId
    self._SummonRound = characterInfo.SummonRound
    self._SummonSkillId = characterInfo.SummonSkillId
    self._SkillCds = characterInfo.SkillCds or {}
    self._CharacterSkillDict = characterInfo.CharacterSkillDict or {}
    self._WeaponSkillDict = characterInfo.WeaponSkillDict or {}
    self._AttackedTimes = characterInfo.AttackedTimes or 0
    self._DizzyCd = characterInfo.DizzyCd or 0
    self._BuffList = formation.BuffList or {}
    self._IsMoved = false
    self._IsAttacked = false
    self:CheckSwitchLuaWeapon()
    self:RefreshEffects()
    self:ShowDelaySkillTalk()
end

function XChessBoss:GetWeaponSkillDict()
    return self._WeaponSkillDict
end

-- 检测切换武器
function XChessBoss:CheckSwitchLuaWeapon()
    if self._LuaWeapon and self._LuaWeapon:GetWeaponId() ~= self._WeaponId then
        self._LuaWeapon:OnRelease()
        self._LuaWeapon = self:GetLuaWeapon()
    end
end

function XChessBoss:IsInBoard()
    if not self._Imp then
        return false
    end
    return self._Imp.IsInBoard
end

function XChessBoss:GetWeaponId()
    return self._WeaponId
end

function XChessBoss:GetRoleId()
    return self._RoleId
end

function XChessBoss:GetId()
    return self._RoleId
end

--region   ------------------Position start-------------------

--当前移动的点位
function XChessBoss:GetMovedPoint()
    if not self._Imp or not self._Imp:IsEquipped() then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.Weapon.MovedPoint
end

--当前回合初始的点位
function XChessBoss:GetCurrentPoint()
    if not self._Imp or not self._Imp:IsEquipped() then
        return CS.UnityEngine.Vector2Int.zero
    end
    
    return self._Imp.Weapon.CurrentPoint
end

function XChessBoss:GetRolePoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.RolePoint
end

--服务器更新的位置
function XChessBoss:GetPos()
    return self._X, self._Y
end

--看向胜利的机位
function XChessBoss:LookAtWinCamera()
    if not self._Imp then
        return
    end
    --相机看向角色
    CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:AddWinCamFollowAndLookAt(self._Imp.transform)
    --角色看向相机
    local position = CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard.SceneCamera.transform.position
    self._Imp.Weapon:TurnRound(position)
end

function XChessBoss:OnMovedEnd(col, row, isManual)
    if not self._Imp then
        return
    end

    -- 手动操作才记录位置
    if isManual then
        -- 添加移动Action
        local roundCount = 1
        self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, XEnumConst.BLACK_ROCK_CHESS.CHESS_OBJ_TYPE.BOSS, col, row, self._WeaponId, roundCount)
    end
end

function XChessBoss:TakeBuffEffect()
    if CS.XBlackRockChess.XBlackRockChessManager.Instance.IsWin then
        return
    end
    --移除临时效果
    self._Imp:ResetBeforeUseSkill()
    --攻击前触发Buff
    for _, buff in pairs(self._BuffDict) do
        if buff and buff:IsEffectiveBeforeAttacked() then
            buff:DoTakeEffect()
        end
    end
end

-- 选中Boss
function XChessBoss:OnSelect(isPreview)
    local skillId = self:GetDelaySkillId()
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_SELECT_BOSS, self._RoleId, skillId, isPreview)
end

function XChessBoss:EnterMove()
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

--endregion------------------Position finish------------------

--region   ------------------Battle start-------------------
function XChessBoss:CheckAttackPoint(point)
    if not self._Imp then
        return false
    end
    if not self:IsAttackAble() then
        return false
    end
    return self._LuaWeapon:CheckAttackPoint(point)
end

function XChessBoss:GetHp()
    return self._Life
end

--- 发呆未操作
--------------------------
function XChessBoss:OnIdle()
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
function XChessBoss:ShowHitEffect(pointKey, point, effectId, hitFrom, isAssist)
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

--- 被攻击, 为了保证调用顺序，需要在RunAsync中执行
---@param piece XBlackRockChessPiece
---@param syncMove function 同步移动函数
---@return
--------------------------
function XChessBoss:AsyncAttacked(piece, syncMove)
    --被击杀
    syncMove(piece, self:GetMovedPoint(), true)
    --展示CheckMate
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, true)
    self._SyncPlayAnimation("Defeated")
    --标记复活
    self._OwnControl:GetChessGamer():Revive(self._RoleId)
    self._SyncPlayAnimation("Fall")
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_CHECK_MATE, false)
end
--endregion------------------Battle finish------------------

--region   ------------------Effect start-------------------

--加载特效
function XChessBoss:LoadEffect(effectId, offset, rotate, isBindRole, delay)
    offset = offset or CS.UnityEngine.Vector3.zero
    rotate = rotate or CS.UnityEngine.Vector3.zero
    isBindRole = isBindRole or false

    if delay and delay > 0 then
        self:ClearLoadEffectTimer()
        self.LoadEffectTimer = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self._Imp) or XTool.UObjIsNil(self._Imp.gameObject) then
                return
            end
            self._Imp:LoadEffectInternal(effectId, offset, rotate, isBindRole)
        end, delay)
    end
    self._Imp:LoadEffectInternal(effectId, offset, rotate, isBindRole)
end

function XChessBoss:ClearLoadEffectTimer()
    if self.LoadEffectTimer then
        XScheduleManager.UnSchedule(self.LoadEffectTimer)
        self.LoadEffectTimer = nil
    end
end

function XChessBoss:ShowBubbleText(text)
    if not self._Imp then
        return
    end
    self._OwnControl:ShowBubbleText(self._Imp, text)
end

--endregion------------------Effect finish------------------

--region   ------------------Animation start-------------------

function XChessBoss:DoCommonWait(cb)
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

function XChessBoss:PlayAnimation(actionId, crossTime, cb)
    local newCb = self:DoCommonWait(cb)
    crossTime = crossTime or 0
    self._Imp:PlayAnimation(actionId, crossTime, newCb)
end

function XChessBoss:PlayTimeline(actionId, cb)
    local newCb = self:DoCommonWait(cb)
    self._Imp:PlayTimelineAnimation(actionId, newCb)
end

--endregion------------------Animation finish------------------


--region   ------------------Sync-Restore start-------------------
function XChessBoss:Restore()
    self._IsDizzy = false
    self._IsMoved = false
    self._IsPlayDead = false
    
    if not self._Imp or not self._Imp:IsEquipped() then
        return
    end

    self._Imp.Weapon:Restore(self._X, self._Y)
    self:RefreshEffects()
    self:ClearLoadEffectTimer()
    self:ClearHideTimer()
end

function XChessBoss:OnRelease()
    self._Imp = nil
    self._X = 0
    self._Y = 0
    self:ClearAllEffect(true)
    self:ClearLoadEffectTimer()
    self:ClearHideTimer()
end
--endregion------------------Sync-Restore finish------------------


-- ============================================ 分割线 ===============================================
function XChessBoss:IsDizzy()
    return self._IsDizzy or self._DizzyCd > 0
end

function XChessBoss:IsCanMove()
    return self._MoveCd == 0
end

function XChessBoss:IsAlive()
    return self._Life and self._Life > 0
end

function XChessBoss:IsAttackAble()
    if not self:IsAlive() or self:IsDizzy() then
        return false
    end
    return true
end

-- 技能是否在cd冷却中
function XChessBoss:IsSkillInCD(skillId)
    for _, info in pairs(self._SkillCds) do
        local skillIds = self._OwnControl:GetWeaponSkillSkillIds(info.Id)
        for _, tempSkillId in ipairs(skillIds) do
            if tempSkillId == skillId then
                return info.Cd > 0, info.Cd
            end
        end
    end
    return false
end

-- 是否存在技能延迟回合生效
function XChessBoss:IsExitSkillDelay()
    for _, skillInfo in pairs(self._WeaponSkillDict) do
        if skillInfo.DelayRound >= 0 then
            return true
        end
    end
    return false
end

-- 技能是否存在延迟结算
function XChessBoss:IsSkillInDelay(skillId)
    local delayInfo = self._WeaponSkillDict[skillId]
    local delayRound = delayInfo and delayInfo.DelayRound or 0
    return delayInfo ~= nil, delayRound
end

-- 获取延迟生效的技能
function XChessBoss:GetDelaySkillInfo()
    for skillId, skillInfo in pairs(self._WeaponSkillDict) do
        if skillInfo.DelayRound >= 0 then
            skillInfo.SkillId = skillId
            return skillInfo
        end
    end
end

-- 获取延迟技能Id
function XChessBoss:GetDelaySkillId()
    local delayInfo = self:GetDelaySkillInfo()
    return delayInfo and delayInfo.SkillId or nil
end

-- 检测释放延迟技能
function XChessBoss:CheckPlayDelaySkill()
    return self._LuaWeapon:CheckPlayDelaySkill()
end

-- 是否可以行动
function XChessBoss:IsCanTakeAction()
    if not self:IsAlive() or self:IsDizzy() then
        return false
    end
    
    -- 即将被眩晕
    if self._LuaWeapon:IsDizzyAfterDelaySkill() then
        return false
    end
    
    local canTakeAction = true
    for _, skillInfo in pairs(self._WeaponSkillDict) do
        if skillInfo.DelayRound > 0 then
            canTakeAction = false
        end
        -- 遮天碧碧黑形态大招第一段延迟结算，总共有两段延迟结算
        if skillInfo.SkillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_BLACK_BIGSKILL and skillInfo.Count == 1 then
            canTakeAction = false
        end
        -- 遮天碧碧白形态大招第一段延迟结算，总共有两段延迟结算
        if skillInfo.SkillId == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL and skillInfo.Count == 1 then
            canTakeAction = false
        end
    end
    return canTakeAction
end

-- 是否可播放技能（角色在技能伤害范围之内）
function XChessBoss:IsCanPlaySkill()
    return self._LuaWeapon:IsCanPlaySkill()
end

-- boss移动
function XChessBoss:MoveTo(point, onlyMove, finishCb)
    if not self._Imp then
        if finishCb then finishCb() end
        return
    end
    local movePoint = onlyMove and point or self._LuaWeapon:SearchMovePoint(point)
    if not movePoint then
        return
    end

    local newFinishCb = function()
        for _, buff in pairs(self._BuffDict) do
            if buff and buff:IsEffectiveByMoved() then
                self:TakeBuffEffect(buff, 0, false)
            end
        end
        self._OwnControl:SubWaitCount()
        if finishCb then finishCb() end
    end
    
    self._OwnControl:AddWaitCount()
    CS.XBlackRockChess.XBlackRockChessManager.Instance:MoveTo(self._Imp, movePoint.x, movePoint.y, newFinishCb)
    local movedPoint = self:GetMovedPoint()
    self._IsMoved = self._Imp:IsMoved() or not CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(movedPoint, movePoint)
end

-- boss攻击
function XChessBoss:AttackTo(point)
    if self:IsExitSkillDelay() then
        return self:CheckPlayDelaySkill()
    else
        return self:PlaySkill()
    end
end

-- 释放技能
function XChessBoss:PlaySkill()
    self:ShowPlaySkillTalk()
    return self._LuaWeapon:PlaySkill()
end

function XChessBoss:AddAction(actionType, objType, ...)
    local action = {
        ObjId = self._RoleId,
        ActionType = actionType,
        ObjType = objType,
        Params = { ... }
    }

    XLog.Warning("============BOSS Action = " .. XLog.Dump(action))
    self._OwnControl:GetChessEnemy():AddAction(action, false)
end

-- 面相角色
function XChessBoss:TurnRoundRole()
    local roleDic = self._OwnControl:GetChessGamer():GetRoleDict()
    for _, role in pairs(roleDic) do
        if not role:IsSupport() then
            local posX, posY = role:GetPos()
            self._Imp.Weapon:TurnRound(posX, posY)
        end
    end
end

-- 是否为敌方棋子
function XChessBoss:IsPiece()
    return true
end

-- 是否为Boss
function XChessBoss:IsBoss()
    return true
end

-- 获取被攻击次数
function XChessBoss:GetAttackTimes()
    return self._AttackedTimes
end

function XChessBoss:AttackEd(damage, isDizzy, isOneShotKill, actorId, hitRoundCount)
    --已经被击杀了
    if self._Life <= 0 then
        return false
    end
    self._HitActorId = actorId
    self._HitRoundCount = hitRoundCount
    self._IsDizzy = isDizzy
    self._IsOnShotKill = isOneShotKill
    if self._Imp then
        self._AttackedTimes = self._AttackedTimes + 1
    end
    
    --无敌
    local isInvincible = self:IsInvincible(self._AttackedTimes)
    if isInvincible then
        return true
    end
    
    -- 受击动画
    self:GetImp():PlayAnimation("Hit")
    self._IsAttacked = true
    self._LuaWeapon:PlayAttacked()
    
    self._Life = math.max(0, self._Life - damage)
    if self._Life <= 0 or isOneShotKill then
        self._OwnControl:AddKillCount(self:GetPieceType(), actorId)
        return true
    end

    return true
end

--是否无敌
function XChessBoss:IsInvincible(attackedTimes)
    for _, buff in pairs(self._BuffList) do
        local buffCfg = self._OwnControl:GetBuffConfig(buff.BuffId)
        -- 确认是否作用在boss上
        local isTargetBoss = false
        for _, target in pairs(buffCfg.TargetType) do
            if target ==  XEnumConst.BLACK_ROCK_CHESS.BUFF_TARGET_TYPE.BOSS then
                isTargetBoss = true
            end
        end
        if isTargetBoss and buff.Count > 0 then
            -- 免疫攻击次数的buff
            if buffCfg.Type == XEnumConst.BLACK_ROCK_CHESS.BUFF_TYPE.INVINCIBLE_ATTACK_CNT then
                if attackedTimes <= buffCfg.Params[1] then
                    return true
                end
            end
        end
    end

    return false
end

function XChessBoss:LookAt(col, row)
    if not self._Imp then
        return
    end
    self._Imp.Weapon:TurnRound(col, row)
end

function XChessBoss:TriggerAttackedBuff(actorId)
    --一击必杀buff失效
    if self._IsOnShotKill then
        return false
    end
    --黑格buff失效
    if actorId and actorId > 0 then
        local actor = self._OwnControl:GetChessGamer():GetRole(actorId)
        if actor and actor:IsSilentAttackedBuff() then
            return false
        end
    end
    local isInvincible = false
    for _, buff in pairs(self._BuffDict) do
        if buff:IsEffectiveByAttacked() then
            --触发每个buff
            self:TakeBuffEffect(buff, actorId, true)
            if buff:CheckIsImmuneInjury() then
                isInvincible = true
            end
        end
    end

    return isInvincible
end

function XChessBoss:GetIconFollow()
    if not self._Imp then
        return
    end
    return self._Imp.transform
end

function XChessBoss:OnSkillHit()
    local hitEffectId = self._OwnControl:GetHitEffectId(self:GetPieceType())
    self:OnSkillHitManual(hitEffectId)
end

function XChessBoss:OnSkillHitManual(hitEffectId)
    self:LoadEffect(hitEffectId)
    if self._IsDizzy then
        self:LoadEffect(self._OwnControl:GetDizzyEffectId())
    end
    --更新特效显示
    self:DoProcessBuffEffect()

    local isDead = not self:IsAlive()
    if isDead then
        self:DoDead()
    end
end

function XChessBoss:DoDead()
    if self._IsPlayDead then
        return
    end

    self._IsPlayDead = true
    --倒地动画
    self:PlayAnimation("Death")
    --播放音效
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_BREAK)
    local playDelay = self._OwnControl:GetDeadEffectDelay(1)
    --延时加载死亡特效
    self:LoadEffect(self._OwnControl:GetDeadEffectId(), nil, nil, true, playDelay)
    local hideDelay = self._OwnControl:GetDeadEffectDelay(2)
    --等待特效播放完毕摧毁棋子
    self:ClearHideTimer()
    self.HideTimer = XScheduleManager.ScheduleOnce(function()
        if not self._Imp then
            return
        end
        self:Hide()
        self._OwnControl:GetChessEnemy():ProcessPieceEffect()
    end, hideDelay)

    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XChessBoss:Hide()
    self._Imp.gameObject:SetActiveEx(false)
    self._Imp:HideAllEffect()
    self:ClearAllEffect()
end

function XChessBoss:ClearHideTimer()
    if self.HideTimer then
        XScheduleManager.UnSchedule(self.HideTimer)
        self.HideTimer = nil
    end
end

-- 回合开始，处理Buff特效
function XChessBoss:DoProcessBuffEffect()
    if not self._Imp then
        return
    end
    if not self:IsPiece() then
        return
    end
    for _, buff in pairs(self._BuffDict) do
        if not buff then
            goto continue
        end
        local isImmuneInjury = buff:CheckIsImmuneInjury()
        local effectId = self._OwnControl:GetBuffEffectId(buff.Id)
        --只处理无敌的特效，本期暂无其他特效
        if not isImmuneInjury then
            if XTool.IsNumberValid(effectId) then
                self:HideEffect(effectId)
            end
            goto continue
        end

        if not XTool.IsNumberValid(effectId) then
            XLog.Error("Buff加载特效失败，Buff的特效Id配置为0, BuffId = " .. buff.Id)
            goto continue
        end
        self:LoadEffect(effectId)
        ::continue::
    end
end

function XChessBoss:GetPieceType()
    return 1 -- TODO
end

-- 刷新特效
function XChessBoss:RefreshEffects()
    -- 延迟伤害特效
    self:RefreshDelayDamageEffects()
    -- 眩晕动画
    self:RefreshDizzyAnim()
    -- 技能特效
    if self._LuaWeapon then
        self._LuaWeapon:RefreshSkillEffects()
    end
end

-- 显示延迟伤害特效
function XChessBoss:RefreshDelayDamageEffects()
    if not self._LuaWeapon then return end
    
    local points = self._LuaWeapon:GetDelayDamagePoints()
    if points and #points > 0 then
        self.DelayDamageEffectGos = self.DelayDamageEffectGos or {}
        if not self.EffectRoot then
            local battleScene = self._OwnControl:GetBattleScene()
            self.EffectRoot = battleScene:TryFind("GroupDynamic/EffectRoot")
        end
        local cfg = CS.XBlackRockChess.XBlackRockChessUtil.GetChessEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.DELAY_DAMAGE_WARNING)
        local effectPath = cfg.EffectPrefab
        for i, point in ipairs(points) do
            local go = self.DelayDamageEffectGos[i]
            if not go then
                go =  CS.UnityEngine.GameObject("BossEffect", typeof(CS.UnityEngine.RectTransform))
                go.transform:SetParent(self.EffectRoot.transform, false)
                table.insert(self.DelayDamageEffectGos, go)
            end
            go.gameObject:SetActiveEx(true)
            -- 刷新位置
            local worldPos = CS.XBlackRockChess.XBlackRockChessUtil.Convert2WorldPoint(point)
            go.transform.position = worldPos
            -- 加载特效
            go:LoadPrefab(effectPath, false)
        end

        -- 隐藏多余特效
        for i = #points + 1, #self.DelayDamageEffectGos do
            self.DelayDamageEffectGos[i].gameObject:SetActiveEx(false)
        end
    else
        self:RecycleDelayDamageEffect()
    end
end

-- 回收延迟伤害特效
function XChessBoss:RecycleDelayDamageEffect()
    if self.DelayDamageEffectGos then
        for _, go in ipairs(self.DelayDamageEffectGos) do
            go.gameObject:SetActiveEx(false)
        end
    end
end

-- 刷新锁定格子特效
function XChessBoss:LoadLockGridEffects(points)
    if not self._LuaWeapon then return end
    if points then
        self.LockGridEffectGos = self.LockGridEffectGos or {}
        if not self.EffectRoot then
            local battleScene = self._OwnControl:GetBattleScene()
            self.EffectRoot = battleScene:TryFind("GroupDynamic/EffectRoot")
        end
        local cfg = CS.XBlackRockChess.XBlackRockChessUtil.GetChessEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.ZHETIAN_BIGSKILLSKILL_LOCK_GRID)
        local effectPath = cfg.EffectPrefab
        for i, point in ipairs(points) do
            local go = self.LockGridEffectGos[i]
            if not go then
                go =  CS.UnityEngine.GameObject("BossEffect", typeof(CS.UnityEngine.RectTransform))
                go.transform:SetParent(self.EffectRoot.transform, false)
                table.insert(self.LockGridEffectGos, go)
            end
            go.gameObject:SetActiveEx(true)
            -- 刷新位置
            local worldPos = CS.XBlackRockChess.XBlackRockChessUtil.Convert2WorldPoint(point)
            go.transform.position = worldPos
            -- 加载特效
            go:LoadPrefab(effectPath, false)
        end

        -- 隐藏多余特效
        for i = #points + 1, #self.LockGridEffectGos do
            self.LockGridEffectGos[i].gameObject:SetActiveEx(false)
        end
    else
        self:RecycleLockGridEffects()
    end
end

-- 回收延迟伤害特效
function XChessBoss:RecycleLockGridEffects()
    if self.LockGridEffectGos then
        for _, go in ipairs(self.LockGridEffectGos) do
            go.gameObject:SetActiveEx(false)
        end
    end
end

-- 清理所有特效
function XChessBoss:ClearAllEffect()
    if self.DelayDamageEffectGos then
        for _, go in ipairs(self.DelayDamageEffectGos) do
            CS.UnityEngine.Object.Destroy(go)
        end
        self.DelayDamageEffectGos = nil
    end
    if self.LockGridEffectGos then
        for _, go in ipairs(self.LockGridEffectGos) do
            CS.UnityEngine.Object.Destroy(go)
        end
        self.LockGridEffectGos = nil
    end
end

-- 是否处于移动强化状态
function XChessBoss:IsInMoveStrengthen()
    return self._LuaWeapon:IsInMoveStrengthen()
end

-- 是否处于技能强化状态
function XChessBoss:IsInSkillStrengthen(skillId)
    return self._LuaWeapon:IsInSkillStrengthen(skillId)
end

-- 刷新眩晕动画
function XChessBoss:RefreshDizzyAnim()
    self.IsDizzyAnim = self.IsDizzyAnim or false
    local isDizzy = self:IsDizzy()
    if isDizzy ~= self.IsDizzyAnim and self._Imp then
        if isDizzy then
            self._Imp:PlayAnimation("Stand02")
        else
            self._Imp:PlayAnimation("Stand")
        end
        self.IsDizzyAnim = not self.IsDizzyAnim
    end
end

function XChessBoss:IsPreviewDead()
    return false
end

-- 显示延迟技能喊话
function XChessBoss:ShowDelaySkillTalk()
    -- 没有延迟技能信息，不显示喊话
    local delayInfo = self:GetDelaySkillInfo()
    if not delayInfo then return end

    -- 黑遮天和白遮天的大招第一段延迟不显示喊话
    local skillId = delayInfo.SkillId
    local count = delayInfo.Count
    local delayRound = delayInfo.DelayRound
    local skillType = self._OwnControl:GetWeaponSkillType(skillId)
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_BLACK_BIGSKILL or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.ZHETIAN_WHITE_BIGSKILL then
        local SUMMOM_COUNT = 1 --第一阶段是召唤，不显示喊话
        if count == SUMMOM_COUNT then return end
    end

    -- 获取喊话配置表
    local growlsCfg = self._OwnControl:GetChessGrowlsConfig(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.BOSS, skillType, self._RoleId, delayRound)
    if not growlsCfg then return end
    
    local cvId = nil
    local text = nil
    for i, triggerArg in ipairs(growlsCfg.TriggerArgs) do
        if triggerArg == delayRound then
            cvId = growlsCfg.CvIds[i]
            text = growlsCfg.Text[i]
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_TALK, self._RoleId, cvId, text, growlsCfg.Duration)
end

-- 显示释放技能喊话
function XChessBoss:ShowPlaySkillTalk()
    local skillId = self._LuaWeapon:GetSkillId()
    local skillType = self._OwnControl:GetWeaponSkillType(skillId)

    -- 获取喊话配置表
    local growlsCfg = self._OwnControl:GetChessGrowlsConfig(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.BOSS, XMVCA.XBlackRockChess.GrowlsTriggerType.UseSkill, self._RoleId, skillType)
    if not growlsCfg then return end
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_TALK, self._RoleId, growlsCfg.CvIds[1], growlsCfg.Text[1], growlsCfg.Duration)
end

return XChessBoss