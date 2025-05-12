local XUiGridSkillElement = XClass(nil, "XUiGridSkillElement")
local CSTextManagerGetText = CS.XTextManager.GetText
local State = {Normal = 1, Activate = 2}

function XUiGridSkillElement:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridState = State.Normal
    XTool.InitUiObject(self)
end

function XUiGridSkillElement:UpdateGrid(skillGroup, carrierElement)
    self.SkillGroup = skillGroup
    self.CarrierElement = carrierElement
    local IsSameElement = carrierElement and skillGroup:GetActiveElement() == carrierElement
    if IsSameElement then
        self:ChangeState(State.Activate)
    else
        self:ChangeState(State.Normal)
    end
end

function XUiGridSkillElement:ChangeState(state)
    self.GridState = state
    self:ShowNormal(self.GridState == State.Normal)
    self:ShowActivate(self.GridState == State.Activate)
    self:UpdateSkillInfo()
end

function XUiGridSkillElement:UpdateSkillInfo()
    local panel = {}
    if self.GridState == State.Normal then
        panel = self.Normal
    elseif self.GridState == State.Activate then
        panel = self.Activate
    end

    local elementConfig = XMVCA.XCharacter:GetCharElement(self.SkillGroup:GetActiveElement())

    panel:GetObject("RImgIcon"):SetRawImage(elementConfig.Icon2)
    panel:GetObject("TxtName").text = elementConfig.ElementName
    panel:GetObject("TxtContent").text = self.SkillGroup:GetSkillDesc()
end

function XUiGridSkillElement:ShowActivate(IsActivate)
    self.Activate.gameObject:SetActiveEx(IsActivate)
end

function XUiGridSkillElement:ShowNormal(IsNormal)
    self.Normal.gameObject:SetActiveEx(IsNormal)
end

return XUiGridSkillElement