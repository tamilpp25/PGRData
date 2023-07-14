local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiAreaWarBattleRoomRoleDetailChildPanel = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetailChildPanel")

local pairs = pairs
local ipairs = ipairs
local tableInsert = table.insert
local tableSort = table.sort

local XUiAreaWarBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiAreaWarBattleRoomRoleDetail")

function XUiAreaWarBattleRoomRoleDetail:Ctor(blockId)
    self.BlockId = blockId
end

function XUiAreaWarBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    self.Entities = {}
    rootUi.PanelAsset.gameObject:SetActiveEx(false)
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
end

function XUiAreaWarBattleRoomRoleDetail:GetEntities(characterType)
    local result = {}
    if XTool.IsTableEmpty(self.Entities[characterType]) then
        self.Entities[characterType] = XDataCenter.AreaWarManager.GetCanFightEntities(characterType)
    end
    for _, entity in ipairs(self.Entities[characterType]) do
        if entity:GetCharacterViewModel():GetCharacterType() == characterType then
            tableInsert(result, entity)
        end
    end
    return result
end

function XUiAreaWarBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    for _, typeDic in pairs(self.Entities) do
        for _, entity in pairs(typeDic) do
            if entity:GetId() == entityId then
                return entity:GetCharacterViewModel()
            end
        end
    end
end

function XUiAreaWarBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    local blockId = self.BlockId
    tableSort(
        entities,
        function(entityA, entityB)
            local aId = entityA:GetId()
            local bId = entityB:GetId()

            --是否满足区块派遣条件
            local aFit =
                XDataCenter.AreaWarManager.CheckDispatchConditionsFitCharacter(
                blockId,
                XEntityHelper.GetCharacterIdByEntityId(aId)
            )
            local bFit =
                XDataCenter.AreaWarManager.CheckDispatchConditionsFitCharacter(
                blockId,
                XEntityHelper.GetCharacterIdByEntityId(bId)
            )
            if aFit ~= bFit then
                return aFit
            end

            return aId < bId
        end
    )
    return entities
end

function XUiAreaWarBattleRoomRoleDetail:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("XUiAreaWarBattleRoomRoleDetail"),
            proxy = XUiAreaWarBattleRoomRoleDetailChildPanel
        }
    end
    return self.ChildPanelData
end

function XUiAreaWarBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XDataCenter.AreaWarManager.GetEndTime(), function(isClose)
        if isClose then
            XDataCenter.AreaWarManager.OnActivityEnd()
        end
    end
end

return XUiAreaWarBattleRoomRoleDetail
