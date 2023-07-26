local XUiReformEnemyGroupGrid = XClass(nil, "XUiReformEnemyGroupGrid")

function XUiReformEnemyGroupGrid:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnNormal, self.BtnAddGroupClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnExtra, self.BtnAddGroupClicked)
    self.Index = nil
    -- XReformEnemyGroup
    self.EnemyGroup = nil
    self.RootUi = rootUi
end

-- enemyGroup : XReformEnemyGroup
function XUiReformEnemyGroupGrid:SetData(index, enemyGroup)
    self.Index = index
    self.EnemyGroup = enemyGroup
    local isActive = self.EnemyGroup:GetIsActive()
    self.BtnNormal.gameObject:SetActiveEx(isActive)
    self.BtnExtra.gameObject:SetActiveEx(not isActive)
    self.BtnNormal:SetNameByGroup(0, XUiHelper.GetText("ReformEnemyGroupName" .. enemyGroup:GetEnemyGroupIndex()))
    self.BtnNormal:SetNameByGroup(1, XUiHelper.GetText("ReformEnemyCountTip"
        , enemyGroup:GetCurrentEnemyCount(), enemyGroup:GetMaxEnemyCount()))
end

function XUiReformEnemyGroupGrid:BtnAddGroupClicked()
    -- self.CurrentEvolvableGroupIndex
    self.RootUi:SetCurrentGroupIndex(self.Index)
    self.RootUi:RefreshEvolvableData()
end

function XUiReformEnemyGroupGrid:SetSelectedIndex(index)
    if index == self.Index and self.EnemyGroup:GetEnemyGroupType() == XReformConfigs.EnemyGroupType.ExtraEnemy then
        self.BtnNormal.gameObject:SetActiveEx(true)
        self.BtnExtra.gameObject:SetActiveEx(false)
    end
    if self.Index == index then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnNormal:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUiReformEnemyGroupGrid