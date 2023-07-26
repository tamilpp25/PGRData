local XUiTheatreTeamUp = XLuaUiManager.Register(XLuaUi, "UiTheatreTeamUp")

function XUiTheatreTeamUp:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Callback = nil
    self:RegisterUiEvents()
end

function XUiTheatreTeamUp:OnStart(lastLevel, lastPower, callback)
    self.Callback = callback
    local currentLevel = self.AdventureManager:GetCurrentLevel()
    self.TxtLvBefore.text = lastLevel
    self.TxtLvAfter.text = currentLevel
    local lastLevelConfig = XTheatreConfigs.GetLevel2Data(lastLevel)
    local currentLevelConfig = XTheatreConfigs.GetLevel2Data(currentLevel)
    local maxLevel = XTheatreConfigs.GetMaxLevel()
    self.ImgProgress.fillAmount = currentLevel / maxLevel
    self.TxtArmsLvBefore.text = lastLevelConfig.EquipmentShowLevel
    self.TxtArmsLvAfter.text = currentLevelConfig.EquipmentShowLevel
    self.TxtPowerBefore.text = lastPower
    self.TxtPowerAfter.text = self.AdventureManager:GeRoleAveragePower()
end

--######################## 私有方法 ########################

function XUiTheatreTeamUp:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiTheatreTeamUp:Close()
    self.Super.Close(self)
    if self.Callback then self.Callback() end
end

return XUiTheatreTeamUp