--各个关卡页面的rank组件
local XUiGuildBossStageRankItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossStageRankItem")
local XUiGuildBossRankPanel = XClass(nil, "XUiGuildBossRankPanel")

function XUiGuildBossRankPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnRank.CallBack = function() self:OnBtnRankClick() end
    self.RankList = {}
    self.RankNum = 3
end

function XUiGuildBossRankPanel:Init(stageId)
    self.StageId = stageId
    self.Data = XDataCenter.GuildBossManager.GetDetailLevelData(stageId)
    for i = 1, self.RankNum do
        if i <= #self.Data.TopPlayers then
            if self.RankList[i] == nil then
                self.RankList[i] = XUiGuildBossStageRankItem.New(self["RankItem" .. i])
            end
            self["RankItem" .. i].gameObject:SetActiveEx(true)
            self.RankList[i]:Init(self.Data.TopPlayers[i], i)
        else
            self["RankItem" .. i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiGuildBossRankPanel:OnBtnRankClick()
    XLuaUiManager.Open("UiGuildBossRank", self.StageId)
end

return XUiGuildBossRankPanel