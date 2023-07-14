--######################## XUiBossSingleRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiBossSingleRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiBossSingleRoleGrid")

function XUiBossSingleRoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    self.PanelStaminaBar.gameObject:SetActiveEx(true)
    local maxStamina = XDataCenter.FubenBossSingleManager.GetMaxStamina()
    local curStamina = maxStamina - XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(entity:GetId())
    self.ImgStaminaExpFill.fillAmount = curStamina / maxStamina
end

--######################## XUiBossSingleBattleRoleRoom ########################
local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiBossSingleBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBossSingleBattleRoleRoom")

function XUiBossSingleBattleRoleRoom:Ctor()
    self.FubenBossSingleManager = XDataCenter.FubenBossSingleManager
end

function XUiBossSingleBattleRoleRoom:GetRoleDetailProxy()
    return {
        AOPOnBtnJoinTeamClickedBefore = function(proxy, rootUi)
            local challengeCount = self.FubenBossSingleManager.GetCharacterChallengeCount(rootUi.CurrentEntityId)
            if challengeCount >= self.FubenBossSingleManager.GetMaxStamina() then
                XUiManager.TipCode(XCode.FubenBossSingleCharacterPointsNotEnough)
                return true
            end
        end,
        GetGridProxy = function()
            return XUiBossSingleRoleGrid
        end,
        GetFilterControllerConfig = function ()
            ---@type XCharacterAgency
            local ag = XMVCA:GetAgency(ModuleId.XCharacter)
            return ag:GetModelCharacterFilterController()["UiFubenBossSingle"]
        end
    }
end

-- team : XTeam
-- stageId : number
function XUiBossSingleBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    if not self:CheckRoleStanmina(team) then
        return
    end
    self.Super.EnterFight(self,team, stageId, challengeCount, isAssist)
end

function XUiBossSingleBattleRoleRoom:AOPRefreshRoleInfosAfter(rootUi)
    local entityIds = rootUi.Team:GetEntityIds()
    local viewModel
    local content
    local maxStamina = self.FubenBossSingleManager.GetMaxStamina()
    local curStamina
    for index, id in ipairs(entityIds) do
        viewModel = self:GetCharacterViewModelByEntityId(id)
        rootUi["PanelStaminaBar" .. index].gameObject:SetActiveEx(viewModel ~= nil)
        if viewModel then
            curStamina = maxStamina - self.FubenBossSingleManager.GetCharacterChallengeCount(viewModel:GetId())
            content = XUiHelper.GetText("RoomStamina", curStamina, maxStamina)
            rootUi["TxtMyStamina" .. index].text = content
            rootUi["ImgStaminaExpFill" .. index].fillAmount = curStamina / maxStamina
        end
    end
end

----------------------------------------

function XUiBossSingleBattleRoleRoom:CheckRoleStanmina(team)
    for i = 1, 3 do
        local posData = team:GetEntityIdByTeamPos(i)
        if posData and posData > 0 then
            local curStamina = self.FubenBossSingleManager.GetMaxStamina() - self.FubenBossSingleManager.GetCharacterChallengeCount(posData)
            if curStamina <= 0 then
                local charName = XCharacterConfigs.GetCharacterName(posData)
                local text = CSXTextManagerGetText("BossSingleNoStamina", charName)
                XUiManager.TipError(text)
                return false
            end
        end
    end
    return true
end

return XUiBossSingleBattleRoleRoom