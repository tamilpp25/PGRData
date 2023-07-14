local XUiTheatreSkillGrid = require("XUi/XUiTheatre/XUiTheatreSkillGrid")
local XUiTheatreReplaceTips = XLuaUiManager.Register(XLuaUi, "UiTheatreReplaceTips")

function XUiTheatreReplaceTips:OnAwake()
    self:RegisterUiEvents()
end

-- fromSkill : XAdventureSkill
-- toSkill : XAdventureSkill
function XUiTheatreReplaceTips:OnStart(fromSkill, toSkill)
    XUiTheatreSkillGrid.New(self.GridBuff1):SetData(fromSkill, true)
    XUiTheatreSkillGrid.New(self.GridBuff2):SetData(toSkill, true)
    self.TxtBuffName1.text = fromSkill:GetName()
    self.TxtBuffName2.text = toSkill:GetName()
end

--######################## 私有方法 ########################

function XUiTheatreReplaceTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCloseClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClicked)
end

function XUiTheatreReplaceTips:OnBtnCloseClicked()
    self:EmitSignal("Close", false)
    self:Close()
end

function XUiTheatreReplaceTips:OnBtnConfirmClicked()
    self:EmitSignal("Close", true)
    self:Close()
end

return XUiTheatreReplaceTips