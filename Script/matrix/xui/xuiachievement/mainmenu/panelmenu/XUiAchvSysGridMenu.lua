--===============
--成就系统菜单项
--===============
local XUiAchvSysGridMenu = XClass(nil, "XUiAchvSysGridMenu")

function XUiAchvSysGridMenu:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    XUiHelper.RegisterClickEvent(self, self.GridAchievementTypeBanner, handler(self, self.OnClick))
end

function XUiAchvSysGridMenu:RefreshData(baseTypeCfg)
    if not baseTypeCfg then
        self:Hide()
        return
    end
    self.BaseTypeId = baseTypeCfg.Id
    self.TxtName.text = baseTypeCfg.Name
    self.RImgIcon:SetRawImage(baseTypeCfg.EntryImage)
    if self.Red then
        self.Red.gameObject:SetActiveEx(XDataCenter.AchievementManager.CheckHasRewardByBaseType(self.BaseTypeId))
    end
    self:Refresh()
end

function XUiAchvSysGridMenu:Refresh()
    self.TxtAchievementCount.text = XUiHelper.GetText("AchievementCount",
        XDataCenter.AchievementManager.GetAchievementCompleteCountByType(self.BaseTypeId))
end

function XUiAchvSysGridMenu:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiAchvSysGridMenu:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiAchvSysGridMenu:OnClick()
    XLuaUiManager.Open("UiAchievement", self.BaseTypeId)
end

return XUiAchvSysGridMenu