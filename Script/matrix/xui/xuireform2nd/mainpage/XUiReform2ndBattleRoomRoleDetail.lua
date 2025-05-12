--######################## XUiReform2ndChildPanel ########################
local XUiReform2ndChildPanel = XClass(nil, "XUiReform2ndChildPanel")

function XUiReform2ndChildPanel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = nil
end

function XUiReform2ndChildPanel:SetData(rootUi)
    self.RootUi = rootUi
end

function XUiReform2ndChildPanel:Refresh(currentEntityId)
    local hasRecommend, txt = XMVCA.XReform:GetRecommendDescByStageIdAndEntityId(self.RootUi:GetStageId(), currentEntityId)

    self.GameObject:SetActiveEx(hasRecommend)
    if hasRecommend then
        self.TxtScore.text = txt
    end
end

--######################## XUiReform2ndBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiReform2ndBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiReform2ndBattleRoomRoleDetail")
local XRobot = require("XEntity/XRobot/XRobot")

-- team : XTeam
function XUiReform2ndBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiReform2ndBattleRoomRoleDetail:GetStageId()
    return self.StageId
end

function XUiReform2ndBattleRoomRoleDetail:GetEntities(characterType)
    return XMVCA.XReform:GetOwnCharacterListByStageId(self:GetStageId(), characterType)
end

function XUiReform2ndBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    return XMVCA.XReform:SortEntitiesInStage(entities, self:GetStageId())
end

function XUiReform2ndBattleRoomRoleDetail:GetAutoCloseInfo()
    local endTime = XMVCA.XReform:GetActivityEndTime()

    return true, endTime, function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end
end

function XUiReform2ndBattleRoomRoleDetail:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
    ---@type XCharacter
    local entity = rootUi.DynamicTable.DataSource[index]
    local characterList = XMVCA.XReform:GetStageCharacterListByStageId(self.StageId)
    local isInList = false

    for i = 1, #characterList do
        if entity and entity:GetId() == characterList[i] then
            isInList = true
        end
    end

    if grid.PanelRecommend then
        grid.PanelRecommend.gameObject:SetActiveEx(isInList)
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
--function XUiReform2ndBattleRoomRoleDetail:GetChildPanelData()
--    return {
--        assetPath = XUiConfigs.GetComponentUrl("PanelReformBattleRoomDetail"),
--        proxy = XUiReform2ndChildPanel,
--        proxyArgs = { self },
--    }
--end

return XUiReform2ndBattleRoomRoleDetail