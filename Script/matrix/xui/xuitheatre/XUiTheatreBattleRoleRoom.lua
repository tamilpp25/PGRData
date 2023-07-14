local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiTheatreBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTheatreBattleRoleRoom")

function XUiTheatreBattleRoleRoom:Ctor(team, stageId)
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Chapter = self.AdventureManager:GetCurrentChapter()
    self.StageId = stageId
end

function XUiTheatreBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiTheatreBattleRoleRoom:GetCharacterViewModelByEntityId(id)
    local role = self.AdventureManager:GetRole(id)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

-- 根据实体Id获取伙伴实体
-- return : XPartner
function XUiTheatreBattleRoleRoom:GetPartnerByEntityId(id)
    local role = self.AdventureManager:GetRole(id)
    if role == nil then return nil end
    local result = nil
    if role:GetIsLocalRole() then
        return XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(role:GetId())
    else
        return role:GetRawData():GetPartner()
    end
end

function XUiTheatreBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiTheatre/XUiTheatreBattleRoomRoleDetail")
end

function XUiTheatreBattleRoleRoom:EnterFight()
    self.AdventureManager:RequestSetSingleTeam(function()
        self.AdventureManager:EnterFight(self.StageId, nil, function(res)
            XLog.Warning(res)
            if res.Code ~= XCode.Success then
                return
            end
            -- hack : 假如当前节点是事件战斗并没有下一个触发节点，直接移除事件选择界面防止战斗回来闪一下
            local currentNode = self.AdventureManager:GetCurrentChapter():GetCurrentNode()
            if not currentNode then return end
            if currentNode:GetNodeType() == XTheatreConfigs.NodeType.Event
               and currentNode:GetEventType() == XTheatreConfigs.EventNodeType.Battle
               and (currentNode:GetNextStepId() == nil or currentNode:GetNextStepId() == 0) then
               XLuaUiManager.Remove("UiTheatreOutpost")
            end
        end)
    end)
end

return XUiTheatreBattleRoleRoom