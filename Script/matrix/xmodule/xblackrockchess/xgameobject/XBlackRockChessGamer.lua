
---@class XBlackRockChessGamer : XEntityControl 玩家
---@field _MainControl XBlackRockChessControl
---@field _Imp XBlackRockChess.XChessGamer
---@field _RoleDict table<number, XChessActor>
---@field _KillData table<number,table<number,number>> 玩家击杀数据 <节点,<类型,数量>>
local XBlackRockChessGamer = XClass(XEntityControl, "XBlackRockChessGamer")
local XChessActor = require("XModule/XBlackRockChess/XGameObject/XChessActor")

local ActionType = XEnumConst.BLACK_ROCK_CHESS.ACTION_TYPE

function XBlackRockChessGamer:OnInit()
    self._RoleDict = {}
    self._Energy = 0 --玩家能量条
    self._ReviveTimes = 0 --玩家复活次数
    self._KillData = {}
    self._RoundData = {}
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
        ---@type XBlackRockChess.XChessRole
        local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddGamer(self._MainControl:GetRoleModelUrl(roleId), x, y)
        -- 设置普通状态下的技能
        local normalWeaponId = self._MainControl:GetRoleWeaponId(roleId, 1)
        if XTool.IsNumberValid(normalWeaponId) then
            local weaponType = self._MainControl:GetWeaponType(normalWeaponId)
            local weaponSkills = self._MainControl:GetWeaponSkillIds(normalWeaponId)
            local moveRange = self._MainControl:GetWeaponMoveRange(normalWeaponId)
            imp:SetGamerWeapon(normalWeaponId, weaponType, #weaponSkills, moveRange)
        else
            XLog.Error("普通状态技能为空.")
        end
        -- 设置红怒状态下的技能
        local redModelWeaponId = self._MainControl:GetRoleWeaponId(roleId, 2)
        if XTool.IsNumberValid(redModelWeaponId) then
            local weaponType = self._MainControl:GetWeaponType(redModelWeaponId)
            local weaponSkills = self._MainControl:GetWeaponSkillIds(redModelWeaponId)
            local moveRange = self._MainControl:GetWeaponMoveRange(redModelWeaponId)
            imp:SetGamerRedModelWeapon(redModelWeaponId, weaponType, #weaponSkills, moveRange)
        end
        if not imp then
            XLog.Error("加载角色" .. roleId .. "失败")
        else
            role:SetImp(imp)
        end
    end
    --应用Buff
    self:ApplyBuff()
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
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
                buff:DoTakeEffect()
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
        buff:DoApply(buffId, imp, table.unpack(args))
    end

    return buff
end

function XBlackRockChessGamer:OnBuffTakeEffect(args)
    self._MainControl:OnBuffTakeEffect(args)
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

    --恢复棋盘点击
    CS.XBlackRockChess.XBlackRockChessManager.SetLimitClick(false)
    self._BeforeEnemy = {} --在敌人行动之前的动作列表
    self._AfterEnemy = {}  --在敌人行动之后的动作列表
    self._Finally = {}  --最后执行的动作列表
    self._BlendAction = {}
    self._ActionId = 1
    self._Imp:OnRoundBegin()
    self._MainControl:BroadcastRound(true, false)
    self._MainControl:SetGameRound(true)
    --回合开始默认选中
    self._CurSelectId = self._MainControl:GetMasterRoleId()
    self._Model:UpdateSelectActor(self._CurSelectId)
    local actor = self:GetRole(self._CurSelectId)
    actor:UpdateBlendPiece(true)
    actor:CallCOnClick()
    self._MainControl:DebugActionChange("OnRoundBegin", self._ActionId)
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

---角色回合结束时执行附身buff
function XBlackRockChessGamer:ApplyBlendBuffAfter()
    for _, role in pairs(self._RoleDict) do
        local blendPieceType = role:GetBlendPieceType()
        if blendPieceType and blendPieceType ~= XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KNIGHT then
            role:ApplyBlendBuff()
        end
    end
end

---角色站在友军上时立即生效
function XBlackRockChessGamer:ApplyBlendBuffBefore()
    for _, role in pairs(self._RoleDict) do
        local blendPieceType = role:GetBlendPieceType()
        if blendPieceType == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.KNIGHT then
            role:ApplyBlendBuff()
        end
    end
end

function XBlackRockChessGamer:RemoveDefenseState()
    for _, role in pairs(self._RoleDict) do
        role:RemoveDefenseState()
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
    self._MainControl:DebugActionChange("DoForceEndOfTurn", self._ActionId)
end

function XBlackRockChessGamer:GetEnergy()
    return self._Energy
end

--- 是否进入红怒状态
function XBlackRockChessGamer:IsEnterRedModel()
    return self._Energy >= self._MainControl:GetEnterRedModelEnergy()
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

---角色是否在当前回合复活
function XBlackRockChessGamer:IsRevive()
    for _, role in pairs(self._RoleDict) do
        if role:IsRevive() then
            return true
        end
    end
    return false
end

---角色是否在当前回合触发保护技能
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

function XBlackRockChessGamer:UpdateData(energy, reviveTimes, stageStatData)
    self._Energy = energy
    self._ReviveTimes = reviveTimes
    self._KillData = {}
    self._RoundData = {}
    -- 服务端nodeIdx从0开始
    for nodeIdx, datas in pairs(stageStatData.KillInfos) do
        self._KillData[nodeIdx] = {}
        for _, data in pairs(datas) do
            self._KillData[nodeIdx][data.PieceType] = data.Count
        end
    end
    for nodeIdx, rounds in pairs(stageStatData.RoundInfos) do
        self._RoundData[nodeIdx] = rounds
    end
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_KILL)
end

function XBlackRockChessGamer:AddEnergy(value)
    local maxEnergy = self._MainControl:GetMaxEnergy()
    self._Energy = math.min(maxEnergy, self._Energy + value)
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
    local curSelectId = self._CurSelectId or self._MainControl:GetMasterRoleId()
    return self:GetRole(curSelectId)
end

function XBlackRockChessGamer:UpdateSelect(roleId)
    if self._CurSelectId ~= roleId and XTool.IsNumberValid(self._CurSelectId) then
        self:GetRole(self._CurSelectId):DoCancelSelect()
    end
    self._CurSelectId = roleId
    self._Model:UpdateSelectActor(roleId)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_REFRESH_SELECT_ROLE, roleId)
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
    
    self._MainControl:ManualTriggeringGuide()
