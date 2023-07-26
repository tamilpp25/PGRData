local XUiGridRiftQuickDeployMember = XClass(nil, "XUiGridRiftQuickDeployMember")
local MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

function XUiGridRiftQuickDeployMember:Ctor(ui, pos, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Pos = pos
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridRiftQuickDeployMember:InitComponent()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnMember.CallBack = function() self:OnMemberClick() end

    local color = XUiHelper.Hexcolor2Color(MEMBER_POS_COLOR[self.Pos])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color

    self.PanelEffectRT = self.PanelEffect:GetComponent("RectTransform")
    self.PanelViewRT = self.Transform.parent.parent.parent.parent:GetComponent("RectTransform")
end

function XUiGridRiftQuickDeployMember:Refresh(xTeam)
    self.XTeam = xTeam
    local roleId = xTeam:GetEntityIdByTeamPos(self.Pos)
    self.XRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)

    if self.XRole then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(self.XRole:GetSmallHeadIcon())
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end
    self.PanelEffect.gameObject:SetActiveEx(false)
    
    self.TryTag.gameObject:SetActiveEx(self.XRole and self.XRole:GetIsRobot())
end

function XUiGridRiftQuickDeployMember:OnMemberClick()
    if self.ClickCb then
        self.ClickCb(self, self.XRole)
    end
end

function XUiGridRiftQuickDeployMember:ShowEffect()
    --判断特效父节点是否在滑动视口内
    if not self.PanelEffectRT:Overlaps(self.PanelViewRT) then return end

    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiGridRiftQuickDeployMember:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridRiftQuickDeployMember:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.Pos == captainPos)
end

function XUiGridRiftQuickDeployMember:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.Pos == firstFightPos)
end

return XUiGridRiftQuickDeployMember