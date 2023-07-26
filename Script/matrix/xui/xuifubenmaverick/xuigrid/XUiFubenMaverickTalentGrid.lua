local XUiFubenMaverickTalentGrid = XClass(nil, "XUiFubenMaverickTalentGrid")
local XState = { Lock = 1, Unlock = 2, Inactive = 3, Active = 4 }
local XBtnText = { 
    [XState.Lock] = "MaverickTalentLock", 
    [XState.Unlock] = "MaverickTalentLock",
    [XState.Inactive] = "MaverickTalentActive",
    [XState.Active] = "MaverickTalentInactive",
}

function XUiFubenMaverickTalentGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiFubenMaverickTalentGrid:Refresh(memberId, talentId)
    self.MemberId = memberId or self.MemberId
    self.TalentId = talentId or self.TalentId

    if self.MemberId and self.TalentId then
        local talentConfig = XDataCenter.MaverickManager.GetTalentConfig(self.TalentId)
        self.TxtName1.text = talentConfig.Name
        self.TxtName2.text = talentConfig.Name
        self.Icon1:SetRawImage(talentConfig.Icon)
        self.Icon2:SetRawImage(talentConfig.Icon)

        if XDataCenter.MaverickManager.CheckTalentActive(self.MemberId, self.TalentId) then
            self.State = XState.Active
        elseif XDataCenter.MaverickManager.CheckTalentCanActive(self.MemberId, self.TalentId) then
            self.State = XState.Inactive
        elseif XDataCenter.MaverickManager.CheckTalentUnlock(self.MemberId, self.TalentId) then
            self.State = XState.Unlock
        else
            self.State = XState.Lock
        end
        
        self.PanelLock.gameObject:SetActiveEx(self.State == XState.Lock)
        self.PanelActive.gameObject:SetActiveEx(self.State == XState.Active)
        self.PanelEffect.gameObject:SetActiveEx(self.State == XState.Inactive)
        self.PanelInactive.gameObject:SetActiveEx(self.State ~= XState.Active)
        
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
    end
end

function XUiFubenMaverickTalentGrid:OnClick()
    if self.TalentId then
        local talentConfig = XDataCenter.MaverickManager.GetTalentConfig(self.TalentId)
        local data = {
            Name = talentConfig.Name,
            Icon = talentConfig.Icon,
            Intro = talentConfig.Intro,
            Condition = self:GetConditionText(),
            BtnText = CSXTextManagerGetText(XBtnText[self.State]),
        }
        data.OnClick = function(ui)
            if self.State == XState.Active then
                XDataCenter.MaverickManager.DisableTalent(self.MemberId, self.TalentId)
                ui:Close()
            elseif self.State == XState.Inactive then
                XDataCenter.MaverickManager.EnableTalent(self.MemberId, self.TalentId)
                ui:Close()
            else
                XUiManager.TipMsg(data.Condition)
            end
        end
        XLuaUiManager.Open("UiFubenMaverickSkillTips", data)
    end
end

function XUiFubenMaverickTalentGrid:GetConditionText()
    local talentConfig = XDataCenter.MaverickManager.GetTalentConfig(self.TalentId)
    if self.State == XState.Lock then
        return CSXTextManagerGetText("MaverickTalentUnlockLvCondition", talentConfig.UnlockLevel)
    elseif self.State == XState.Unlock then
        talentConfig = XDataCenter.MaverickManager.GetTalentConfig(talentConfig.PreTalentId)
        return CSXTextManagerGetText("MaverickTalentUnlockPreTalentCondition", talentConfig.Name)
    end
end

return XUiFubenMaverickTalentGrid