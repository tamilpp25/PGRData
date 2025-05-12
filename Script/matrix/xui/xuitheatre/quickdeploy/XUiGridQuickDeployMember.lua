local MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

local XUiGridQuickDeployMember = XClass(nil, "XUiGridQuickDeployMember")

function XUiGridQuickDeployMember:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridQuickDeployMember:InitComponent()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnMember.CallBack = function() self:OnMemberClick() end
end

function XUiGridQuickDeployMember:Refresh(teamList, teamId, memberIndex)
    self.MemberIndex = memberIndex
    self.TeamList = teamList
    self.TeamId = teamId

    local color = XUiHelper.Hexcolor2Color(MEMBER_POS_COLOR[self.MemberIndex])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color

    local entityId = self:GetEntityId()
    if XTool.IsNumberValid(entityId) then
        local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:SetActiveEx(false)

    local isRobot = XEntityHelper.GetIsRobot(entityId)
    self.TryTag.gameObject:SetActiveEx(isRobot)
end

function XUiGridQuickDeployMember:OnMemberClick()
    if self.ClickCb then
        self.ClickCb(self, self.MemberIndex)
    end
end

function XUiGridQuickDeployMember:ShowEffect()
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiGridQuickDeployMember:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridQuickDeployMember:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.MemberIndex == captainPos)
end

function XUiGridQuickDeployMember:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.MemberIndex == firstFightPos)
end

function XUiGridQuickDeployMember:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiGridQuickDeployMember:GetEntityId()
    local team = self:GetTeam()
    local entityId = team:GetEntityIdByTeamPos(self.MemberIndex)
    local role = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(entityId)
    return role and role:GetRawDataId()
end

return XUiGridQuickDeployMember