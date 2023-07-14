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
        GetEntities = function(proxy, characterType)
            local result = {}
            local robotIds = XDataCenter.GuildBossManager.GetStageRobotTab(self.StageId)
            for i, robotId in ipairs(robotIds) do
                table.insert(result, XRobotManager.GetRobotById(robotId))
                local characterId = XEntityHelper.GetCharacterIdByEntityId(robotId)
                if XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
                    table.insert(result, XDataCenter.CharacterManager.GetCharacter(characterId))
                end
            end
            return result
        end,
        -- AOPOnStartAfter = function(proxy, rootUi)
        --     rootUi.BtnGroupCharacterType.gameObject:SetActiveEx(false)
        --     rootUi.BtnFilter.gameObject:SetActiveEx(false)
        -- end
    }
end

function XUiGuildBossBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiGuildBossBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

return XUiGuildBossBattleRoleRoom