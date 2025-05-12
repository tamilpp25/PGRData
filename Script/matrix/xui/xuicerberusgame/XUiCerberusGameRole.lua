local XUiCerberusGameRole = XLuaUiManager.Register(XLuaUi, "UiCerberusGameRole")

local CharIndex = 
{
    Role1 = 1,
    Role2 = 2,
    Role3 = 3,
    Team = 4,
}

function XUiCerberusGameRole:OnAwake()
    self:InitButton()
    self.CurSelectIndex = nil
end

function XUiCerberusGameRole:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnTeam, self.OnBtnTeamClick)
    self:BindHelpBtn(self.BtnHelp, "CerberusHelp")

    local tabBtns = { self.BtnRole01, self.BtnRole02, self.BtnRole03 }
    self.BtnTab:Init(tabBtns, function(index) self:OnRoleSelect(index) end)
end

function XUiCerberusGameRole:OnRoleSelect(index)
    if self.CurSelectIndex == index then
        return
    end

    self:ChangeCameraIndex(index)
    self.CurSelectIndex = index
    self:PlayAnimation("QieHuan")
end

function XUiCerberusGameRole:OnStart(model3D)
    self.Model3D = model3D
end

function XUiCerberusGameRole:ChangeCameraIndex(index)
    self.Model3D:SetChangeByRoleBtn(index, true)
    self:RefreshRightInfoByIndex(index)
end

function XUiCerberusGameRole:OnEnable()
    self:RefreshRightInfoByIndex(CharIndex.Team)
end

function XUiCerberusGameRole:GetConfig(index)
    local allConfig = XMVCA.XCerberusGame:GetModelCerberusGameCharacterInfo()
    return allConfig[index]
end

function XUiCerberusGameRole:RefreshRightInfoByIndex(index)
    local config = self:GetConfig(index)
    self.TxtTeamTitle.text = config.TeamTitle
    self.TxtTeamInfo.text = config.TeamInfo
    self.TxtCharacter.text = config.CharacterInfo
    self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
    self.TxtTeamInfo.gameObject:SetActiveEx(not string.IsNilOrEmpty(config.TeamInfo))

    local panel1 = {}
    XTool.InitUiObjectByUi(panel1, self.PanelSkill1)
    panel1.RImgSkillIcon:SetRawImage(config.SkillIcon[1])
    panel1.TxtSkillName.text = config.SkillTitle[1]
    panel1.TxtSkillDesc.text = config.SkillDesc[1]

    local panel2 = {}
    XTool.InitUiObjectByUi(panel2, self.PanelSkill2)
    panel2.RImgSkillIcon:SetRawImage(config.SkillIcon[2])
    panel2.TxtSkillName.text = config.SkillTitle[2]
    panel2.TxtSkillDesc.text = config.SkillDesc[2]
end

function XUiCerberusGameRole:OnBtnTeamClick()
    self:RevertTeamView()
end

function XUiCerberusGameRole:RevertTeamView()
    self:RefreshRightInfoByIndex(CharIndex.Team)
    self.Model3D:SetAllModelCamFalse()
    self.Model3D:SetTrackSelect(2) -- 2是诺克提
    self.Model3D:SetAllModelUnSelect()
    self.Model3D.CurSelectIndex = nil
    self.CurSelectIndex = nil
    self.BtnTab:CancelSelect()
end

function XUiCerberusGameRole:OnDisable()
    self:RevertTeamView()
    self.ParentUi:OnChildUiClose()
end

return XUiCerberusGameRole