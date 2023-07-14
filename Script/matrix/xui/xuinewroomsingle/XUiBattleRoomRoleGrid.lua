local XUiBattleRoomRoleGrid = XClass(nil, "XUiBattleRoomRoleGrid")

function XUiBattleRoomRoleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiBattleRoomRoleGrid:SetData(entity)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    self.TxtLevel.text = characterViewModel:GetLevel()
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    -- 元素图标
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 3 do
        elementIcon = obtainElementIcons[i]
        self["RImgElement" .. i].gameObject:SetActiveEx(elementIcon ~= nil)
        if elementIcon then
            self["RImgElement" .. i]:SetRawImage(elementIcon)
        end
    end
    self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))
    if self.RImgTypeIcon then
        self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    end
end

function XUiBattleRoomRoleGrid:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetInSameStatus(value)
    self.PanelSameRole.gameObject:SetActiveEx(value)
end

function XUiBattleRoomRoleGrid:SetAbility(value)
    self.TxtPower.text = value
end

return XUiBattleRoomRoleGrid