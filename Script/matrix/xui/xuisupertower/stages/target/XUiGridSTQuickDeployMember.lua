local XUiGridSTQuickDeployMember = XClass(nil, "XUiGridSTQuickDeployMember")
local MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

function XUiGridSTQuickDeployMember:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridSTQuickDeployMember:InitComponent()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnMember.CallBack = function() self:OnMemberClick() end
end

function XUiGridSTQuickDeployMember:Refresh(memberRole, memberPos)
    local color = XUiHelper.Hexcolor2Color(MEMBER_POS_COLOR[memberPos])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color
    self.MemberPos = memberPos
    local isEmpty = not memberRole
    if not isEmpty then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(memberRole:GetSmallHeadIcon())
        self.TryTag.gameObject:SetActiveEx(memberRole:GetIsRobot())
    else
        self.RImgRole.gameObject:SetActiveEx(false)
        self.TryTag.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiGridSTQuickDeployMember:OnMemberClick()
    if self.ClickCb then
        self.ClickCb(self, self.MemberPos)
    end
end

function XUiGridSTQuickDeployMember:ShowEffect()
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiGridSTQuickDeployMember:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridSTQuickDeployMember:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.MemberPos == captainPos)
end

function XUiGridSTQuickDeployMember:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.MemberPos == firstFightPos)
end

return XUiGridSTQuickDeployMember