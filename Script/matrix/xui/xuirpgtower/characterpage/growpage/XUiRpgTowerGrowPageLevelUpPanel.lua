-- 兵法蓝图角色养成升星页签面板
local XUiRpgTowerGrowPageLevelUpPanel = XClass(nil, "XUiRpgTowerGrowPageLevelUpPanel")
local XUiRpgTowerStarPanel = require("XUi/XUiRpgTower/Common/XUiRpgTowerStarPanel")
local XUiLevelUpTips = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerLevelUpTipsPanel")

function XUiRpgTowerGrowPageLevelUpPanel:Ctor(ui, page)
    XTool.InitUiObjectByUi(self, ui)
    self.Page = page
    self.RpgTowerStarSuccess.gameObject:SetActiveEx(false)
    self.Star = XUiRpgTowerStarPanel.New(self.PanelRpgTowerStars)
    self.StarBefore = XUiRpgTowerStarPanel.New(self.PanelRpgTowerStarsBefore)
    self.StarAfter = XUiRpgTowerStarPanel.New(self.PanelRpgTowerStarsAfter)
    self.LevelUpTips = XUiLevelUpTips.New(self.RpgTowerStarSuccess)
    self.BtnLevelUp.CallBack = function() self:OnClickLevelUp() end
    self.BtnReset.CallBack = function() self:OnClickReset() end
    if self.RImgLevelUpItemIcon then CsXUiHelper.RegisterClickEvent(self.RImgLevelUpItemIcon, function() self:OnClickLevelUpItemIcon() end) end
end
--================
--显示面板
--================
function XUiRpgTowerGrowPageLevelUpPanel:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self:AddEventListener()
end
--================
--隐藏面板
--================
function XUiRpgTowerGrowPageLevelUpPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
    self:RemoveEventListener()
end
--================
--刷新面板数据，显示控件
--================
function XUiRpgTowerGrowPageLevelUpPanel:RefreshData(rChara)
    self.RCharacter = rChara
    self.Star:ShowStar(self.RCharacter:GetLevel())
    self.StarBefore:ShowStar(self.RCharacter:GetLevel())
    if not self.RCharacter:GetIsMaxLevel() then
        self.PanelStarsAdvanced.gameObject:SetActiveEx(true)
        self.TxtMax.gameObject:SetActiveEx(false) 
        self.StarAfter:ShowStar(self.RCharacter:GetLevel() + 1)
        self.BtnLevelUp:SetButtonState(CS.UiButtonState.Normal)
        self.BtnLevelUp.TempState = CS.UiButtonState.Normal
        if self.PanelUpgrade then self.PanelUpgrade.gameObject:SetActiveEx(true) end
    else
        self.PanelStarsAdvanced.gameObject:SetActiveEx(false)
        self.TxtMax.gameObject:SetActiveEx(true)
        self.BtnLevelUp:SetButtonState(CS.UiButtonState.Disable)
        self.BtnLevelUp.TempState = CS.UiButtonState.Disable
        if self.PanelUpgrade then self.PanelUpgrade.gameObject:SetActiveEx(false) end
    end
    self.TxtCharaGrade.text = self.RCharacter:GetGradeName()
    self.TxtSkillUp.text = self.RCharacter:GetSkillUpDescription()
    local levelUpCondition = self.RCharacter:GetLevelUpCondition()
    if string.IsNilOrEmpty(levelUpCondition) then levelUpCondition = CS.XTextManager.GetText("RpgTowerNoUpgradeCondition") end
    self.TxtLevelUpCondition.text = levelUpCondition
    local costStr
    local total = self.RCharacter:GetLevelUpCostItemNum()
    local cost = self.RCharacter:GetLevelUpCostNum()
    if total >= cost then
        costStr = CS.XTextManager.GetText("RpgTowerLevelUpCostStr", total, cost)
    else
        costStr = CS.XTextManager.GetText("RpgTowerLevelUpCostNotEnoughStr", total, cost)
    end
    self.TxtCost.text = costStr
    if self.RImgLevelUpItemIcon then
        local icon = XDataCenter.ItemManager.GetItemIcon(self.RCharacter:GetLevelUpCostItemId())
        self.RImgLevelUpItemIcon:SetRawImage(icon)
    end 
end
--================
--角色升级成功时（回调）
--================
function XUiRpgTowerGrowPageLevelUpPanel:OnLevelUp(rChara)
    self.LevelUpTips:ShowTips(rChara)
end
--================
--面板被回收时（移除UIEvent监听）
--================
function XUiRpgTowerGrowPageLevelUpPanel:OnCollect()
    self:RemoveEventListener()
end
--================
--当点击升级按钮时
--================
function XUiRpgTowerGrowPageLevelUpPanel:OnClickLevelUp()
    XDataCenter.RpgTowerManager.CharaUpgrade(self.RCharacter:GetCharacterId())
end
--================
--当点击升级道具图标时
--================
function XUiRpgTowerGrowPageLevelUpPanel:OnClickLevelUpItemIcon()
    if self.RCharacter then XLuaUiManager.Open("UiTip", self.RCharacter:GetLevelUpCostItemId()) end
end
--================
--当点击重置按钮时
--================
function XUiRpgTowerGrowPageLevelUpPanel:OnClickReset()
    if self.RCharacter:GetLevel() == 1 then
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerNoNeedReset"))
        return
    end
    XDataCenter.RpgTowerManager.CharacterReset(self.RCharacter:GetCharacterId())
end
--================
--增加Event监听
--================
function XUiRpgTowerGrowPageLevelUpPanel:AddEventListener()
    if self.AddEvent == true then return end
    self.AddEvent = true
    XEventManager.AddEventListener(XEventId.EVENT_RPGTOWER_ON_LEVELUP, self.OnLevelUp, self)
end
--================
--移除Event监听
--================
function XUiRpgTowerGrowPageLevelUpPanel:RemoveEventListener()
    if self.AddEvent == false then return end
    self.AddEvent = false
    XEventManager.RemoveEventListener(XEventId.EVENT_RPGTOWER_ON_LEVELUP, self.OnLevelUp, self)
end
return XUiRpgTowerGrowPageLevelUpPanel