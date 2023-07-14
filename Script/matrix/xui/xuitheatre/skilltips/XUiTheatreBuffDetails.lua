-- V1.29 角色技能优化 该类不在使用 具体使用在 UiSkillDetailsTips
--######################## XGridSkill 技能格子 ########################
local XGridSkill = XClass(nil, "XGridSkill")

function XGridSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.RImgBg.gameObject:SetActiveEx(false)
end

function XGridSkill:SetData(icon)
    self.RImgIcon:SetRawImage(icon)
end

--肉鸽玩法技能详情弹窗
local XUiTheatreBuffDetails = XLuaUiManager.Register(XLuaUi, "UiTheatreBuffDetails")

local CSTextManagerGetText = CS.XTextManager.GetText

function XUiTheatreBuffDetails:OnAwake()
    self:AddListener()
    self.SkillGrid = XGridSkill.New(self.GridBuff)
end

function XUiTheatreBuffDetails:AddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiTheatreBuffDetails:OnStart(skillId, skillLevel)
    self.TxtTitle.text = CSTextManagerGetText("SCTipBossSkillDetailName")
    self.TxtDescTitle.text = CSTextManagerGetText("SCTipBossSkillDetailDesc")
    local configDes = XCharacterConfigs.GetSkillGradeDesConfig(skillId, skillLevel)
    self.TxtName.text = configDes.Name
    self.TxtDesc.text = configDes.Intro
    self.TxtLv.text = skillLevel
    self.SkillGrid:SetData(configDes.Icon)
end