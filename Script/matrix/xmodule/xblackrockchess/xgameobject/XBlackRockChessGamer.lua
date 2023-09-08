-- 武器类型
local WeaponType = {
    -- 霰弹枪
    Shotgun = 1,
    -- 小刀
    Knife = 2,
}

local SkillSearchCount = {
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL1] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL2] = 9,
    
}

---@class XBlackRockChessGamer 玩家
---@field _Id number
---@field _Imp XBlackRockChess.XChessGamer
---@field _X number x坐标
---@field _Y number y坐标
---@field _WeaponType number 武器Id
---@field _Energy number 能量值
---@field _ReviveCount number 复活次数
---@field _Control XBlackRockChessControl
---@field _AttackedPiece XBlackRockChessPiece[] 主动技能攻击到棋子对象
local XBlackRockChessGamer = XClass(nil, "XBlackRockChessGamer")

function XBlackRockChessGamer:Ctor(controlId, control)
    self._Id = XEnumConst.BLACK_ROCK_CHESS.PLAYER_MEMBER_ID
    self._ControlId = controlId
    self._Control = control
    self._PassiveSkill = {}
    
    --玩家操作动作
    self._ActionDict = {}
    --玩家操作回合
    self._HandleRound = 1
end

function XBlackRockChessGamer:SetImp(imp)
    self._Imp = imp
    self._Imp:InitParams(self._Id)
    self._Imp:RegisterOnMoveEnd(handler(self, self.OnMoveEnd))
    self._Imp:RegisterOnChangedTarget(handler(self, self.OnFocusEnemy))
    self._Imp:RegisterOnKickback(handler(self, self.OnKickback))
    self._Imp.IsExtraRound = function() 
        return self:IsExtraTurn()
    end
    local prefab, lineHigh, roleHigh, count = self._Control:GetLineRenderProperty()
    self._Imp:InitLine(lineHigh, roleHigh, count, prefab)
    -- fix weapon select
    if (self._WeaponType == WeaponType.Shotgun and self._Imp.IsKnife)
            or (self._WeaponType == WeaponType.Knife and self._Imp.IsShotgun) then
        self._Imp:SwitchWeapon()
    end
    self:InitSkill()
    
    local buffDict = self._Control:GetGlobalBuffDict()
    for _, data in pairs(buffDict) do
        self:ApplyBuff(data.Id, data.Overlays)
    end
end

function XBlackRockChessGamer:InitSkill()
    if not self._Imp then
        return
    end
    local weaponIds = self._Control:GetWeaponIds()
    for _, weaponId in ipairs(weaponIds) do
        local weaponType = self._Control:GetWeaponType(weaponId)
        local skillIds = self._Control:GetWeaponSkillIds(weaponId)
        for _, skillId in ipairs(skillIds) do
            local range = self._Control:GetWeaponSkillRange(skillId)
            local skillType = self._Control:GetWeaponSkillType(skillId)
            local searchCount = SkillSearchCount[skillType] or 0
            local isDizzy = self._Control:IsDizzy(skillId)
            local extraTurn = self._Control:GetWeaponSkillExtraTurn(skillId)
            local isPenetrate = self._Control:GetWeaponSkillIsPenetrate(skillId)
            local skill
            if weaponType == WeaponType.Shotgun then
                skill = self._Imp:AddShotgunSkill(skillType)
            else
                skill = self._Imp:AddKnifeSkill(skillType)
            end
            skill:InitBaseParam(skillId, self._Control:GetWeaponSkillCost(skillId, true), range, isDizzy, extraTurn, isPenetrate)
            skill:CreateSputtering(searchCount)
        end
    end
end

function XBlackRockChessGamer:ApplyBuff(buffId, overlays)
    local targetType = self._Control:GetBuffTargetType(buffId)
    local isTarget = false
    for _, target in pairs(targetType) do
        if target == XEnumConst.BLACK_ROCK_CHESS.PLAYER_MEMBER_ID then
            isTarget = true
            break
        end
    end
    if not isTarget then
        return
    end
    local type = self._Control:GetBuffType(buffId)
    local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(type)
    local args = self._Control:GetBuffParams(buffId)
    for i = 1, overlays do
        buff:Apply(buffId, self._Imp.Knife, table.unpack(args))
        buff:Apply(buffId, self._Imp.Shotgun, table.unpack(args))
    end
