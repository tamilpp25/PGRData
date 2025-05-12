local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiGuildBossBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiGuildBossBattleRoleRoom")

function XUiGuildBossBattleRoleRoom:Ctor(team, stageId)
    self.StageId = stageId
end

function XUiGuildBossBattleRoleRoom:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ArenaOnlineTimeOut"))
    end
end

function XUiGuildBossBattleRoleRoom:GetRoleDetailProxy()
    return {
        GetEntities = function(proxy)
            local result = {}
            local robotIds = XDataCenter.GuildBossManager.GetStageRobotTab(self.StageId)
            for i, robotId in ipairs(robotIds) do
                local aa = XRobotManager.GetRobotById(robotId)
                table.insert(result, aa)
                local characterId = XEntityHelper.GetCharacterIdByEntityId(robotId)
                if XMVCA.XCharacter:IsOwnCharacter(characterId) then
                    table.insert(result, XMVCA.XCharacter:GetCharacter(characterId))
                end
            end
            return result
        end,
        SortEntitiesWithTeam = function (proxy, team, entities, sortTagType) -- nzwjV3 新写一个排序 兼容固定机器人
            table.sort(entities, function(entityA, entityB)
                local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
                local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
                local teamWeightA = posA ~= -1 and (10 - posA) * 1000000 or 0
                local teamWeightB = posB ~= -1 and (10 - posB) * 1000000 or 0
        
                -- 战力 + 是否是拥有角色 + 固定机器人 + 试玩机器人
                local isARegularRobot = XDataCenter.GuildBossManager.CheckIsGuildFixedRobot(entityA:GetId())
                local isBRegularRobot = XDataCenter.GuildBossManager.CheckIsGuildFixedRobot(entityB:GetId())

                teamWeightA = teamWeightA + self:GetRoleAbility(entityA:GetId()) * 1000 + ((XEntityHelper.GetIsRobot(entityA:GetId()) and 0) or 500) + (isARegularRobot and 100 or 0)
                teamWeightB = teamWeightB + self:GetRoleAbility(entityB:GetId()) * 1000 + ((XEntityHelper.GetIsRobot(entityB:GetId()) and 0) or 500) + (isBRegularRobot and 100 or 0)
        
                return teamWeightA > teamWeightB 
            end)

            return entities
        end,
        AOPOnDynamicTableEventAfter = function(proxy, battleRoom, event, index, grid)
            if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
                local entity = battleRoom.DynamicTable.DataSource[index]
                local isGuildRegular = XDataCenter.GuildBossManager.CheckIsGuildFixedRobot(entity:GetId())
                grid:SetGuildFixedRobot(isGuildRegular) -- 添加活动试玩标签（拟真围剿的固定机器人）
            end
        end
        -- AOPOnStartAfter = function(proxy, rootUi)
        --     rootUi.BtnGroupCharacterType.gameObject:SetActiveEx(false)
        --     rootUi.BtnFilter.gameObject:SetActiveEx(false)
        -- end
    }
end

---@overload
function XUiGuildBossBattleRoleRoom:GetValidEntityIdList()
    local robotList = XDataCenter.GuildBossManager.GetStageRobotTab(self.StageId)
    --所有合法的角色ID
    local characterList = {}
    for i = 1, #robotList do
        table.insert(characterList, XRobotManager.GetCharacterId(robotList[i]))
        table.insert(characterList, robotList[i])
    end
    
    return characterList
end

function XUiGuildBossBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiGuildBossBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

return XUiGuildBossBattleRoleRoom