end

function XBlackRockChessGamer:GetActionList()
    if not self._Imp then
        return {}
    end
    -- 服务端校验有顺序要求
    -- 单个 handle round 里 被动 > 移动 > 攻击(强制结束回合)
    -- 整个回合里 复活在最后

    -- 线上未复现bug：释放大招时 Move事件发送了2次
    local isMoveHasAdd = false

    -- 在敌人操作之前的动作，在敌人操作之后的动作
    local beforeEnemy, afterEnemy, finally = {}, {}, {}
    if not XTool.IsTableEmpty(self._BeforeEnemy) then
        local sort = { ActionType.PASSIVE_SKILL, ActionType.MOVE, ActionType.ATTACK, ActionType.SKIP_ROUND }
        for _, actionType in pairs(sort) do
            for actionId, dict in pairs(self._BeforeEnemy) do
                if dict[actionType] then
                    if actionType == ActionType.MOVE then
                        if not isMoveHasAdd then
                            isMoveHasAdd = true
                            table.insert(beforeEnemy, dict[actionType])
                        end
                    else
                        table.insert(beforeEnemy, dict[actionType])
                    end
                    self._MainControl:DebugMutilMove(actionId, actionType)
                end
            end
        end
    end
    -- 反击需要放在敌人移动后
    if not XTool.IsTableEmpty(self._AfterEnemy) then
        for _, dicts in pairs(self._AfterEnemy) do
            for _, dict in pairs(dicts) do
                table.insert(afterEnemy, dict)
            end
        end
    end
    -- 角色复活放在最后面
    if not XTool.IsTableEmpty(self._Finally) then
        local sort = { ActionType.CHARACTER_REVIVE, ActionType.CHARACTER_SKILL }
        for _, actionType in pairs(sort) do
            for actionId, dict in pairs(self._Finally) do
                if dict[actionType] then
                    table.insert(finally, dict[actionType])
                end
            end
        end
    end
    -- 处理附身特殊事件
    if not XTool.IsTableEmpty(self._BlendAction) then
        local moveAction = self._BlendAction[ActionType.MOVE]
        if moveAction then
            for i, action in ipairs(beforeEnemy) do
                if action.ActionType == ActionType.MOVE then
                    if moveAction.Params[1] ~= action.Params[1] or moveAction.Params[2] ~= action.Params[2] then
                        table.insert(beforeEnemy, i, moveAction)
                        break
                    end
                end
            end
        end
    end
    
    return beforeEnemy, afterEnemy, finally
end