end

--- 主动技能由TimeLine驱动，被动技能手动执行
function XBlackRockChessGamer:StartAttack(skillId)
    local effectIds = self._Control:GetWeaponEffectIds(skillId)
    local delays = self._Control:GetWeaponEffectDelay(skillId)
    local skillType = self._Control:GetWeaponSkillType(skillId)
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL1
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL2 then
        local fire, delayFire = effectIds[1], delays[1]
        local bullet, delayBullet = effectIds[2], delays[2]

        self:LoadEffect(fire, nil, nil, delayFire)
        self:FireEffect(bullet, nil, nil, delayBullet, self._ShotCenter, function()
            self:PlayPieceHit(skillId)
            self._Control:PlaySound(self._Control:GetWeaponSkillHitCueId(skillId))
        end)
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL2 then
        local fire, delayFire = effectIds[1], delays[1]
        self:LoadEffect(fire, nil, nil, delayFire)
        self:PlayPieceHit(skillId)
    else
        local fire, delayFire = effectIds[1], delays[1]
        local rotate = self._Imp.transform.localEulerAngles.y
        --跟玩家的旋转抵消
        self:LoadEffect(fire, nil, CS.UnityEngine.Vector3(0, -rotate, 0), delayFire)
    end
    self._Control:PlaySound(self._Control:GetWeaponSkillCueId(skillId))
end

function XBlackRockChessGamer:PlayPieceHit(skillId)
    if XTool.IsTableEmpty(self._AttackedPiece) then
        return
    end
    local hitEffectIds = self._Control:GetWeaponHitEffectIds(skillId)
    local hitPos = self._Imp.MovePoint
    if not XTool.IsTableEmpty(hitEffectIds) then
        --加载武器攻击特效
        for _, piece in pairs(self._AttackedPiece) do
            for _, effectId in pairs(hitEffectIds) do
                piece:PlayHit(effectId, hitPos)
            end
        end

        self._AttackedPiece = {}
        return
    end
    --若武器没有攻击特效
    for _, piece in pairs(self._AttackedPiece) do
        piece:PlayHit(0, hitPos)
    end
    self._AttackedPiece = {}
end

function XBlackRockChessGamer:OnSelectSkill(skillIndex)
    if not self._Imp then
        return
    end
    skillIndex = skillIndex - 1
    self._Imp:OnSelectSkill(skillIndex)
    self:OnFocusEnemy(skillIndex)
end

function XBlackRockChessGamer:OnFocusEnemy(skillIndex)
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.CHANGE_PIECE_TARGET)
    ---@type XBlackRockChess.XSkill
    local skill = self._Imp.Current:GetSkillByIndex(skillIndex)
    if skill:IsPassive() then
        return
    end
    local center = skill.ShotCenter
    local piece = self._Control:PieceAtCoord(center)
    if piece and piece.IsPiece and piece:IsPiece() then
        self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.FOCUS_ENEMY, piece:GetId())
    end
    local sputtering = self._Imp.Sputtering
    for i = 0, sputtering.Count - 1 do
        local pos = sputtering[i]
        local tPiece = self._Control:PieceAtCoord(pos)
        if tPiece and tPiece.IsPiece and tPiece:IsPiece() then
            local isInvincible = tPiece:IsInvincible()
            tPiece:LookAt(self:GetWorldPosition())
            local damage = isInvincible and 0 or self:GetSkillDamage(skill.Id, CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(pos, center), self:IsExtraTurn())
            self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.PREVIEW_DAMAGE, 
                    tPiece:GetId(),
                    damage
                    
            )
        end
    end
end

--- 使用被动技能
---@param skill XBlackRockChess.XSkill
--------------------------
function XBlackRockChessGamer:UsePassiveSkill(skill)
    local params = self._Control:GetWeaponSkillParams(skill.Id)
    local addMoveRange = params[1]
    skill.AddMoveRange = skill.AddMoveRange + addMoveRange
    skill.UseCount = skill.UseCount + 1
    
    self._PassiveSkill[skill.Id] = skill.UseCount
    
    self._Imp:ApplyPassiveSkill(skill)
    self:StartAttack(skill.Id)
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PASSIVE_SKILL, false, skill.Id, skill.UseCount, self._HandleRound)
    self._Control:PlaySound(self._Control:GetWeaponSkillCueId(skill.Id))
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_BUFF_HUD, self._Id, self._Imp.transform, skill.Id, skill.UseCount)
end

