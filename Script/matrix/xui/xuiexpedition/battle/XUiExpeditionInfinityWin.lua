-- 虚像地平线无尽关胜利结算界面
local XUiExpeditionInfinityWin = XLuaUiManager.Register(XLuaUi, "UiExpeditionInfinityWin")

function XUiExpeditionInfinityWin:OnAwake()
    XTool.InitUiObject(self)
    self:InitPanel()
    self:RegisterBtns()
end

function XUiExpeditionInfinityWin:InitPanel()
    self.GridWinRole.gameObject:SetActive(false)
    self.GridCombo.gameObject:SetActive(false)
    self.PanelNewRecord.gameObject:SetActive(false)
end

function XUiExpeditionInfinityWin:RegisterBtns()
    self.BtnExitFight.CallBack = function() self:OnBtnExitClick() end
    self.BtnReFight.CallBack = function() self:OnBtnReFightClick() end
end

function XUiExpeditionInfinityWin:OnBtnExitClick()
    if XDataCenter.ExpeditionManager.GetIfBackMain() then
        if self.Timer then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        self:StopAudio()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    else
        self:StopAudio()
        self:Close()
    end
end

function XUiExpeditionInfinityWin:OnBtnReFightClick()
    if XDataCenter.ExpeditionManager.GetIfBackMain() then
        if self.Timer then
            XScheduleManager.UnSchedule(self.Timer)
            self.Timer = nil
        end
        self:StopAudio()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
    else
        self:StopAudio()
        self:Close()
        XLuaUiManager.Open("UiBattleRoleRoom", self.EStage:GetStageId())
    end
end

function XUiExpeditionInfinityWin:OnStart(data)
    self.WinData = data.SettleData.ExpeditionFightResult
    self.EStage = XDataCenter.ExpeditionManager.GetEStageByStageId(data.StageId)
    self.HistoryWave = XDataCenter.ExpeditionManager.GetWave(data.StageId)
    local newWave = self.WinData.NpcGroup > 0 and self.WinData.NpcGroup or 0
    if self.HistoryWave < newWave then XDataCenter.ExpeditionManager.SetWave(data.StageId, self.WinData.NpcGroup) end
    self.CurrentStageId = data.StageId
    self.IsFirst = true
    self:InitInfo()
    XLuaUiManager.SetMask(true)
end

function XUiExpeditionInfinityWin:InitInfo()
    self:InitStageNameAndTime()
    self:InitRolePanel()
    self:InitComboPanel()
    self:ShowWave()
end

function XUiExpeditionInfinityWin:InitStageNameAndTime()
    self.TxtStageName.text = self.EStage:GetStageName()
    self.TxtCostTime.text = self.WinData.UseTime or "-"
end

function XUiExpeditionInfinityWin:InitRolePanel()
    local team = XDataCenter.ExpeditionManager.GetTeam():GetBattleTeam()
    local XHeadIcon = require("XUi/XUiExpedition/Battle/XUiExpeditionInfinityHeadIcon")
    for _, member in pairs(team) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridWinRole.gameObject)
        prefab.transform:SetParent(self.PanelRoleContent.transform, false)
        local headIcon = XHeadIcon.New(prefab)
        headIcon:RefreshData(member)
        prefab.gameObject:SetActiveEx(true)
    end
end

function XUiExpeditionInfinityWin:InitComboPanel()
    local XComboList = require("XUi/XUiExpedition/Battle/XUiExpeditionInfinityComboList")
    self.ComboList = XComboList.New(self.DyanamicTableCombo)
    self.ComboList:RefreshData()
end

function XUiExpeditionInfinityWin:ShowWave()
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    local newWave = self.WinData.NpcGroup > 0 and self.WinData.NpcGroup or 0
    XUiHelper.Tween(time, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end

            -- 通关时间
            local costTime = XUiHelper.GetTime(math.floor(f * self.WinData.UseTime), XUiHelper.TimeFormatType.SHOP)
            self.TxtCostTime.text = costTime

            -- 当前波数
            local wave = math.floor(f * newWave)
            self.TxtCurrentWave.text = wave

            -- 历史最高分
            local highScore = math.floor(f * self.HistoryWave)
            self.TxtHistoryWave.text = highScore
        end, function()
            self:StopAudio()
            self.PanelNewRecord.gameObject:SetActiveEx(newWave > self.HistoryWave)
            XLuaUiManager.SetMask(false)
        end)
end

function XUiExpeditionInfinityWin:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end