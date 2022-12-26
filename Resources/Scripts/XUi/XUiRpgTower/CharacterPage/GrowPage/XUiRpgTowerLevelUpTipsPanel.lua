-- 兵法蓝图升星成功提示页面控件
local XUiRpgTowerLevelUpTipsPanel = XClass(nil, "XUiRpgTowerLevelUpTipsPanel")
local XUiRpgTowerCharaItem = require("XUi/XUiRpgTower/Common/XUiRpgTowerCharaItem")
local XUiRpgTowerItemIcon = require("XUi/XUiRpgTower/Common/XUiRpgTowerItemIcon")
function XUiRpgTowerLevelUpTipsPanel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PreLevelCharaItem = XUiRpgTowerCharaItem.New(self.CharaItemPreLevel, XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar)
    self.NowLevelCharaItem = XUiRpgTowerCharaItem.New(self.CharaItemNowLevel, XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar)
    CsXUiHelper.RegisterClickEvent(self.BtnCancel, function() self:HidePanel() end)
    self.ItemIcon = XUiRpgTowerItemIcon.New(self.RImgTalentIcon)
    self.GradeUpgradeDisable:stopped('+', function(director) self:HidePanelCallBack() end)
end
--================
--刷新升级提示面板显示控件
--================
function XUiRpgTowerLevelUpTipsPanel:ShowTips(rChara)
    self.PreLevelCharaItem:RefreshData(rChara)
    self.PreLevelCharaItem:SetLevel(rChara:GetLevel() - 1)
    self.NowLevelCharaItem:RefreshData(rChara)
    self.TxtUnlockTheNumber.text = rChara:GetPreLevelSkillUpDescription()
    self.TxtTalentNumber.text = rChara:GetPreUpgradeNaturePoint()
    self.ItemIcon:InitIcon(rChara:GetTalentItem())
    self:ShowPanel()
end
--================
--显示面板
--================
function XUiRpgTowerLevelUpTipsPanel:ShowPanel()
    self.GradeUpgradeEnable.gameObject:SetActiveEx(false)
    self.GradeUpgradeDisable.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
    self.GradeUpgradeEnable.gameObject:SetActiveEx(true)
end
--================
--隐藏面板
--================
function XUiRpgTowerLevelUpTipsPanel:HidePanel()
    self.GradeUpgradeDisable.gameObject:SetActiveEx(true)
end
--================
--隐藏面板动画结束回调
--================
function XUiRpgTowerLevelUpTipsPanel:HidePanelCallBack(director)
    self.GameObject:SetActiveEx(false)
end
return XUiRpgTowerLevelUpTipsPanel