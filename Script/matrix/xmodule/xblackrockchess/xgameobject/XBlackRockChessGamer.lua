
---@class XBlackRockChessGamer : XEntityControl 玩家
---@field _MainControl XBlackRockChessControl
---@field _Imp XBlackRockChess.XChessGamer
---@field _RoleDict table<number, XChessActor>
local XBlackRockChessGamer = XClass(XEntityControl, "XBlackRockChessGamer")
local XChessActor = require("XModule/XBlackRockChess/XGameObject/XChessActor")

function XBlackRockChessGamer:OnInit()
    self._RoleDict = {}
    self._Energy = 0 --玩家能量条
    self._ReviveTimes = 0 --玩家复活次数
    self._KillData = {} --玩家击杀数据 Key = pieceType Value = Count
end

function XBlackRockChessGamer:SetImp(imp)
    --避免重复设置
    if self._Imp then
        return
    end
    self._Imp = imp
end

function XBlackRockChessGamer:DoEnterFight()
    local roleDict = self:GetRoleDict()
    --玩家角色布局
    for roleId, role in pairs(roleDict) do
        local x, y = role:GetPos()
        local weaponId = role:GetWeaponId()
        local weaponType = self._MainControl:GetWeaponType(weaponId)
        local weaponSkills = self._MainControl:GetWeaponSkillIds(weaponId)
        local moveRange = self._MainControl:GetWeaponMoveRange(weaponId)
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddGamer(self._MainControl:GetRoleModelUrl(roleId), 
                x, y, weaponId, weaponType, #weaponSkills, moveRange)
        if not imp then
            XLog.Error("加载角色" .. roleId .. "失败")
        else
            role:SetImp(imp)
        end
    end
    --应用Buff
    self:ApplyBuff()
    --开始玩家回合
    self:OnRoundBegin()
end

function XBlackRockChessGamer:ApplyBuff()
    --全局Buff
    local buffData = self._MainControl:GetGlobalBuffDict()
    for _, data in pairs(buffData) do
        if not self:CheckIsActorBuff(data.Id) then
            goto continue
        end
        local buff = self:CreateBuff(data.Id)
        if not buff then
            goto continue
        end
        buff:AddTakeEffectCb(handler(self, self.OnBuffTakeEffect))
        
        if buff:IsEffectiveByStageInit() then
            local overlays = data.Overlays
            for i = 1, overlays do
                buff:TakeEffect()
            end
        end

        ::continue::
    end
end

function XBlackRockChessGamer:CreateBuff(buffId, imp)
    if not XTool.IsNumberValid(buffId) then
        return
    end
    local buffType = self._MainControl:GetBuffType(buffId)
    local buff = CS.XBlackRockChess.XBlackRockChessUtil.CreateBuff(buffType)
    if buff then
        local args = self._MainControl:GetBuffParams(buffId)
        buff:Apply(buffId, imp, table.unpack(args))
    end

    return buff
end

function XBlackRockChessGamer:OnBuffTakeEffect(args)
    local buffId, buffType = args[0], args[1]
    if buffType == XMVCA.XBlackRockChess.BuffType.SkillEnergyCostAdd then
        local count, roleId = args[2], args[3]
        self:GetRole(roleId):AddSkillCost(count)
    elseif buffType == XMVCA.XBlackRockChess.BuffType.InitContinuationRound then
        local count, roleId = args[2], args[3]
        self:GetRole(roleId):SetBuffContinuationRound(count)
    end
end

function XBlackRockChessGamer:CheckIsActorBuff(buffId)
    if not XTool.IsNumberValid(buffId) then
        return false
    end
    local targetTypes = self._MainControl:GetBuffTargetType(buffId)
    if XTool.IsTableEmpty(targetTypes) then
        return false
    end

    for _, targetType in ipairs(targetTypes) do
        -- -1为角色专属
        if targetType == -1 then
            return true
        end
    end
    return false
end

function XBlackRockChessGamer:OnRoundBegin()
    if not self._Imp then
        return
    end

    self._BeforeEnemy = {} --在敌人行动之前的动作列表
    self._AfterEnemy = {}  --在敌人行动之后的动作列表
    self._ActionId = 1
    self._Imp:OnRoundBegin()
    self._MainControl:BroadcastRound(true, false)
    self._MainControl:SetGameRound(true)
    --回合开始默认选中
    self._CurSelectId = self._MainControl:GetMasterRoleId()
    self._Model:UpdateSelectActor(self._CurSelectId)
    local actor = self:GetRole(self._CurSelectId)
    actor:CallCOnClick()
end

function XBlackRockChessGamer:OnRoundEnd()
    if not self._Imp then
        return
    end
    self._MainControl:SetGameRound(false)
    self._Imp:OnRoundEnd()
    for _, role in pairs(self._RoleDict) do
        role:OnEndOfTurn()
    end
end

function XBlackRockChessGamer:IsAllActorOperaEnd()
    local isEnd = true
    for _, role in pairs(self._RoleDict) do
        if not role:IsOperaEnd() then
            isEnd = false
            break
        end
    end
    return isEnd
end

--强制回合结束
function XBlackRockChessGamer:DoForceEndOfTurn()
    for _, role in pairs(self._RoleDict) do
        role:OnForceEndOfTurn()
    end
    self:UpdateActionId(1)
end

function XBlackRockChessGamer:GetEnergy()
    return self._Energy
end

function XBlackRockChessGamer:GetReviveCount()
    return self._ReviveTimes
end

function XBlackRockChessGamer:Revive(roleId)
    local actor = self:GetRole(roleId)
    if not actor or actor:IsSupport() then
        return
    end
    self:DoWalkOut()
    actor:Revive()
    self._ReviveTimes = self._ReviveTimes + 1
    self._MainControl:BroadcastReviveCount(self._ReviveTimes)
end

--所有支援角色退场
function XBlackRockChessGamer:DoWalkOut()
    for _, actor in pairs(self._RoleDict) do
        if actor and actor:IsSupport() then
            actor:PlayWalkOut()
        end
    end
end

function XBlackRockChessGamer:IsRevive()
    for _, role in pairs(self._RoleDict) do
        if role:IsRevive() then
            return true
        end
    end
    return false
end

function XBlackRockChessGamer:IsTriggerProtect()
    for _, role in pairs(self._RoleDict) do
        if role:IsTriggerProtect() then
            return true
        end
    end
    return false
end

--更新角色信息
function XBlackRockChessGamer:UpdateRole(formation)
    local characterInfo = formation.CharacterInfo or {}
    local characterId = characterInfo.CharacterId
    local role = self._RoleDict[characterId]
    if not role then
        role = self:AddEntity(XChessActor, characterId)
        self._RoleDict[characterId] = role
    end
    role:UpdateData(formation)
end

--悔棋
function XBlackRockChessGamer:RetractRole(formation)
    local characterInfo = formation.CharacterInfo or {}
    local characterId = characterInfo.CharacterId
    local role = self._RoleDict[characterId]
    if role then
        role:Retract(formation)
    end
end

---@param cls any 实体的Class
---@return XChessActor
function XBlackRockChessGamer:AddEntity(cls, ...)
    ---@type XEntity
    local entity = cls.New(self._MainControl)
    local uid = entity:GetUid()

    local minUid = self._TypesMinUid[cls]
    if not minUid or minUid > uid then --记录一个最小id
        self._TypesMinUid[cls] = uid
    end

    self._EntitiesDict[uid] = entity

    local typesDict = self._EntitiesTypesDict[cls]
    if not typesDict then
        typesDict = {}
        self._EntitiesTypesDict[cls] = typesDict
    end

    typesDict[uid] = entity
    entity:__Init(...)
    return entity
end

function XBlackRockChessGamer:UpdateData(energy, reviveTimes, killData)
    self._Energy = energy
    self._ReviveTimes = reviveTimes
    self._KillData = killData
end

function XBlackRockChessGamer:GetRoleDict()
    return self._RoleDict
end

function XBlackRockChessGamer:GetRoleIds()
    local ids = {}
    for id, _ in pairs(self._RoleDict) do
        table.insert(ids, id)
    end
    return ids
end

---@type XChessActor
function XBlackRockChessGamer:GetRole(roleId)
    local actor = self._RoleDict[roleId]
    if not actor then
        XLog.Error("未初始化角色数据， 角色id = " .. roleId)
        return
    end
    return actor
end

function XBlackRockChessGamer:GetSelectActor()
    return self:GetRole(self._CurSelectId)
end

function XBlackRockChessGamer:UpdateSelect(roleId)
    if self._CurSelectId ~= roleId and XTool.IsNumberValid(self._CurSelectId) then
        self:GetRole(self._CurSelectId):DoCancelSelect()
    end
    self._CurSelectId = roleId
    self._Model:UpdateSelectActor(roleId)
    self._MainControl:DispatchEvent(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_ID.REFRESH_SELECT_ROLE, roleId)
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    
    self._MainControl:ManualTriggeringGuide()
end

function XBlackRockChessGamer:GetActionList()
    if not self._Imp then
        return {}
    end
    -- 服务端校验有顺序要求
    -- 单个 handle round 里 被动 > 移动 > 攻击(强制结束回合)
    -- 整个回合里 复活在最后

    -- 在敌人操作之前的动作，在敌人操作之后的动作
    local beforeEnemy, afterEnemy = {}, {}
    for actionId, dict in pairs(self._BeforeEnemy) do
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.PASSIVE_SKILL])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.MOVE])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.ATTACK])
        table.insert(beforeEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.SKIP_ROUND])
    end

    for actionId, dict in pairs(self._AfterEnemy) do
        table.insert(afterEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE])
        table.insert(afterEnemy, dict[XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_SKILL])
    end
    return beforeEnemy, afterEnemy
