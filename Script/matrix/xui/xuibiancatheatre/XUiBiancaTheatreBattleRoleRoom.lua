local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiBiancaTheatreBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiBiancaTheatreBattleRoleRoom")

function XUiBiancaTheatreBattleRoleRoom:Ctor(team, stageId)
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Chapter = self.AdventureManager:GetCurrentChapter()
    self.StageId = stageId
    self:CheckTeam(team)
end

--检查队伍里试玩角色是否在已招募列表里，存在时更新当前星级的试玩角色Id
function XUiBiancaTheatreBattleRoleRoom:CheckTeam(team)
    local characterId
    local adventureRole, adventureRobotRole
    for teamPos, entityId in ipairs(team:GetEntityIds()) do
        if XEntityHelper.GetIsRobot(entityId) then
            characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
            adventureRole = self.AdventureManager:GetRoleByCharacterId(characterId)
            adventureRobotRole = adventureRole and adventureRole:GetRobotRole()
            if adventureRobotRole then
                team:UpdateEntityTeamPos(adventureRobotRole:GetId(), teamPos, true)
            end
        end
    end
end

function XUiBiancaTheatreBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    rootUi.BtnMainUi.CallBack = function() XDataCenter.BiancaTheatreManager.RunMain() end
    -- 进入辅助机关闭音效滤镜
    for i = 1, 3, 1 do
        if rootUi["UiObjPartner"..i] then
            XUiHelper.RegisterClickEvent(rootUi, rootUi["UiObjPartner"..i]:GetObject("BtnClick"), function ()
                XDataCenter.BiancaTheatreManager.ResetAudioFilter()
            end)
        end
    end
end

function XUiBiancaTheatreBattleRoleRoom:AOPOnEnableAfter(rootUi)
    -- 音效滤镜界限恢复
    XDataCenter.BiancaTheatreManager.StartAudioFilter()
end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiBiancaTheatreBattleRoleRoom:GetCharacterViewModelByEntityId(id)
    local role = self.AdventureManager:GetRole(id)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

-- 根据实体Id获取伙伴实体
-- return : XPartner
function XUiBiancaTheatreBattleRoleRoom:GetPartnerByEntityId(id)
    local role = self.AdventureManager:GetRole(id)
    if role == nil then return nil end
    local result = nil
    if role:GetIsLocalRole() then
        return XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(role:GetId())
    else
        return role:GetRawData():GetPartner()
    end
end

function XUiBiancaTheatreBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiBiancaTheatre/XUiBiancaTheatreBattleRoomRoleDetail")
end

function XUiBiancaTheatreBattleRoleRoom:EnterFight()
    self.AdventureManager:RequestSetSingleTeam(function()
        self.AdventureManager:EnterFight(self.StageId, nil, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            -- hack : 假如当前节点是事件战斗并没有下一个触发节点，直接移除事件选择界面防止战斗回来闪一下
            local currentNode = self.AdventureManager:GetCurrentChapter():GetCurrentNode()
            if not currentNode then return end
            if currentNode:GetNodeType() == XBiancaTheatreConfigs.NodeType.Event
               and currentNode:GetEventType() == XBiancaTheatreConfigs.EventNodeType.Battle
               and (currentNode:GetNextStepId() == nil or currentNode:GetNextStepId() == 0) then
               XLuaUiManager.Remove("UiBiancaTheatreOutpost")
            end
        end)
    end)
end

function XUiBiancaTheatreBattleRoleRoom:GetRoleAbility(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role then
        return role:GetAbility()
    end
    return 0
end

return XUiBiancaTheatreBattleRoleRoom