local XUiBabelMemberHead = XClass(nil, "XUiBabelMemberHead")

function XUiBabelMemberHead:Ctor(ui, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index

    XTool.InitUiObject(self)
    self.UiButtonComp = self.Transform:GetComponent("XUiButton")
end

function XUiBabelMemberHead:ClearMemberHead()
    self.RImgRole.gameObject:SetActiveEx(false)
    self.ImgLeader.gameObject:SetActiveEx(self:IsLeader())
    self.ImgSword.gameObject:SetActiveEx(false)
end

function XUiBabelMemberHead:SetMemberInfo(characterId, isHalf, captainPos)
    self.CharacterId = characterId
    self.CaptainPos = captainPos
    
    local characterViewModel = XEntityHelper.GetCharacterViewModelByEntityId(characterId)
    if not characterViewModel then
        self:ClearMemberHead()
        return
    end

    self.RImgRole.gameObject:SetActiveEx(true)
    self.ImgLeader.gameObject:SetActiveEx(self:IsLeader())
    self.ImgSword.gameObject:SetActiveEx(true)

    if isHalf then
        self.RImgRole:SetRawImage(characterViewModel:GetHalfBodyCommonIcon())
    else
        self.RImgRole:SetRawImage(characterViewModel:GetSmallHeadIcon())
    end

    self.TxtSword.text = math.floor(characterViewModel:GetAbility())
end

function XUiBabelMemberHead:SetMemberCallBack(cb)
    if cb and self.UiButtonComp then
        self.UiButtonComp.CallBack = function() cb() end
    end
end

function XUiBabelMemberHead:IsLeader()
    return self.Index == self.CaptainPos
end

return XUiBabelMemberHead