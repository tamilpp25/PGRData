local XUiChessPursuitGridQuickDeployMember = XClass(nil, "XUiChessPursuitGridQuickDeployMember")

function XUiChessPursuitGridQuickDeployMember:Ctor(ui, pos, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Pos = pos
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiChessPursuitGridQuickDeployMember:InitComponent()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnMember.CallBack = function() self:OnMemberClick() end

    local color = XUiHelper.Hexcolor2Color(XChessPursuitConfig.MEMBER_POS_COLOR[self.Pos])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color
end

function XUiChessPursuitGridQuickDeployMember:Refresh(characterId, team, characterLimitType, teamGridIndex)
    self.CharacterId = characterId
    self.Team = team
    self.CharacterLimitType = characterLimitType
    self.TeamGridIndex = teamGridIndex

    if characterId and characterId ~= 0 then
        local isRobot = XRobotManager.CheckIsRobotId(characterId)
        local id = XRobotManager.CheckIdToCharacterId(characterId)
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(id))
        self.TryTag.gameObject:SetActiveEx(isRobot)
    else
        self.RImgRole.gameObject:SetActiveEx(false)
        self.TryTag.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiChessPursuitGridQuickDeployMember:OnMemberClick()
    if self.ClickCb then
        self.ClickCb(self.CharacterId, self, self.Pos, self.Team, self.CharacterLimitType, self.TeamGridIndex)
    end
end

function XUiChessPursuitGridQuickDeployMember:ShowEffect()
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiChessPursuitGridQuickDeployMember:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiChessPursuitGridQuickDeployMember:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.Pos == captainPos)
end

function XUiChessPursuitGridQuickDeployMember:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.Pos == firstFightPos)
end

return XUiChessPursuitGridQuickDeployMember