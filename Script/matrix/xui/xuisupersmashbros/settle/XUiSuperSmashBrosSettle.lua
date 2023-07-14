
local XUiSuperSmashBrosSettle = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosSettle")

function XUiSuperSmashBrosSettle:OnStart(mode)
    self.Mode = mode
    self:InitPanel()
end

function XUiSuperSmashBrosSettle:InitPanel()
    XUiHelper.RegisterClickEvent(self, self.BtnRight, function() self:OnClickExit() end)
    self.TxtModeName.text = self.Mode:GetName()
    self.TxtWinCount.text = self.Mode:GetWinCount()
    self.TxtSpendTime.text = XUiHelper.GetTime(self.Mode:GetSpendTime(), XUiHelper.TimeFormatType.DEFAULT)
    local ownTeam = self.Mode:GetBattleTeam()
    local charaId = ownTeam and ownTeam[1]
    local chara = charaId and XDataCenter.SuperSmashBrosManager.GetRoleById(charaId)
    if chara then
        self.RImgRole:SetRawImage(chara:GetHalfBodyIcon())
        local core = chara:GetCore()
        if core then
            self.TxtCoreName.text = core:GetName()
            self.RImgCoreIcon:SetRawImage(core:GetIcon())
        else
            self.RImgCoreIcon.gameObject:SetActiveEx(false)
            self.TxtCoreName.gameObject:SetActiveEx(false)
        end
    end
end

function XUiSuperSmashBrosSettle:OnClickExit()
    XLuaUiManager.Remove("UiSuperSmashBrosReady")
    self:Close()
end

function XUiSuperSmashBrosSettle:OnDestroy()
    XDataCenter.SuperSmashBrosManager.ResetMode()
end