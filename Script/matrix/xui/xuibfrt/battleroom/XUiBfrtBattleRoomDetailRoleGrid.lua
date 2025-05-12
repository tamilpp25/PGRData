local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiBfrtBattleRoomDetailRoleGrid:XUiBattleRoomRoleGrid
local XUiBfrtBattleRoomDetailRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiBfrtBattleRoomDetailRoleGrid")

function XUiBfrtBattleRoomDetailRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

---@param team XTeam
function XUiBfrtBattleRoomDetailRoleGrid:SetData(entity, team, stageId, index, getEchelonIndexFunc)
    self.Super.SetData(self, entity)
    self.InEchelonIndex, self.InEchelonType = getEchelonIndexFunc(entity:GetId())
end

function XUiBfrtBattleRoomDetailRoleGrid:SetInTeamStatus()
    self.ImgInTeam.gameObject:SetActiveEx(false)
    self.PanelTeamSupport.gameObject:SetActiveEx(false)
    if self.InEchelonIndex then
        if self.InEchelonType == XDataCenter.BfrtManager.EchelonType.Fight then
            if self.TxtInTeamBlue then
                self.TxtInTeamBlue.text = CS.XTextManager.GetText("BfrtFightEchelonTitleSimple", self.InEchelonIndex)
            end
            self.ImgInTeam.gameObject:SetActiveEx(true)
        elseif self.InEchelonType == XDataCenter.BfrtManager.EchelonType.Logistics then
            if self.TxtEchelonIndex then
                self.TxtEchelonIndex.text = CS.XTextManager.GetText("BfrtLogisticEchelonTitleSimple", self.InEchelonIndex)
            end
            self.PanelTeamSupport.gameObject:SetActiveEx(true)
        end
    end
end

return XUiBfrtBattleRoomDetailRoleGrid