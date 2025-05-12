---@class XUiGridQuickDeployMember
local XUiGridQuickDeployMember = XClass(nil, "XUiGridQuickDeployMember")

function XUiGridQuickDeployMember:Ctor(ui, pos, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Pos = pos
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

    local color = XUiHelper.Hexcolor2Color(XEnumConst.BFRT.MEMBER_POS_COLOR[self.Pos])
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color

    self.PanelEffectRT = self.PanelEffect:GetComponent("RectTransform")
    self.PanelViewRT = self.Transform.parent.parent.parent.parent:GetComponent("RectTransform")
end

function XUiGridQuickDeployMember:Refresh(characterId, team, characterLimitType)
    self.CharacterId = characterId
    self.Team = team
    self.CharacterLimitType = characterLimitType

    if characterId and characterId ~= 0 then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end

    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiGridQuickDeployMember:OnMemberClick()
    if self.ClickCb then
        self.ClickCb(self.CharacterId, self, self.Pos, self.Team, self.CharacterLimitType)
    end
end


function XUiGridQuickDeployMember:ShowEffect()
    --判断特效父节点是否在滑动视口内
    if not self.PanelEffectRT:Overlaps(self.PanelViewRT) then return end

    self.PanelEffect.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiGridQuickDeployMember:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridQuickDeployMember:RefreshCaptainPos(captainPos)
    self.ImgLeader.gameObject:SetActiveEx(self.Pos == captainPos)
end

function XUiGridQuickDeployMember:RefreshFirstFightPos(firstFightPos)
    self.ImgFirstRole.gameObject:SetActiveEx(self.Pos == firstFightPos)
end

return XUiGridQuickDeployMember