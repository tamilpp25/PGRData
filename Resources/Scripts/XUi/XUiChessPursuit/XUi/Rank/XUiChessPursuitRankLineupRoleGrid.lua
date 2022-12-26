local XUiChessPursuitRankLineupRoleGrid = XClass(nil, "XUiChessPursuitRankLineupRoleGrid")

function XUiChessPursuitRankLineupRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiChessPursuitRankLineupRoleGrid:Refresh(characterId, index)
    if not characterId then return end
    
    local id = XRobotManager.CheckIdToCharacterId(characterId)
    if XCharacterConfigs.GetCharacterTemplate(id) then
        local liberateLv = XDataCenter.ChessPursuitManager.GetRankDetailCharacterLiberateLv(index, characterId)
        local charIcon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(id, liberateLv)
        self.RawImage:SetRawImage(charIcon)
    end

    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    self.PanelTry.gameObject:SetActiveEx(isRobot)
end

return XUiChessPursuitRankLineupRoleGrid