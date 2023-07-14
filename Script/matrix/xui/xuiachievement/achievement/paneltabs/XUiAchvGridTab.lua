--================
--页签对象
--================
local XUiAchvGridTab = XClass(nil, "XUiAchvGridTab")

function XUiAchvGridTab:Ctor(uiPrefab, onSelectCb)
    self.GameObjct = uiPrefab.gameObject
    self.Transform = uiPrefab.transform
    self.Button = self.GameObjct:GetComponent("XUiButton")
    self.OnSelectCb = onSelectCb
end

function XUiAchvGridTab:RefreshData(achievementTypeCfg)
    self.AchievementTypeId = achievementTypeCfg.Id
    self.Button:SetName(achievementTypeCfg.Name)
    self:ShowReddot()
end

function XUiAchvGridTab:ShowReddot()
    self.Button:ShowReddot(XDataCenter.AchievementManager.CheckHasRewardByType(self.AchievementTypeId))
end

function XUiAchvGridTab:GetButton()
    return self.Button
end

function XUiAchvGridTab:OnSelect()
    if self.OnSelectCb then
        self.OnSelectCb(self.AchievementTypeId)
    end
end

function XUiAchvGridTab:Show()
    self.GameObjct:SetActiveEx(true)
end

function XUiAchvGridTab:Hide()
    self.GameObjct:SetActiveEx(false)
end

return XUiAchvGridTab