function XBlackRockChessGamer:AddAction(action, isRemove)
    if action.ActionType == ActionType.CHARACTER_REVIVE or action.ActionType == ActionType.CHARACTER_SKILL then
        if not self._Finally then
            return
        end
        local dict = self._Finally[self._ActionId] or {}
        if isRemove then
            dict[action.ActionType] = nil
        else
            dict[action.ActionType] = action
        end
        self._Finally[self._ActionId] = dict
    elseif action.ActionType == ActionType.CHARACTER_ATTACK_BACK then
        if not self._AfterEnemy then
            return
        end
        local dict = self._AfterEnemy[self._ActionId] or {}
        if isRemove then
            dict[action.ActionType] = nil
        else
            dict[action.ActionType] = action
        end
        self._AfterEnemy[self._ActionId] = dict
    else
        if not self._BeforeEnemy then
            return
        end
        local dict = self._BeforeEnemy[self._ActionId] or {}
        if isRemove then
            dict[action.ActionType] = nil
        else
            dict[action.ActionType] = action
        end
        self._BeforeEnemy[self._ActionId] = dict
    end
end

function XBlackRockChessGamer:AddBlendSpecialAction(actionType, action)
    self._BlendAction[actionType] = action
end

function XBlackRockChessGamer:UpdateActionId(value)
    if value < 0 then
        self._Finally[self._ActionId] = nil
        self._BeforeEnemy[self._ActionId] = nil
        self._AfterEnemy[self._ActionId] = nil
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
end

function XBlackRockChessGamer:UseWeaponSkill(roleId, skillId)
    local actor = self:GetRole(roleId)
    local endOfRound = true
    if actor then
        endOfRound = actor:UseWeaponSkill(skillId)
    end
    self:UpdateActionId(1)
    self._MainControl:DebugActionChange("UseWeaponSkill", self._ActionId)
    
    return endOfRound
end

--region   ------------------KillData start-------------------

--总体击杀数
function XBlackRockChessGamer:GetKillTotal()
    local total = 0
    for _, data in pairs(self._KillData) do
        for _, count in pairs(data) do
            total = total + count
        end
    end
    
    return total
end

function XBlackRockChessGamer:GetRoundTotal()
    local total = self._MainControl:GetChessRound()
    for _, count in pairs(self._RoundData) do
        total = total + count
    end
    return total
end

function XBlackRockChessGamer:GetCurNodeKill()
    local idx = self._MainControl:GetChessNodeIdx()
    return self._KillData[idx - 1]
end

function XBlackRockChessGamer:GetCurNodeKillCount()
    local killData = self:GetCurNodeKill()
    local total = 0
    if killData then
        for _, count in pairs(killData) do
            total = total + count
        end
    end
    return total
end

--某个类型棋子的击杀数
function XBlackRockChessGamer:GetKillCount(pieceType)
    local killData = self:GetCurNodeKill()
    if killData and killData[pieceType] then
        return killData[pieceType]
    end
    return 0
end

function XBlackRockChessGamer:AddKillCount(pieceType)
    local killData = self:GetCurNodeKill() or {}
    if killData[pieceType] then
        killData[pieceType] = killData[pieceType] + 1
    else
        killData[pieceType] = 1
    end
    local idx = self._MainControl:GetChessNodeIdx()
    self._KillData[idx - 1] = killData -- 服务端索引从0开始
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_KILL)
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
    self._RoundData = {}
    self._RoleDict = {}
end

function XBlackRockChessGamer:DoWin(onWin)
    ---@type XChessActor
    local luna
    for _, actor in pairs(self._RoleDict) do
        actor:DoWin()
        if not actor:IsSupport() then
            luna = actor
        end
    end

    --机位对准
    if luna then
        luna:LookAtWinCamera()
    end

    luna:LoadEffect(XEnumConst.BLACK_ROCK_CHESS.EFFECT_ID.NODE_SUCCESS)

    local col, row, point, duration = self._MainControl:GetViewOfWin()
    local syncDoWin = asynTask(function(cb)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:DoWin(cb)
    end)
    
    local syncMoveTo = asynTask(function(col, row, cb)
        if luna then
            luna:PlayWinMove(col, row, function()
                if luna then
                    luna:LookAtWinCamera()
                end
                if cb then
                    cb()
                end
            end)
        end
    end)
    
    RunAsyn(function()
        --切换相机
        syncDoWin()
        --机位对准
        if luna then
            luna:LookAtWinCamera()
        end
        --移动角色
        syncMoveTo(col, row)
        --播放角色落地动作
        if luna then
            luna:PlayAnimation("WeilaFall")
        end
        --相机移动
        CS.XBlackRockChess.XBlackRockChessManager.Instance.ChessBoard:PlayWinCamera(point, duration, function()
            if onWin then
                onWin()
            end
        end)
    end)
end

--endregion------------------Sync-Restore finish------------------


return XBlackRockChessGamer