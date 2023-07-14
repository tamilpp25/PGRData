--装修的格子
local XUiDecorationGrid = XClass(nil, "XUiDecorationGrid")

function XUiDecorationGrid:Ctor(ui, decorationId, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:InitUi()
    XUiHelper.RegisterClickEvent(self, self.GuildSkillPointBtn, self.OnGuildSkillPointBtnClick)

    self.ClickCallback = clickCb
    self.DecorationManager = XDataCenter.TheatreManager.GetDecorationManager()
    self.DecorationId = decorationId
    self:SetSelectActive(false)
end

function XUiDecorationGrid:InitUi()
    self.GuildSkillPointBtn = XUiHelper.TryGetComponent(self.Transform, "GuildSkillPointBtn", "XUiButton")
    self.SelectIcon = XUiHelper.TryGetComponent(self.Transform, "Select")
    self.NewTag = XUiHelper.TryGetComponent(self.Transform, "New")
    self.TxtLevelByBtnNormal = XUiHelper.TryGetComponent(self.GuildSkillPointBtn.transform, "GuildSkillPointNormal/TxtEnName", "Text")
    self.TxtLevelByBtnPress = XUiHelper.TryGetComponent(self.GuildSkillPointBtn.transform, "GuildSkillPointDisable/TxtEnName", "Text")
    self.ImgSkillByBtnNormal = XUiHelper.TryGetComponent(self.GuildSkillPointBtn.transform, "GuildSkillPointNormal/ImgSkill", "RawImage")
    self.ImgSkillByBtnPress = XUiHelper.TryGetComponent(self.GuildSkillPointBtn.transform, "GuildSkillPointDisable/ImgSkill", "RawImage")
    self.ImgSkillByBtnDisable = XUiHelper.TryGetComponent(self.GuildSkillPointBtn.transform, "GuildSkillPointPress /ImgSkill", "RawImage")
    self.EffectActivation = XUiHelper.TryGetComponent(self.Transform, "EffectActivation")
end

function XUiDecorationGrid:UpdateIcon()
    local theatreDecorationId = self.DecorationManager:GetTheatreDecorationId(self.DecorationId)
    if not theatreDecorationId then
        return
    end
    --图标
    local iconPath = XTheatreConfigs.GetDecorationIcon(theatreDecorationId)
    self.ImgSkillByBtnNormal:SetRawImage(iconPath)
    self.ImgSkillByBtnPress:SetRawImage(iconPath)
    self.ImgSkillByBtnDisable:SetRawImage(iconPath)
end

function XUiDecorationGrid:Refresh()
    local decorationId = self.DecorationId
    local theatreDecorationId = self.DecorationManager:GetTheatreDecorationId(decorationId)
    if not theatreDecorationId then
        return
    end

    --等级
    local maxLevel = XTheatreConfigs.GetTheatreDecorationMaxLv(decorationId)
    local curLevel = self.DecorationManager:GetDecorationLv(decorationId)
    local isMaxLv = curLevel >= maxLevel
    local levelText = isMaxLv and XUiHelper.GetText("TheatreDecorationMaxLevel") or XUiHelper.GetText("TheatreDecorationLevel", curLevel, maxLevel)
    self.TxtLevelByBtnNormal.text = levelText
    self.TxtLevelByBtnPress.text = levelText

    --按钮状态
    local isActive = self.DecorationManager:IsActiveDecoration(decorationId)
    self.GuildSkillPointBtn:SetDisable(not isActive)

    --可升级提醒
    local conditionId = self.DecorationManager:GetTheatreDecorationNextLvConditionId(decorationId)
    local ret = not XTool.IsNumberValid(conditionId) and true or XConditionManager.CheckCondition(conditionId)
    local costItemId = XTheatreConfigs.GetDecorationUpgradeCostItemId(theatreDecorationId)
    local costUpgradeCost = XTheatreConfigs.GetDecorationUpgradeCost(theatreDecorationId)
    local costCostCount = XDataCenter.ItemManager.GetCount(costItemId)
    local isLevelUp = not isMaxLv and ret and costCostCount >= costUpgradeCost
    self.NewTag.gameObject:SetActiveEx(isActive and isLevelUp)

    --可解锁提醒
    self.EffectActivation.gameObject:SetActiveEx(not isActive and isLevelUp)

    self:UpdateIcon()
end

function XUiDecorationGrid:SetSelectActive(isActive)
    self.SelectIcon.gameObject:SetActiveEx(isActive)
end

function XUiDecorationGrid:GetDecorationId()
    return self.DecorationId
end

function XUiDecorationGrid:OnGuildSkillPointBtnClick()
    if self.ClickCallback then
        self.ClickCallback(self)
    end
end

function XUiDecorationGrid:GetGuildSkillPointBtn()
    return self.GuildSkillPointBtn
end

return XUiDecorationGrid