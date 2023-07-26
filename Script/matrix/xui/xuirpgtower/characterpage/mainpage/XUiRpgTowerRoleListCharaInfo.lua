-- 兵器蓝图角色页面角色状态面板
local XUiRpgTowerRoleListCharaInfo = XClass(nil, "XUiRpgTowerRoleListCharaInfo")
local XUiRpgTowerCharaInfoInfo = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerCharaInfoInfo")
local XUiRpgTowerCharaInfoStatus = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerCharaInfoStatus")
local XUiRpgTowerCharaInfoSkills = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerCharaInfoSkills")
function XUiRpgTowerRoleListCharaInfo:Ctor(ui, page)
    XTool.InitUiObjectByUi(self, ui)
    self.Page = page
    self.InfoPanel = XUiRpgTowerCharaInfoInfo.New(self.PanelCharacterInfo)
    self.StatusPanel = XUiRpgTowerCharaInfoStatus.New(self.PanelCharacterStatus)
    self.SkillPanel = XUiRpgTowerCharaInfoSkills.New(self.PanelCharacterSkills)
    CsXUiHelper.RegisterClickEvent(self.BtnLevelUp, function() self:OnClickBtnLevelUp() end)
end
--================
--刷新面板数据（刷新子面板）
--================
function XUiRpgTowerRoleListCharaInfo:RefreshData(rChara)
    self.InfoPanel:RefreshInfo(rChara)
    self.StatusPanel:RefreshStatus(rChara)
    self.SkillPanel:RefreshSkills(rChara)
    self.LevelUpRedPoint.gameObject:SetActiveEx(rChara:CheckCanActiveTalent())
    if self.AnimEnable then
        self.AnimEnable.time = 0
        self.AnimEnable:Play()
    end
    self.Page.RootUi:PlayAnimation("SViewCharacterListEnable")
end
--================
--点击升级按钮
--================
function XUiRpgTowerRoleListCharaInfo:OnClickBtnLevelUp()
    self.Page.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.TYPESELECT)
end
--================
--显示面板
--================
function XUiRpgTowerRoleListCharaInfo:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--================
--隐藏面板
--================
function XUiRpgTowerRoleListCharaInfo:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiRpgTowerRoleListCharaInfo