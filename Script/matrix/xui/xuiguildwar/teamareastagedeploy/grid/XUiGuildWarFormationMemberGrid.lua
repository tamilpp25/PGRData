local XUiGuildWarFormationMemberGrid = XClass(nil, "XUiGuildWarFormationMemberGrid")

local MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

---@param rootUi XUiGuildWarFormationTeamGrid
function XUiGuildWarFormationMemberGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGuildWarFormationMemberGrid:InitComponent()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.ImgAbility.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnMember.CallBack = function() self:OnMemberClick() end
    self.PanelEffectRT = self.PanelEffect:GetComponent("RectTransform")
    self.PanelViewRT = self.Transform.parent.parent.parent.parent:GetComponent("RectTransform")
end

---@param guildWarMember XGuildWarMember
function XUiGuildWarFormationMemberGrid:Refresh(index,guildWarMember)
    self.CharacterId = guildWarMember:GetEntityId()
    self.Pos = index
    
    local color = XUiHelper.Hexcolor2Color(MEMBER_POS_COLOR[self.Pos])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color
    
    if self.CharacterId and self.CharacterId ~= 0 then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.CharacterId))
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:SetActiveEx(false)
    --支援图标
    self.ImgSupport.gameObject:SetActiveEx(guildWarMember:IsAssitant())
end

function XUiGuildWarFormationMemberGrid:ShowEffect()
    --判断特效父节点是否在滑动视口内
    if not self.PanelEffectRT:Overlaps(self.PanelViewRT) then return end

    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiGuildWarFormationMemberGrid:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiGuildWarFormationMemberGrid:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.Pos == captainPos)
end

function XUiGuildWarFormationMemberGrid:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.Pos == firstFightPos)
end

function XUiGuildWarFormationMemberGrid:OnMemberClick()
    self.RootUi:OnMemberClick(self.Pos)
end

return XUiGuildWarFormationMemberGrid