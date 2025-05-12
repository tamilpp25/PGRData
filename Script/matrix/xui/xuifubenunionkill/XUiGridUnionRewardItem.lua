local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridUnionRewardItem = XClass(nil, "XUiGridUnionRewardItem")

function XUiGridUnionRewardItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    self.MailRewardList = {}
    XTool.InitUiObject(self)
    self.BtnReceive.gameObject:SetActiveEx(false)
end

function XUiGridUnionRewardItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 刷新排名奖励
function XUiGridUnionRewardItem:Refresh(rewardInfo, rankLevel)
    local minRank = rewardInfo.MinRank * 100
    local maxRank = rewardInfo.MaxRank * 100
    if minRank <= 0 then
        self.TxtScore.text = string.format("%d%%", maxRank)
    else
        self.TxtScore.text = string.format("%d%%-%d%%", minRank, maxRank)
    end

    local killRankInfos = XDataCenter.FubenUnionKillManager.GetKillRankInfosByLevel(rankLevel)
    if not killRankInfos then return end
    local _, curRank, totalRank = killRankInfos.Score, killRankInfos.Rank, killRankInfos.TotalRank

    local playerRank = 0
    if totalRank ~= 0 then
        playerRank = (curRank * 1.0) / totalRank * 100
    end
    self.PanelCurRank.gameObject:SetActiveEx(playerRank > minRank and playerRank <= maxRank)

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local rewardList = mailAgency:GetRewardList(rewardInfo.MailId)

    for i, reward in pairs(rewardList or {}) do
        if not self.MailRewardList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            ui.transform:SetParent(self.PanelRewardContent, false)
            local common = XUiGridCommon.New(self.UiRoot, ui)
            self.MailRewardList[i] = common
        end

        self.MailRewardList[i]:Refresh(reward)
    end
    for i = #rewardList + 1, #self.MailRewardList do
        self.MailRewardList[i].GameObject:SetActiveEx(false)
    end
end


return XUiGridUnionRewardItem