local DefaultLifePercent = 100
local DefaultEnergyPercent = 0

local XUiTeamMember = XClass(nil, "XUiTeamMember")

function XUiTeamMember:Ctor(ui, pos, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.Pos = pos
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self.Team = XDataCenter.EscapeManager.GetTeam()
    XUiHelper.RegisterClickEvent(self, self.BtnSelectRole, clickCb)
    self:Init()
end

function XUiTeamMember:Init()
    self.ImgJia = XUiHelper.TryGetComponent(self.Transform, "ImgJia")
    self.PanelDeath = XUiHelper.TryGetComponent(self.Transform, "PanelDeath")
end

function XUiTeamMember:Refresh()
    local pos = self.Pos
    local team = self.Team
    local captainPos = team:GetCaptainPos()
    self.ImgLeader.gameObject:SetActiveEx(captainPos == pos)

    local isInChallenge = XTool.IsNumberValid(self.EscapeData:GetChapterId())
    self.ImgLock.gameObject:SetActiveEx(isInChallenge)

    local entityId = team:GetEntityIdByTeamPos(pos)
    if not XTool.IsNumberValid(entityId) then
        self:SetObjActive(false)
        return
    end

    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    self.TxtMemberName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)

    local characterState = self.EscapeData:GetCharacterState(entityId)
    local lifePermyriadPercent = characterState and characterState:GetLifePermyriadPercent()
    local isDeath = (lifePermyriadPercent and lifePermyriadPercent <= 0) and true or false
    self.ImgProgressHp.fillAmount = lifePermyriadPercent or DefaultLifePercent
    self.ImgProgressEnergy.fillAmount = characterState and characterState:GetEnergyPermyriadPercent() or DefaultEnergyPercent
    if self.PanelDeath then
        self.PanelDeath.gameObject:SetActiveEx(isDeath)
    end

    self.RImgRole:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyImage(XEntityHelper.GetCharacterIdByEntityId(entityId)))

    self:SetObjActive(true)
end

function XUiTeamMember:SetObjActive(isActive)
    self.ImgMemberName.gameObject:SetActiveEx(isActive)
    self.ProgressEnergy.gameObject:SetActiveEx(isActive)
    self.ProgressHP.gameObject:SetActiveEx(isActive)
    self.RImgRole.gameObject:SetActiveEx(isActive)
    if self.ImgJia then
        self.ImgJia.gameObject:SetActiveEx(not isActive)
    end
end

return XUiTeamMember