--- 使用主动技能
---@param skill XBlackRockChess.XSkill
---@return boolean 是否攻击到人了
--------------------------
function XBlackRockChessGamer:UseActiveSkill(skill)
    -- 攻击中心
    local center = skill.ShotCenter
    self._ShotCenter = center
    self._AttackedPiece = {}
    -- 溅射点
    local sputtering = self._Imp.Sputtering
    local isAttack = false
    for i = 0, sputtering.Count - 1 do
        local vec2Int = sputtering[i]
        local piece = self._Control:PieceAtCoord(vec2Int)
        if piece and piece:IsPiece() then
            local damage = self:GetSkillDamage(skill.Id, CS.XBlackRockChess.XBlackRockChessUtil.EqualVec2Int(center, vec2Int),
                    self:IsExtraTurn())
            local attacked = piece:AttackEd(damage, skill.IsDizzy, skill.Id, self._Imp:IsFront(vec2Int))
            --XLog.Error("对棋子" .. self._Control:GetPieceDesc(piece:GetConfigId()).. "(Id = " .. piece:GetId() .. ")" .. "造成伤害 = " .. tostring(damage) ..  ", 棋子被眩晕：" .. tostring(skill.IsDizzy))
            isAttack = isAttack or attacked
            table.insert(self._AttackedPiece, piece)
        end
    end
    
    skill.UseCount = skill.UseCount + 1
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK, false, self._WeaponId, skill.Id, center.x, center.y, self._HandleRound)
    return isAttack
end

function XBlackRockChessGamer:PlayAnimation(animName, cb)
    if not self._Imp then
        if cb then cb(false) end
    end
    local newCb = function()
        if self._Control then
            self._Control:CancelWaiting()
        end
        if cb then cb() end
    end
    self._Control:ConfirmWaiting()
    self._Imp:PlayAnimation(animName, newCb)
end

function XBlackRockChessGamer:PlayTimeLineAnimation(animName, finishCb)
    if not self._Imp then
        return
    end
    local newCb = function()
        if finishCb then finishCb() end
        
        if self._Control then
            self._Control:CancelWaiting()
        end
    end
    self._Control:ConfirmWaiting()
    self._Imp:PlayTimeLineAnimation(animName, newCb)
end

function XBlackRockChessGamer:OnCancelSkill(isEnterMove)
    if not self._Imp then
        return
    end
    if isEnterMove ~= false then
        isEnterMove = true
    end
    self._Imp:OnCancelSkill(isEnterMove)
end

--- 使用武器技能
---@param skillId number 技能Id
---@return boolean 是否结束回合
--------------------------
function XBlackRockChessGamer:UseWeaponSkill(skillId)
    if not self._Control:CouldUseSkill(skillId) then
        return false
    end
    local skill = self._Imp:GetSkill(skillId)
    if skill.ExtraTurn < 0 then
        XLog.Error("技能额外回合小于0次了")
        return false
    end
    local skillType = self._Control:GetWeaponSkillType(skillId)
    self._Control:ConsumeEnergy(skill.Id)
    --小刀被动技能
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL1 then
        self:UsePassiveSkill(skill)
        return false
    end
    local isAttack = self:UseActiveSkill(skill)
    local extraTurn = skill.ExtraTurn
    skill.ExtraTurn = skill.ExtraTurn - 1
    --重置技能
    self:ResetPassiveSkill()
    --攻击到人 && 额外回合大于 0 && 并切处于非额外回合
    if isAttack and extraTurn > 0 and not self:IsExtraTurn() then
        ----进入额外回合恢复能量
        --self._Control:AddEnergyWhenRound()
        self._HandleRound = self._HandleRound + 1
        self._Control:UpdateIsExtraRound()
        --同步一下位置，可以重新移动了
        self._Imp:SyncLocation()
        self._Imp:ResetSkill()
        --重新选中敌人
        --self._Imp:OnSelectSkillById(skillId)
        local isEnd = self._Control:IsFightingStageEnd()
        return isEnd
    end
    return true
end

function XBlackRockChessGamer:GetSkill(skillId)
    return self._Imp and self._Imp:GetSkill(skillId) or nil
end

