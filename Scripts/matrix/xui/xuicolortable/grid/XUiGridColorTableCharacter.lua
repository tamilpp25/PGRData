local XUiGridColorTableCharacter = XClass(nil, "UiGridColorTableCharacter")

function XUiGridColorTableCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridColorTableCharacter:Refresh(entity)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    self.TxtLevel.text = characterViewModel:GetLevel()
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    self.TxtFight.text = characterViewModel:GetAbility()
    self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    
    -- 试玩图标
    self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))

    -- 处理相同characterId的robot
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entity:GetId())
    
    -- 领队
    local isCaptain = XDataCenter.ColorTableManager.IsCaptainRole(characterId)
    self.CharTag1.gameObject:SetActiveEx(isCaptain)

    -- 特攻
    local isSpecialAtk = XDataCenter.ColorTableManager.IsSpecialRole(characterId)
    self.CharTag2.gameObject:SetActiveEx(isSpecialAtk)
end

function XUiGridColorTableCharacter:SetSelectStatus(value)
    self.PanelSelected.gameObject:SetActiveEx(value)
end

function XUiGridColorTableCharacter:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
end

return XUiGridColorTableCharacter