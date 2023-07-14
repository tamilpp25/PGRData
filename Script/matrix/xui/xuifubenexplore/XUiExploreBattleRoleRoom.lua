--######################## XUiExploreRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiExploreRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiExploreRoleGrid")

function XUiExploreRoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    self.PanelStaminaBar.gameObject:SetActiveEx(true)
    local maxStamina = XDataCenter.FubenExploreManager.GetMaxEndurance(XDataCenter.FubenExploreManager.GetCurChapterId())
    local curStamina = maxStamina - XDataCenter.FubenExploreManager.GetEndurance(XDataCenter.FubenExploreManager.GetCurChapterId(), entity:GetId())
    self.ImgStaminaExpFill.fillAmount = curStamina / maxStamina
end

--######################## XUiExploreBattleRoleRoom ########################
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiExploreBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiExploreBattleRoleRoom")

function XUiExploreBattleRoleRoom:Ctor()
    self.FubenExploreManager = XDataCenter.FubenExploreManager
end

function XUiExploreBattleRoleRoom:GetRoleDetailProxy()
    return {
        GetGridProxy = function()
            return XUiExploreRoleGrid
        end
    }
end

function XUiExploreBattleRoleRoom:AOPOnStartBefore(rootUi)
    rootUi.Team:Clear()
end

function XUiExploreBattleRoleRoom:GetTipDescs()
    if self.FubenExploreManager.IsNodeFinish(self.FubenExploreManager.GetCurChapterId()
        , self.FubenExploreManager.GetCurNodeId()) then
        return {}
    end
    -- todo text
    -- 消费AP 建议写入到Text.tab
    return { string.format( "Stage Endurance Cost: %s", self.FubenExploreManager.GetCurNodeEndurance()) }
end

-- team : XTeam
-- stageId : number
function XUiExploreBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    self.FubenExploreManager.SetCurTeam(team:SwithToOldTeamData())
    self.Super.EnterFight(self,team, stageId, challengeCount, isAssist)
end

function XUiExploreBattleRoleRoom:AOPRefreshRoleInfosAfter(rootUi)
    local entityIds = rootUi.Team:GetEntityIds()
    local viewModel
    local content
    local maxStamina = self.FubenExploreManager.GetMaxEndurance(self.FubenExploreManager.GetCurChapterId())
    local curStamina
    for index, id in ipairs(entityIds) do
        viewModel = self:GetCharacterViewModelByEntityId(id)
        rootUi["PanelStaminaBar" .. index].gameObject:SetActiveEx(viewModel ~= nil)
        if viewModel then
            curStamina = maxStamina - self.FubenExploreManager.GetEndurance(self.FubenExploreManager.GetCurChapterId(), viewModel:GetId())
            content = XUiHelper.GetText("RoomStamina", curStamina, maxStamina)
            rootUi["TxtMyStamina" .. index].text = content
            rootUi["ImgStaminaExpFill" .. index].fillAmount = curStamina / maxStamina
        end
    end
end

return XUiExploreBattleRoleRoom