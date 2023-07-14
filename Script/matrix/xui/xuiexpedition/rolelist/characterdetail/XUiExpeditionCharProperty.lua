--虚像地平线成员列表界面：角色展示页面: 角色状态栏
local XUiExpeditionCharProperty = XClass(nil, "XUiExpeditionCharProperty")

function XUiExpeditionCharProperty:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionCharProperty:ShowPanel(robotData)
    self.RobotCfg = robotData
    self.CharacterId = self.RobotCfg.CharacterId
    self.IsShow = true
    self.GameObject:SetActive(true)
    self.PanelLeveInfo.gameObject:SetActive(true)
    self.BtnLiberation = self.PanelLeveInfo.transform:Find("BtnLiberation")
    self.ExpBar = self.PanelLeveInfo.transform:Find("ExpBar")
    self.LeveInfoQiehuan:PlayTimelineAnimation()
    self:UpdatePanel()
    self.BtnLevelUpButton.gameObject:SetActive(false)
    self.ImgMaxLevel.gameObject:SetActive(self.RobotCfg.CharacterLevel == XCharacterConfigs.GetCharMaxLevel(self.CharacterId))
end

function XUiExpeditionCharProperty:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiExpeditionCharProperty:UpdatePanel()
    self.ExpBar.gameObject:SetActiveEx(false)
    self.BtnLiberation.gameObject:SetActiveEx(false)
    self.TxtCurLevel.text = self.RobotCfg.CharacterLevel
    self.TxtMaxLevel.text = "/" .. XCharacterConfigs.GetCharMaxLevel(self.CharacterId)
    self.TxtExp.text = "-"
    self.ImgFill.fillAmount = 1
    self.CharacterAttributes = XRobotManager.GetRobotAttribs(self.RobotCfg.Id)
    self.TxtAttack.text = FixToInt(self.CharacterAttributes[XNpcAttribType.AttackNormal])
    self.TxtLife.text = FixToInt(self.CharacterAttributes[XNpcAttribType.Life])
    self.TxtDefense.text = FixToInt(self.CharacterAttributes[XNpcAttribType.DefenseNormal])
    self.TxtCrit.text = FixToInt(self.CharacterAttributes[XNpcAttribType.Crit])
end

return XUiExpeditionCharProperty