local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiScoreTowerStageRoleGrid : XUiBattleRoomRoleGrid
local XUiScoreTowerStageRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiScoreTowerStageRoleGrid")

---@param team XScoreTowerStageTeam
function XUiScoreTowerStageRoleGrid:SetData(entity, team, stageId, index, getStageShowCharacterInfo)
    self.Super.SetData(self, entity)
    self.Team = team
    self.StageId = stageId
    self.Index = index
    self.GetStageShowCharacterInfo = getStageShowCharacterInfo
    self:RefreshTag(entity:GetCharacterViewModel())
end

function XUiScoreTowerStageRoleGrid:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end

    self.TxtFight.text = XMVCA.XScoreTower:GetCharacterPower(self.Character:GetId())
    self.PanelFight.gameObject:SetActiveEx(true)
end

-- 刷新标签
function XUiScoreTowerStageRoleGrid:RefreshTag(characterViewModel)
    self:ShowSuggestTag(characterViewModel)
    self:ShowIsUsedTag(characterViewModel)
end

-- 显示推荐标签
---@param characterViewModel XCharacterViewModel
function XUiScoreTowerStageRoleGrid:ShowSuggestTag(characterViewModel)
    local cfgId = self.Team:GetStageCfgId()
    local entityId = characterViewModel:GetSourceEntityId()
    if not XTool.IsNumberValid(cfgId) or not XTool.IsNumberValid(entityId) then
        return
    end
    -- boss 关不显示推荐标签
    local stageType = XMVCA.XScoreTower:GetStageType(cfgId)
    if stageType == XEnumConst.ScoreTower.StageType.Boss then
        return
    end
    local isSuggestTag = XMVCA.XScoreTower:IsStageSuggestTag(cfgId, entityId)
    if self.PanelRecommend then
        self.PanelRecommend.gameObject:SetActiveEx(isSuggestTag)
    end
end

-- 显示已上阵标签
---@param characterViewModel XCharacterViewModel
function XUiScoreTowerStageRoleGrid:ShowIsUsedTag(characterViewModel)
    local entityId = characterViewModel:GetSourceEntityId()
    if not XTool.IsNumberValid(entityId) then
        return
    end
    local info = self.GetStageShowCharacterInfo(entityId)
    if not info then
        return
    end
    if self.PanelSupportLock then
        self.PanelSupportLock.gameObject:SetActiveEx(info.IsUsed)
    end
end

return XUiScoreTowerStageRoleGrid
