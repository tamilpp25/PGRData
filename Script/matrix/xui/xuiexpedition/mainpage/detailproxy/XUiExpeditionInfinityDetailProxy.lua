local BattleProxy = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionBattleDetailProxy")
--无尽关卡详细代理
local XUiExpeditionInfinityDetailProxy = XClass(BattleProxy, "XUiExpeditionInfinityDetailProxy")
--================
--初始化掉落列表
--================
function XUiExpeditionInfinityDetailProxy:InitPanelDrop()
    self.PanelBattle.PanelDropList.gameObject:SetActiveEx(false)
end
function XUiExpeditionInfinityDetailProxy:SetPanelReset()
    self.PanelBottom.PanelReset.gameObject:SetActiveEx(false)
end

--================
--初始化通关队伍面板
--================
function XUiExpeditionInfinityDetailProxy:InitPanelTeam()
    if not self.PanelTeam then
        self.PanelTeam = {}
        XTool.InitUiObjectByUi(self.PanelTeam, self.PanelBattle.PanelUsedTeam)
    end
    local teamDatas = self.Ui.EStage:GetPassTeamData()
    self.PanelTeam.ImgEmpty.gameObject:SetActiveEx(#teamDatas <= 0)
    self.PanelTeam.Txt02.gameObject:SetActiveEx(#teamDatas > 0)
    self.PanelTeam.TxtRecord.text = XDataCenter.ExpeditionManager.GetWave(self.Ui.EStage:GetStageId())
    self.PanelTeam.GridMember.gameObject:SetActiveEx(false)
    self:CreateTeamListByTeamDatas(teamDatas)
    self.PanelTeam.GameObject:SetActiveEx(true)
end

return XUiExpeditionInfinityDetailProxy