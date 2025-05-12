local XUiRogueLikeMemberHead = XClass(nil, "XUiRogueLikeMemberHead")

function XUiRogueLikeMemberHead:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.UiButtonComp = self.Transform:GetComponent("XUiButton")
end

function XUiRogueLikeMemberHead:ClearMemberHead()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgSword.gameObject:SetActiveEx(false)
    self.TxtSword.text = ""
    self.ImgIconUp.gameObject:SetActiveEx(false)
end

function XUiRogueLikeMemberHead:SetMemberInfo(characterId, isHalf, isRobot)
    self.CharacterId = characterId
    if not characterId or characterId == 0 then
        self:ClearMemberHead()
        return
    end

    if isRobot then
        self.CharacterId = XRobotManager.GetCharacterId(self.CharacterId)
        if not self.CharacterId or self.CharacterId == 0 then
            self:ClearMemberHead()
            return
        end
    end
    self.RImgRole.gameObject:SetActiveEx(true)
    self.ImgSword.gameObject:SetActiveEx(true)

    if isHalf then
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(self.CharacterId))
    else
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.CharacterId))
    end
    if isRobot then
        self.TxtSword.text = ""
    else
        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
        self.TxtSword.text = math.floor(character.Ability)
    end
    self.ImgIconUp.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(characterId))
end

function XUiRogueLikeMemberHead:SetMemberCallBack(cb)
    if cb and self.UiButtonComp then
        self.UiButtonComp.CallBack = function() cb() end
    end
end

return XUiRogueLikeMemberHead