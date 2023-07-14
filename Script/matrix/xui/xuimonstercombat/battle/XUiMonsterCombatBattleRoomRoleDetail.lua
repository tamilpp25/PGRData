local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiMonsterCombatBattleRoomRoleGrid
local XUiMonsterCombatBattleRoomRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiMonsterCombatBattleRoomRoleGrid")

function XUiMonsterCombatBattleRoomRoleGrid:SetLoveStatus(value)
    if self.PanelLove then
        self.PanelLove.gameObject:SetActiveEx(value)
    end
end

function XUiMonsterCombatBattleRoomRoleGrid:SetRecommendStatus(value)
    if self.PanelRecommend then
        self.PanelRecommend.gameObject:SetActiveEx(value)
    end
end

local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiMonsterCombatBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiMonsterCombatBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiMonsterCombatBattleRoomRoleDetail")

---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattleRoomRoleDetail:Ctor(stageId, monsterTeam, pos)
    self.MonsterTeam = monsterTeam
    self.StageId = stageId
end

function XUiMonsterCombatBattleRoomRoleDetail:GetAutoCloseInfo()
    local endTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        end
    end
end

function XUiMonsterCombatBattleRoomRoleDetail:GetEntities(characterType)
    local roles = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local chapterId = stageInfo.ChapterId
    local chapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(chapterId)
    local robotIds = chapterEntity:GetLimitRobotIds()
    -- 添加机器人
    for _, robotId in pairs(robotIds) do
        local type = self:GetCharacterType(robotId)
        local entity = XRobotManager.GetRobotById(robotId)
        if entity then
            table.insert(roles, entity)
        end
    end
    return roles
end

---@param monsterTeam XMonsterTeam
function XUiMonsterCombatBattleRoomRoleDetail:SortEntitiesWithTeam(monsterTeam, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local inTeamA = monsterTeam:GetEntityIdIsInTeam(entityA:GetId())
        local inTeamB = monsterTeam:GetEntityIdIsInTeam(entityB:GetId())
        if inTeamA ~= inTeamB then
            return inTeamA
        end
        local specialA = self:CheckSpecialSortEntities(entityA)
        local specialB = self:CheckSpecialSortEntities(entityB)
        if specialA ~= specialB then
            return specialA
        end
        return XDataCenter.RoomCharFilterTipsManager.GetSort(entityA:GetCharacterViewModel():GetId()
        , entityB:GetCharacterViewModel():GetId(), nil, false, sortTagType)
    end)
    return entities
end

function XUiMonsterCombatBattleRoomRoleDetail:CheckIsNeedPractice()
    -- 引导的时候不需要教学
    local isInGuide = XDataCenter.GuideManager.CheckIsInGuide()
    if isInGuide then
        return false
    end
    return true
end

function XUiMonsterCombatBattleRoomRoleDetail:GetGridProxy()
    return XUiMonsterCombatBattleRoomRoleGrid
end

function XUiMonsterCombatBattleRoomRoleDetail:AOPOnStartAfter(rootUi)
    self.AllRecommendCharacterIds = {}
    self.AllFetterCharacterIds = {}
    if self.MonsterTeam:GetMonsterIsEmpty() then
        self:GetRecommendCharacterIds()
    else
        self:GetFetterCharacterIds()
    end
end

function XUiMonsterCombatBattleRoomRoleDetail:GetRecommendCharacterIds()
    -- 获取推荐角色
    local tempCharacterIds = {}
    local stageEntity = XDataCenter.MonsterCombatManager.GetStageEntity(self.StageId)
    local recommendMonsters = stageEntity:GetRecommendMonsters()
    for _, monsterId in pairs(recommendMonsters) do
        local buffConfig = XMonsterCombatConfigs.GetBuffConfigByMonsterId(monsterId)
        local characterIds = buffConfig.CharacterIds
        tempCharacterIds = appendArray(tempCharacterIds, characterIds)
    end
    self.AllRecommendCharacterIds = table.unique(tempCharacterIds, true)
end

function XUiMonsterCombatBattleRoomRoleDetail:GetFetterCharacterIds()
    -- 获取羁绊角色
    local tempCharacterIds = {}
    local monsterIds = self.MonsterTeam:GetMonsterIds()
    for _, monsterId in pairs(monsterIds) do
        if XTool.IsNumberValid(monsterId) then
            local buffConfig = XMonsterCombatConfigs.GetBuffConfigByMonsterId(monsterId)
            -- 羁绊角色
            local characterIds = buffConfig.CharacterIds
            tempCharacterIds = appendArray(tempCharacterIds, characterIds)
        end
    end
    self.AllFetterCharacterIds = table.unique(tempCharacterIds, true)
end

---@param grid XUiMonsterCombatBattleRoomRoleGrid
function XUiMonsterCombatBattleRoomRoleDetail:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = rootUi.DynamicTable.DataSource[index]
        ---@type XCharacterViewModel
        local characterViewModel = entity:GetCharacterViewModel()
        local id = characterViewModel:GetId()
        -- 羁绊角色
        local isInFetter = table.contains(self.AllFetterCharacterIds, id)
        grid:SetLoveStatus(isInFetter)
        -- 推荐角色
        local isInRecommend = table.contains(self.AllRecommendCharacterIds, id)
        grid:SetRecommendStatus(isInRecommend)
    end
end

function XUiMonsterCombatBattleRoomRoleDetail:CheckSpecialSortEntities(entity)
    local charId = entity:GetCharacterViewModel():GetId()
    if table.contains(self.AllRecommendCharacterIds, charId) or table.contains(self.AllFetterCharacterIds, charId) then
        return true
    end
    return false
end

return XUiMonsterCombatBattleRoomRoleDetail