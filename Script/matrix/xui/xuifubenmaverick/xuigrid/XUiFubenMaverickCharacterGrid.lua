local XUiFubenMaverickCharacterGrid = XClass(nil, "XUiFubenMaverickCharacterGrid")

function XUiFubenMaverickCharacterGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiFubenMaverickCharacterGrid:Refresh(memberId)
    self.MemberId = memberId or self.MemberId
    
    local member = XDataCenter.MaverickManager.GetMember(self.MemberId)
    self.TxtLevel.text = member.Level
    local combatScore = XDataCenter.MaverickManager.GetCombatScore(member)
    self.TxtCombatScore.text = combatScore
    self.RobotId = XDataCenter.MaverickManager.GetRobotId(member)
    self.CharacterId = XRobotManager.GetCharacterId(self.RobotId)
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.CharacterId))
   
    self:RefreshSelect()

    if self.RootUi.ShowRedDot then
        XRedPointManager.CheckOnce(self.OnCheckRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER }, self.MemberId)
    else
        self:OnCheckRedDot(-1)
    end
end

function XUiFubenMaverickCharacterGrid:OnCheckRedDot(count)
    self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenMaverickCharacterGrid:RefreshSelect()
    self.PanelSelected.gameObject:SetActiveEx(self.RootUi.LastUsedMemberId == self.MemberId)
end

return XUiFubenMaverickCharacterGrid