end

function XBlackRockChessGamer:AddAction(action, isRemove)
    if action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_REVIVE
            or action.ActionType == XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE.CHARACTER_SKILL
    then
        local dict = self._AfterEnemy[self._ActionId] or {}
        if isRemove then
            dict[action.ActionType] = nil
        else
            dict[action.ActionType] = action
        end
        self._AfterEnemy[self._ActionId] = dict
    else
        local dict = self._BeforeEnemy[self._ActionId] or {}
        if isRemove then
            dict[action.ActionType] = nil
        else
            dict[action.ActionType] = action
        end
        self._BeforeEnemy[self._ActionId] = dict
    end
end

function XBlackRockChessGamer:UpdateActionId(value)
    if value < 0 then
        self._AfterEnemy[self._ActionId] = nil
        self._BeforeEnemy[self._ActionId] = nil
    end
    self._ActionId = self._ActionId + value
end

function XBlackRockChessGamer:IsMoving()
    for _, role in pairs(self._RoleDict) do
        if role:IsMoving() then
            return true
        end
    end
    return false
end

function XBlackRockChessGamer:CheckIsSkillRunning()
    for _, role in pairs(self._RoleDict) do
        if role:CheckIsSkillRunning() then
            return true
        end
    end
    return false
end

function XBlackRockChessGamer:IsExtraTurn()
    return self._Imp and self._Imp:IsInExtraRound() or false
