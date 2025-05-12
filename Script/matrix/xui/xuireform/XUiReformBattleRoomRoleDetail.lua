--######################## XUiReformChildPanel ########################
local XUiReformChildPanel = XClass(nil, "XUiReformChildPanel")

function XUiReformChildPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = nil
end

function XUiReformChildPanel:SetData(rootUi)
    self.RootUi = rootUi
end

function XUiReformChildPanel:Refresh(currentEntityId)
    self.TxtScore.text = self.RootUi.MemberGroup:GetRoleScoreByCharacterId(
        self.RootUi:GetCharacterViewModelByEntityId(currentEntityId):GetId())
end

--######################## XUiReformBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiReformBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiReformBattleRoomRoleDetail")

-- team : XTeam
function XUiReformBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    self.ReformActivityManager = XDataCenter.ReformActivityManager
    self.BaseStage = self.ReformActivityManager.GetBaseStage(self.StageId)
    self.EvolableStage = self.BaseStage:GetCurrentEvolvableStage()
    self.MemberGroup = self.EvolableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
end

-- characterType : XEnumConst.CHARACTER.CharacterType
function XUiReformBattleRoomRoleDetail:GetEntities(characterType)
    if characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
        return {}
    end
    --[[
        同时满足参战的源和本地拥有同样的源角色的角色
    ]]
    local sources = self.MemberGroup:GetAllCanJoinTeamSources()
    local characterId, character, source
    for i = #sources, 1, -1 do
        source = sources[i]
        characterId = source:GetCharacterId()
        character = XMVCA.XCharacter:GetCharacter(characterId)
        if character then
            table.insert(sources, character)
        end
    end
    
    return sources
end

function XUiReformBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local source = self.MemberGroup:GetSourceById(entityId)
    local reuslt = nil
    if source then
        reuslt = source:GetCharacterViewModel()
    elseif entityId > 0 then
        reuslt = XMVCA.XCharacter:GetCharacter(entityId):GetCharacterViewModel()
    end
    return reuslt
end

function XUiReformBattleRoomRoleDetail:GetCharacterType(entityId)
    return XEnumConst.CHARACTER.CharacterType.Normal
end

function XUiReformBattleRoomRoleDetail:CheckTeamHasSameCharacterId(team, checkEntityId)
    local checkCharacterId = self:GetCharacterIdByEntityId(checkEntityId)
    for pos, entityId in pairs(team:GetEntityIds()) do
        if self:GetCharacterIdByEntityId(entityId) == checkCharacterId then
            return pos ~= self.Pos
        end
    end
    return false
end

function XUiReformBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 1000000000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 1000000000 or 0 
        -- local abilityA = entityA:GetCharacterViewModel():GetAbility() * 10
        -- local abilityB = entityB:GetCharacterViewModel():GetAbility() * 10
        local viewModelA = self:GetCharacterViewModelByEntityId(entityA:GetId())
        local viewModelB = self:GetCharacterViewModelByEntityId(entityB:GetId())
        local scoreA = self.MemberGroup:GetRoleScoreByCharacterId(viewModelA:GetId()) * 1000
        local scoreB = self.MemberGroup:GetRoleScoreByCharacterId(viewModelB:GetId()) * 1000
        local weightA = teamWeightA + scoreA + viewModelA:GetId() / 1000
        local weightB = teamWeightB + scoreB + viewModelB:GetId() / 1000
        if XRobotManager.CheckIsRobotId(entityA:GetId()) then weightA = weightA - 1 end
        if XRobotManager.CheckIsRobotId(entityB:GetId()) then weightB = weightB - 1 end
        return weightA > weightB
    end)
    return entities
end

function XUiReformBattleRoomRoleDetail:GetAutoCloseInfo()
    local endTime = self.ReformActivityManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            self.ReformActivityManager.HandleActivityEndTime()
        end
    end
end

function XUiReformBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
    rootUi.BtnGroupCharacterType.gameObject:SetActiveEx(false)
end

function XUiReformBattleRoomRoleDetail:GetRoleDynamicGrid(rootUi)
    return rootUi.GridCharacterReform
end

function XUiReformBattleRoomRoleDetail:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
    local entity = rootUi.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.TxtReformScore.text = self.MemberGroup:GetRoleScoreByCharacterId(
            self:GetCharacterViewModelByEntityId(entity:GetId()):GetId())
    end
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiReformBattleRoomRoleDetail:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoomDetail"),
        proxy = XUiReformChildPanel,
        proxyArgs = { self },
    }
end

--######################## 私有方法 ########################

function XUiReformBattleRoomRoleDetail:GetCharacterIdByEntityId(entityId)
    local result = entityId
    local source = self.MemberGroup:GetSourceById(entityId)
    if source then
        result = source:GetCharacterViewModel():GetId()
    end
    return result
end

return XUiReformBattleRoomRoleDetail