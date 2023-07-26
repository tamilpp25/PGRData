---@class XUiMazeRoleRoomGrid
local XUiMazeRoleRoomGrid = XClass(nil, "XUiMazeRoleRoomGrid")

function XUiMazeRoleRoomGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Id = false
    self.BtnClick.gameObject:SetActiveEx(false)
end

function XUiMazeRoleRoomGrid:Update(robotId)
    self._Id = robotId
    local characterId = XRobotManager.GetCharacterId(robotId)
    local name = XCharacterConfigs.GetCharacterName(characterId)
    local icon = XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
    local stageId = XMazeConfig.GetStageId(robotId)
    local isPassed = XDataCenter.MazeManager.IsStagePassed(stageId)
    self.RImgRole:SetRawImage(icon)
    self.TxtName.text = name
    self.PanelPass.gameObject:SetActiveEx(isPassed)
    self:UpdateSelected()
end

function XUiMazeRoleRoomGrid:UpdateSelected(robotIdSelected)
    robotIdSelected = robotIdSelected or XDataCenter.MazeManager.GetPartnerRobotId()
    local isSelected = self._Id == robotIdSelected
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

return XUiMazeRoleRoomGrid