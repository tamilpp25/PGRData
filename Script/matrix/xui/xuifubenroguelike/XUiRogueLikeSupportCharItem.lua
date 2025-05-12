local XUiRogueLikeSupportCharItem = XClass(nil, "XUiRogueLikeSupportCharItem")

function XUiRogueLikeSupportCharItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end


function XUiRogueLikeSupportCharItem:UpdateCharacterInfos(robotId)
    self.RobotId = robotId
    self.GameObject:SetActiveEx(self.RobotId ~= nil)
    if self.RobotId ~= nil then
        local characterId = XRobotManager.GetCharacterId(robotId)
        if characterId == nil then
            self.GameObject:SetActiveEx(false)
            return
        end
        self.RImgRoleHead:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(characterId))
    end
end

return XUiRogueLikeSupportCharItem