end

--能量为所有Actor通用
function XBlackRockChessGamer:ConsumeEnergy(cost)
    local energy = math.max(0, self._Energy - cost)
    energy = math.min(energy, self._MainControl:GetMaxEnergy())
    self._Energy = energy
    self._MainControl:UpdateEnergy()
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessGamer:UseWeaponSkill(roleId, skillId)
    local actor = self:GetRole(roleId)
    local endOfRound = true
    if actor then
        endOfRound = actor:UseWeaponSkill(skillId)
    end
    self:UpdateActionId(1)
    
    return endOfRound
end

--region   ------------------KillData start-------------------

--总体击杀数
function XBlackRockChessGamer:GetKillTotal()
    local total = 0
    for _, count in pairs(self._KillData) do
        total = total + count
    end
    
    return total
end

--某个类型棋子的击杀数
function XBlackRockChessGamer:GetKillCount(pieceType)
    return self._KillData[pieceType] and self._KillData[pieceType] or 0
end

function XBlackRockChessGamer:AddKillCount(pieceType)
    if not self._KillData[pieceType] then
        self._KillData[pieceType] = 1
        return
    end
    self._KillData[pieceType] = self._KillData[pieceType] + 1
end

--endregion------------------KillData finish------------------

--region   ------------------Sync-Restore start-------------------

function XBlackRockChessGamer:TempSync()
    for _, role in pairs(self._RoleDict) do
        role:TempSync()
    end
end

function XBlackRockChessGamer:Sync()
    for _, role in pairs(self._RoleDict) do
        role:Sync()
    end
end

function XBlackRockChessGamer:Restore()
    for _, role in pairs(self._RoleDict) do
        role:Restore()
    end
    local selectId = self._MainControl:GetMasterRoleId()
    if selectId ~= self._CurSelectId then
        self._CurSelectId = selectId
        self._Model:UpdateSelectActor(self._CurSelectId)
    end
    local actor = self:GetRole(selectId)
    actor:CallCOnClick()
end

function XBlackRockChessGamer:OnRelease()
    self._Imp = nil
    self._Energy = 0
    self._ReviveTimes = 0
    self._KillData = {}
    self._RoleDict = {}
end

function XBlackRockChessGamer:DoWin(onWin)
    local targetConditionId = self._MainControl:GetActiveConditionId()
    ---@type XChessActor
    local luna
    for _, actor in pairs(self._RoleDict) do
        actor:DoWin(targetConditionId)
        if not actor:IsSupport() then
            luna = actor
        end
    end

    --机位对准
    if luna then
        luna:LookAtWinCamera()
    end
    
    local col, row, point, duration = self._MainControl:GetViewOfWin()
    local syncDoWin = asynTask(function(cb)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:DoWin(cb)
    end)
    
    local syncMoveTo = asynTask(function(col, row, cb)
        if luna then
            luna:MoveTo(col, row, cb)
        end
    end)
    
    local syncCameMove = asynTask(function(vec3, duration, cb)
        if luna then
            luna:PlayAnimation("Victory")
        end
        CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:PlayWinCamera(vec3, duration, cb)
    end)
    RunAsyn(function()
        --切换相机
        syncDoWin()
        --移动角色
        syncMoveTo(col, row)
        --机位对准
        if luna then
            luna:LookAtWinCamera()
        end
        --相机移动
        syncCameMove(point, duration)

        if onWin then onWin() end
    end)
end

--endregion------------------Sync-Restore finish------------------


return XBlackRockChessGamer