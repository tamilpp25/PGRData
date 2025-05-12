local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiScoreTowerTowerRoleGrid : XUiBattleRoomRoleGrid
local XUiScoreTowerTowerRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiScoreTowerTowerRoleGrid")

---@param team XScoreTowerTowerTeam
function XUiScoreTowerTowerRoleGrid:SetData(entity, team, stageId, index)
    self.Super.SetData(self, entity)
    self.Team = team
    self.StageId = stageId
    self.Index = index
    self:ShowSuggestTag(entity:GetCharacterViewModel())
end

function XUiScoreTowerTowerRoleGrid:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end

    self.TxtFight.text = XMVCA.XScoreTower:GetCharacterPower(self.Character:GetId())
    self.PanelFight.gameObject:SetActiveEx(true)
end

-- 显示推荐标签
---@param characterViewModel XCharacterViewModel
function XUiScoreTowerTowerRoleGrid:ShowSuggestTag(characterViewModel)
    local towerId = self.Team:GetTowerId()
    local entityId = characterViewModel:GetSourceEntityId()
    if not XTool.IsNumberValid(towerId) or not XTool.IsNumberValid(entityId) then
        return
    end
    local isSuggestTag = XMVCA.XScoreTower:IsTowerSuggestTag(towerId, entityId)
    if self.PanelRecommend then
        self.PanelRecommend.gameObject:SetActiveEx(isSuggestTag)
    end
end

return XUiScoreTowerTowerRoleGrid
