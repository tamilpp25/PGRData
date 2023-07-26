--######################## XUiPanelRebuildDetaile ########################
local XUiPanelRebuildDetaile = XClass(XSignalData, "XUiPanelRebuildDetaile")

function XUiPanelRebuildDetaile:Ctor(ui, rootUi)
    self.Node = nil
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClicked)
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
end

function XUiPanelRebuildDetaile:SetData(node)
    self.Node = node
    self.RImgIcon:SetRawImage(node:GetShowMonsterIcon())
    self.TxtName.text = node:GetShowMonsterName()
    self.TxtMyTime.text = XUiHelper.GetText("GuildWarMyMaxRebuildTimeTip"
        , XUiHelper.GetTime(node:GetHistoryMaxRebuildTime(), XUiHelper.TimeFormatType.DEFAULT))
    self:RefreshTimeData()
    local monster = self.Node:GetEliteMonsters()[1]
    self.BtnChange.gameObject:SetActiveEx(monster ~= nil)
    -- 设置按钮名称
    self.BtnChange:SetNameByGroup(0, XUiHelper.GetText("GuildWarChangeMonster"))
    local allInfectIsDead = self.BattleManager:CheckAllInfectIsDead()
    self.TxtRebuildTime.transform.parent.gameObject:SetActiveEx(not allInfectIsDead)
    self.PrograssTime.gameObject:SetActiveEx(not allInfectIsDead)
end

function XUiPanelRebuildDetaile:OnBtnChangeClicked()
    self.RootUi:OnBtnChangeClicked()
end

function XUiPanelRebuildDetaile:RefreshTimeData()
    if self.BattleManager:CheckAllInfectIsDead() then
        return
    end
    local node = self.Node
    self.TxtRebuildTime.text = node:GetRebuildTimeStr()
    self.PrograssTime.fillAmount = node:GetRebuildProgress()
    if XTime.GetServerNowTimestamp() >= node:GetRebuildTime() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
    end
end

return XUiPanelRebuildDetaile