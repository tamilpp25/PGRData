-- 兵法蓝图角色天赋总览页面
local XUiRpgTowerCollect = XLuaUiManager.Register(XLuaUi, "UiRpgTowerCollect")
local PanelStatus = require("XUi/XUiRpgTower/CharacterPage/TalentTotalView/XUiRpgTowerCollectPanelStatus")
local PanelSkill = require("XUi/XUiRpgTower/CharacterPage/TalentTotalView/XUiRpgTowerCollectPanelSkillInfo")
local PanelTalent = require("XUi/XUiRpgTower/CharacterPage/TalentTotalView/XUiRpgTowerCollectPanelTalent")

function XUiRpgTowerCollect:OnAwake()
    XTool.InitUiObject(self)
    self:InitPanels()
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
end

function XUiRpgTowerCollect:OnStart(rCharacter, talentTypeId)
    self.RCharacter = rCharacter
    self.Type = talentTypeId
    self:Refresh()
end

function XUiRpgTowerCollect:InitPanels()
    --self:InitPanelStatus()
    --self:InitPanelSkillInfo()
    self:InitPanelTalent()
end

function XUiRpgTowerCollect:InitPanelStatus()
    self.Status = PanelStatus.New(self.PanelStatus)
end

function XUiRpgTowerCollect:InitPanelSkillInfo()
    self.SkillInfo = PanelSkill.New(self.PanelSkill)
end

function XUiRpgTowerCollect:InitPanelTalent()
    self.Talent = PanelTalent.New(self.GameObject)
end

function XUiRpgTowerCollect:Refresh()
    --self.Status:Refresh(self.RCharacter)
    --self.SkillInfo:Refresh(self.RCharacter)
    self.Talent:Refresh(self.RCharacter, self.Type)
end

function XUiRpgTowerCollect:OnClickClose()
    self:Close()
end