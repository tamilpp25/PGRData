
local XUiSuperSmashBrosBattleResult = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosBattleResult")

function XUiSuperSmashBrosBattleResult:OnStart(settleData)
    self.SettleData = settleData
    self:InitBtns()
    self:InitPanel()
end

function XUiSuperSmashBrosBattleResult:InitBtns()
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self.BtnRestart.CallBack = function() self:OnClickBtnRestart() end
end

function XUiSuperSmashBrosBattleResult:InitPanel()
    self.Mode = XDataCenter.SuperSmashBrosManager.GetPlayingMode()
    self.TxtWinNumber.text = self.Mode:GetWinCount() + 1
    local ownTeam = self.Mode:GetBattleTeam()
    local battleIndex = self.Mode:GetBattleCharaIndex() 
    local chara = XDataCenter.SuperSmashBrosManager.GetRoleById(ownTeam[battleIndex])
    local core = chara:GetCore()
    if core then
        self.TxtCoreName.text = core:GetName()
        self.RImgCoreIcon:SetRawImage(core:GetIcon())
    else
        self.TxtCoreName.text = ""
        self.RImgCoreIcon.gameObject:SetActiveEx(false)
    end
    self.TxtPassTime.text = XUiHelper.GetTime(self.Mode:GetLastStagePassTime(), XUiHelper.TimeFormatType.DEFAULT)
    self.TxtHpPercent.text = chara:GetHpLeft() .. "%"
end

function XUiSuperSmashBrosBattleResult:OnClickBtnConfirm()
    self:Close()
    CS.XFight.ExitForClient(true)
end

function XUiSuperSmashBrosBattleResult:OnClickBtnRestart()
    self:Close()
    CS.XFight.ExitForClient(true)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.Mode:GetNextStageId())
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
end