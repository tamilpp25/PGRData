--===========================================================================
 ---@desc 角色列表元素
--===========================================================================
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiPivotCombatRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiPivotCombatRoleGrid")

function XUiPivotCombatRoleGrid:SetData(entity, team, stageId)
    self.Super.SetData(self, entity, team, stageId)
    local characterViewModel = entity:GetCharacterViewModel()
    --无论是机器人还是玩家的角色，这里都是CharacterId不是RobotId
    local id = characterViewModel:GetId()
    local stage = XDataCenter.PivotCombatManager.GetStage(stageId)
    if not stage or stage:CheckIsScoreStage() then
        self.ImgLock.gameObject:SetActiveEx(false)
    else
        local characterIdDic = XDataCenter.PivotCombatManager.GetLockCharacterDict()
        local isLock = characterIdDic[id] and true or false
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end



--===========================================================================
 ---@desc SP枢纽作战选人代理界面
--===========================================================================
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiPivotCombatBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiPivotCombatBattleRoomRoleDetail")

local EnhanceSkill = 5 --属性界面->独域技能

function XUiPivotCombatBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiPivotCombatBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    self.Entities = {}
end

function XUiPivotCombatBattleRoomRoleDetail:GetGridProxy()
    return XUiPivotCombatRoleGrid
end

function XUiPivotCombatBattleRoomRoleDetail:GetDefaultCharacterType()
    local roles = self:GetEntities(XCharacterConfigs.CharacterType.Isomer)
    return #roles > 0 and XCharacterConfigs.CharacterType.Isomer or XCharacterConfigs.CharacterType.Normal
end

--获取角色
function XUiPivotCombatBattleRoomRoleDetail:GetEntities(characterType)
    local result = {}
    if XTool.IsTableEmpty(self.Entities[characterType]) then
        self.Entities[characterType] = XDataCenter.PivotCombatManager.GetFightEntities(characterType)
    end
    for _, entity in ipairs(self.Entities[characterType]) do
        table.insert(result, entity)
    end
    return result
end

--角色排序
function XUiPivotCombatBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 1000000000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 1000000000 or 0
        local abilityA = entityA:GetCharacterViewModel():GetAbility() * 10
        local abilityB = entityB:GetCharacterViewModel():GetAbility() * 10
        local weightA = teamWeightA + abilityA + entityA:GetId() / 1000
        local weightB = teamWeightB + abilityB + entityB:GetId() / 1000
        return weightA > weightB
    end)
    return entities
end

function XUiPivotCombatBattleRoomRoleDetail:CheckCustomLimit(entityId)
    if not XTool.IsNumberValid(entityId) then
        return false
    end
    local stage = XDataCenter.PivotCombatManager.GetStage(self.StageId)
    local isLock = false
    --积分关不锁角色
    if not stage or stage:CheckIsScoreStage() then
        return isLock
    end
    local entity = self.Super.GetCharacterViewModelByEntityId(self, entityId)
    local id = entity and entity:GetId() or 0
    local characterIdDic = XDataCenter.PivotCombatManager.GetLockCharacterDict()
    isLock = characterIdDic[id] and true or false
    if isLock then
        XUiManager.TipError(XUiHelper.GetText("PivotCombatRoleLockTips"))
    end
    return isLock
end

function XUiPivotCombatBattleRoomRoleDetail:AOPOnBtnJoinTeamClickedBefore(rootUi)
    local entity = self.Super.GetCharacterViewModelByEntityId(self, rootUi.CurrentEntityId)
    local id = entity and entity:GetId() or 0
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(id)
    if not isOwn then return end
   
    local condition = XPivotCombatConfigs.GetSpecialSkillCheck(id)
    

    if not condition then return end

    local unlock, desc = XConditionManager.CheckCondition(condition, id)
   
   
    local negativeCb = function()
        --打开新的界面，会打断原来的界面关闭，这里重新关闭
        rootUi:Close(true) 
    end
   
    local positiveCb = function()
        XLuaUiManager.Open("UiCharacter", id, nil, nil, nil, true, nil, nil, EnhanceSkill)
    end

    if not unlock then
         XDataCenter.PivotCombatManager.ShowDialogHintTip(id, negativeCb, positiveCb)
    end
    return false
end


--活动结束
function XUiPivotCombatBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XDataCenter.PivotCombatManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.PivotCombatManager.OnActivityEnd()
        end
    end
end


return XUiPivotCombatBattleRoomRoleDetail