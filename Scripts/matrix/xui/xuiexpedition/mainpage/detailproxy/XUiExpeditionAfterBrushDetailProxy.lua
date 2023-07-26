local BattleProxy = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpeditionBattleDetailProxy")
--复刷关卡详细代理
local XUiExpeditionAfterBrushDetailProxy = XClass(BattleProxy, "XUiExpeditionAfterBrushDetailProxy")

function XUiExpeditionAfterBrushDetailProxy:SetPanelReset()
    self.PanelBottom.PanelReset.gameObject:SetActiveEx(false)
end
--================
--初始化通关队伍面板
--================
function XUiExpeditionAfterBrushDetailProxy:InitPanelTeam()
    self.PanelBattle.PanelUsedTeam.gameObject:SetActiveEx(false)
end
--================
--初始化掉落列表
--================
function XUiExpeditionAfterBrushDetailProxy:InitPanelDrop()
    local isFirstPass = self.Ui.EStage:GetFirstPass()
    if not self.PanelDrop then
        self.PanelDrop = {}
        XTool.InitUiObjectByUi(self.PanelDrop, self.PanelBattle.PanelDropList)
    end
    self.PanelDrop.GridCommonDrop.gameObject:SetActiveEx(false)
    self.PanelDrop.TxtDrop.gameObject:SetActiveEx(false)
    self.PanelDrop.TxtFirstDrop.gameObject:SetActiveEx(false)
    self.PanelDrop.TxtRecruit.gameObject:SetActiveEx(true)
    if not isFirstPass then
        self.PanelDrop.TxtFirstDrop.gameObject:SetActiveEx(true)
        self.PanelDrop.TxtRecruit.text = self.Ui.EStage:GetDrawTimesRewardStr()
    else
        self.PanelDrop.TxtDrop.gameObject:SetActiveEx(true)
        self.PanelDrop.TxtRecruit.text = self.Ui.EStage:GetPassDrawTimesRewardStr()
    end
    self.PanelDrop.ImgEmpty.gameObject:SetActiveEx(false)
    self.PanelDrop.GameObject:SetActiveEx(true)
end

return XUiExpeditionAfterBrushDetailProxy