function XBlackRockChessGamer:IsExtraTurn()
    return self._HandleRound > 1
end

function XBlackRockChessGamer:IsUsePassiveSkill()
    return not XTool.IsTableEmpty(self._PassiveSkill)
end

function XBlackRockChessGamer:GetSkillDamage(skillId, isCenter, isExtraTurn)
    local damage = 0
    local skillType = self._Control:GetWeaponSkillType(skillId)
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL1
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL2 then
        local params = self._Control:GetWeaponSkillParams(skillId)
        damage = isCenter and params[1] or params[2]
    elseif skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK 
            or skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL2 then
        local params = self._Control:GetWeaponSkillParams(skillId)
        local addDamage = params[3]
        damage = isExtraTurn and params[1] + addDamage or params[1]
    end

    for id, count in pairs(self._PassiveSkill) do
        local type = self._Control:GetWeaponSkillType(id)
        if type == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL1 then
            local params = self._Control:GetWeaponSkillParams(id)
            local addDamage = params[2] * count
            damage = damage + addDamage
        end
    end

    return math.max(0, damage)
end

function XBlackRockChessGamer:Release()
    self._Imp = nil
    self._PassiveSkill = {}
    self._ActionDict = {}
    self._HandleRound = 1
    self._Control:UpdateIsExtraRound()
    self._Control = nil
end

function XBlackRockChessGamer:SwitchWeapon()
    if not self._Imp then
        return
    end
    self._WeaponType = self:IsShotgun() and WeaponType.Knife or WeaponType.Shotgun
    self._WeaponId = self._Control:GetWeaponIdByType(self._WeaponType)
    self._Imp:SwitchWeapon()
end

function XBlackRockChessGamer:IsShotgun()
    return self._Imp.IsShotgun and self._WeaponType == WeaponType.Shotgun
end

function XBlackRockChessGamer:IsKnife()
    return self._Imp.IsKnife and self._WeaponType == WeaponType.Knife
end

function XBlackRockChessGamer:UpdateData(formation)
    self._X = formation.X
    self._Y = formation.Y
    local data = formation.CharacterInfo
    self._WeaponId = data.WeaponId
    self._WeaponType = self._Control:GetWeaponType(data.WeaponId)
    self._Energy = data.Energy
    self._Control:UpdateEnergy()
    self._ReviveCount = data.ReviveTimes
end

function XBlackRockChessGamer:GetReviveCount()
    return self._ReviveCount
end

function XBlackRockChessGamer:SetRevive()
    self._IsRevive = true
    local count = self._Control:GetGamerLeftReviveCount()
    if count < 0 then
        self._Control:EndGamerRound()
        return
    end
    --复活次数 + 1
    self._ReviveCount = self._ReviveCount + 1
    self._Control:BroadcastReviveCount(self._ReviveCount)
    self._Imp:Revive()
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE, false, self._Imp.RevivePoint.x, self._Imp.RevivePoint.y)
end

--当前回合是否复活
function XBlackRockChessGamer:IsRevive()
    return self._IsRevive
end

function XBlackRockChessGamer:GetCoordinate()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.Current.Coordinate
end

function XBlackRockChessGamer:GetMovePoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.Current.MovePoint
end

function XBlackRockChessGamer:GetWorldPosition()
    local point = self:GetMovePoint()
    
    return CS.XBlackRockChess.XBlackRockChessUtil.Convert2WorldPoint(point.x, point.y)
end

function XBlackRockChessGamer:OnRoundBegin()
    if not self._Imp then
        return
    end
    self._Imp:OnRoundBegin()
    self._Control:BroadcastRound(true, false)
end

function XBlackRockChessGamer:OnRoundEnd()
    if not self._Imp then
        return
    end
    self._HandleRound = 1
    self._Imp:OnRoundEnd()
    --玩家操作完成后显示遮罩
    if not XLuaUiManager.IsMaskShow(XEnumConst.BLACK_ROCK_CHESS.MASK_KEY) then
        XLuaUiManager.SetMask(true, XEnumConst.BLACK_ROCK_CHESS.MASK_KEY)
    end
end

function XBlackRockChessGamer:OnMoveEnd(x, y)
    if not self._Imp then
        return
    end
    local isRemove = x == self._Imp.Coordinate.x and y == self._Imp.Coordinate.y
    
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE, isRemove, x, y, self._WeaponId, self._HandleRound)
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_GAMER_MOVE_END)
end

