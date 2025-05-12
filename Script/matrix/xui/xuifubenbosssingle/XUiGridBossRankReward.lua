local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridBossRankReward : XUiNode
local XUiGridBossRankReward = XClass(XUiNode, "XUiGridBossRankReward")

function XUiGridBossRankReward:OnStart(rootUi)
    self._RootUi = rootUi
    self._GridRewardList = {}
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiGridBossRankReward:Refresh(cfg, isShowCurTag, clickCallback)
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local rewardList = mailAgency:GetRewardList(cfg.MailID)

    for i = 1, #rewardList do
        local grid = self._GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self._RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self._GridRewardList[i] = grid
        end

        grid:SetProxyClickFunc(clickCallback)
        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardList + 1, #self._GridRewardList do
        self._GridRewardList[i].GameObject:SetActiveEx(false)
    end

    if cfg.MinRank <= 1 and cfg.MaxRank <= 1 then
        local min
        if cfg.MinRank > 0 then
            min = XMath.ToInt(cfg.MinRank * 100) .. "%" .. "-"
        else
            min = ""
        end
        local max = XMath.ToInt(cfg.MaxRank * 100) .. "%"

        self.TxtScore.text = min .. max
    else
        if cfg.MinRank == cfg.MaxRank then
            self.TxtScore.text = cfg.MinRank
        else
            self.TxtScore.text = cfg.MinRank .. "-" .. cfg.MaxRank
        end
    end

    if self.PanelCurRank then
        self.PanelCurRank.gameObject:SetActiveEx(isShowCurTag)
    end
end

return XUiGridBossRankReward
