local LEVEL_PREFIX_FORMAT = "+%s"
local stringFormat = string.format
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPanelSkillLevelDetailOther = XClass(nil, "XUiPanelSkillLevelDetailOther")

function XUiPanelSkillLevelDetailOther:Ctor(ui)
    self.DetailGrids = {}
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridDetails.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = function() self.GameObject:SetActiveEx(false) end
end

function XUiPanelSkillLevelDetailOther:Refresh(characterId, skillId)
    local detailGrids = self.DetailGrids

    local grid = detailGrids.ResonanceLevel
    local resonanceLevel = XDataCenter.CharacterManager.GetResonanceSkillLevel(characterId, skillId)
    if resonanceLevel and resonanceLevel > 0 then
        if not grid then
            grid = self:NewGrid()
            detailGrids.ResonanceLevel = grid
        end

        grid.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailResonanace")
        grid.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, resonanceLevel)
        grid.GameObject:SetActiveEx(true)
    elseif grid then
        grid.GameObject:SetActiveEx(false)
    end

    local grid2 = detailGrids.AssignLevel
    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevel(characterId, skillId)
    if resonanceLevel and assignLevel > 0 then
        if not grid2 then
            grid2 = self:NewGrid()
            detailGrids.AssignLevel = grid2
        end

        grid2.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailAssign")
        grid2.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, assignLevel)
        grid2.GameObject:SetActiveEx(true)
    elseif grid2 then
        grid2.GameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillLevelDetailOther:NewGrid()
    local grid = {}
    local go = CSUnityEngineObjectInstantiate(self.GridDetails, self.PanelDetails)
    grid.GameObject = go.gameObject
    grid.Transform = go.transform
    XTool.InitUiObject(grid)
    grid.GameObject:SetActiveEx(true)
    return grid
end

return XUiPanelSkillLevelDetailOther