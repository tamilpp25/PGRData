local XUiChessPursuitRankLineupRoleGrid = XClass(nil, "XUiChessPursuitRankLineupRoleGrid")

function XUiChessPursuitRankLineupRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiChessPursuitRankLineupRoleGrid:Refresh(characterId, index)
    if not characterId then return end

    local id = XRobotManager.CheckIdToCharacterId(characterId)
    if XMVCA.XCharacter:GetCharacterTemplate(id) then
        local headInfo = XDataCenter.ChessPursuitManager.GetRankDetailCharacterHeadInfo(index, characterId) or {}
        local charIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(id, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
        self.RawImage:SetRawImage(charIcon)
    end

    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    self.PanelTry.gameObject:SetActiveEx(isRobot)
end

return XUiChessPursuitRankLineupRoleGrid