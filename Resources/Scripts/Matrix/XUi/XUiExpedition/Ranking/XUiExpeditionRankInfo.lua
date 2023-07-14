-- 虚像地平线排行榜控件
local XUiExpeditionRankInfo = XClass(nil, "XUiExpeditionRankInfo")
local XUiPanelMyRank = require("XUi/XUiExpedition/Ranking/XUiExpeditionMyRank")
local XUiRankGrid = require("XUi/XUiExpedition/Ranking/XUiExpeditionRankGrid")
local XUiRankList = require("XUi/XUiExpedition/Ranking/XUiExpeditionRankList")
function XUiExpeditionRankInfo:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self:InitPanel()
end

function XUiExpeditionRankInfo:InitPanel()
    self.GridRank.gameObject:SetActive(false)
    self.TxtCurTime.text = CS.XTextManager.GetText("ExpeditionResetCountDown", "-")
    self.TxtIos.gameObject:SetActive(false)
    self.TxtAndroid.gameObject:SetActive(false)
    self.MyRank = XUiPanelMyRank.New(self.PanelMyRank, self.RootUi)
    self.TopRankingList = XUiRankList.New(self.PlayerRankList, self.RootUi, self)
end

function XUiExpeditionRankInfo:RefreshRankData()
    self.TopRankingList:UpdateData()
    self.MyRank:Refresh()
end

function XUiExpeditionRankInfo:RefreshCountDown(time)
    if self.TxtCurTime then self.TxtCurTime.text = CS.XTextManager.GetText("ExpeditionResetCountDown", time) end
end

return XUiExpeditionRankInfo