function XBlackRockChessGamer:IsMoving()
    if not self._Imp then
        return false
    end
    return self._Imp.Current:IsMoving()
end

function XBlackRockChessGamer:OnForceEndRound()
    self:ResetPassiveSkill()
    self:AddAction(XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND, false, self._WeaponId)
end

function XBlackRockChessGamer:GetActionList()
    if not self._Imp then
        return { }
    end
    -- 服务端校验有顺序要求
    -- 单个 handle round 里 被动 > 移动 > 攻击(强制结束回合)
    -- 整个回合里 复活在最后
    
    -- 在敌人操作之前的动作，在敌人操作之后的动作
    local beforeEnemy, afterEnemy = {}, {}
    for _, dict in pairs(self._ActionDict) do
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PASSIVE_SKILL])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND])
        
        table.insert(afterEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE])
    end
    return beforeEnemy, afterEnemy
end

function XBlackRockChessGamer:AddAction(actionType, isRemove, ...)
    if not self._ActionDict[self._HandleRound] then
        self._ActionDict[self._HandleRound] = {}
    end
    if isRemove then
        self._ActionDict[self._HandleRound][actionType] = nil
    else
        self._ActionDict[self._HandleRound][actionType] = {
            ObjId = self._Id,
            ActionType = actionType,
            Params = { ... }
        }
    end
end

function XBlackRockChessGamer:SyncLocation()
    if not self._Imp then
        return
    end
    self._Imp:SyncLocation()
end

function XBlackRockChessGamer:RestoreLocation()
    if not self._Imp then
        return
    end
    self._Imp.Coordinate = CS.UnityEngine.Vector2Int(self._X, self._Y)
    self._Imp:RestoreLocation()
end

function XBlackRockChessGamer:SyncSkill()
    self:ResetPassiveSkill()
end

function XBlackRockChessGamer:RestoreSkill()
    self:ResetPassiveSkill()
end

function XBlackRockChessGamer:Sync()
    self._ActionDict = {}
    self._HandleRound = 1
    self._IsRevive = false
    
    self:SyncLocation()
    self:SyncSkill()
    
    self._Control:UpdateIsExtraRound()
end

function XBlackRockChessGamer:Restore()
    self._ActionDict = {}
    self._HandleRound = 1
    self._IsRevive = false
    self:RestoreLocation()
    self:RestoreSkill()
    self._Imp.gameObject:SetActiveEx(true)

    self._Control:UpdateIsExtraRound()
end

function XBlackRockChessGamer:GetWeaponId()
    return self._WeaponId
end

function XBlackRockChessGamer:GetPos()
    return self._X, self._Y
end

function XBlackRockChessGamer:GetId()
    return self._Id
end

function XBlackRockChessGamer:GetEnergy()
    return self._Energy
end

function XBlackRockChessGamer:ConsumeEnergy(cost)
    local energy = math.max(0, self._Energy - cost)
    energy = math.min(energy, self._Control:GetMaxEnergy())
    self._Energy = energy
    self._Control:UpdateEnergy()
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessGamer:DoWin()
    if not self._Imp then
        return
    end
    local col, row, angleY = self._Control:GetViewOfWin()
    self._Imp:DoWin(col, row, angleY)
    self._Control:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.GAME_WIN)
end

function XBlackRockChessGamer:LoadEffect(effectId, offset, rotate, delay)
    self._Control:LoadEffect(self._Imp, effectId, offset, rotate, delay)
end

function XBlackRockChessGamer:FireEffect(effectId, offset, rotate, delay, shotCenter, hitCb)
    self._Control:FireEffect(self._Imp, effectId, offset, rotate, delay, shotCenter, hitCb)
end

function XBlackRockChessGamer:ShowDialog(text)
    if not self._Imp then
        return
    end
    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.SHOW_DIALOG_BUBBLE, self._Imp.transform, text)
end

function XBlackRockChessGamer:OnKickback()
    self:ShowDialog(self._Control:GetWeaponMoveText(1))
end

function XBlackRockChessGamer:ResetPassiveSkill()
    self._PassiveSkill = {}

    self._Control:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.HIDE_BUFF_HUD, self._Id)
end

return XBlackRockChessGamer