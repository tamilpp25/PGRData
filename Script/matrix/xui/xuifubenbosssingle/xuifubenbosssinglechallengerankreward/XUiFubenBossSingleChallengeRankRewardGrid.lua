---@class XUiFubenBossSingleChallengeRankRewardGrid : XUiNode
---@field TxtScore UnityEngine.UI.Text
---@field PanelCurRank UnityEngine.RectTransform
---@field PanelRewardContent UnityEngine.RectTransform
---@field GridReward UnityEngine.RectTransform
local XUiFubenBossSingleChallengeRankRewardGrid = XClass(XUiNode, "XUiFubenBossSingleChallengeRankRewardGrid")

function XUiFubenBossSingleChallengeRankRewardGrid:OnStart()
    self._GridRewardList = {}
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleChallengeRankRewardGrid:Refresh(config, isSelfRank)
    if not config or not XTool.IsNumberValid(config.MailID) then
        self:Close()
        return
    end
    
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local rewardList = mailAgency:GetRewardList(config.MailID)

    for i = 1, #rewardList do
        local grid = self._GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.Parent, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self._GridRewardList[i] = grid
        end

        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardList + 1, #self._GridRewardList do
        self._GridRewardList[i].GameObject:SetActiveEx(false)
    end

    if config.MinRank <= 1 and config.MaxRank <= 1 then
        local min = nil
        local max = XMath.ToInt(config.MaxRank * 100) .. "%"
        
        if config.MinRank > 0 then
            min = XMath.ToInt(config.MinRank * 100) .. "%" .. "-"
        else
            min = ""
        end

        self.TxtScore.text = min .. max
    else
        if config.MinRank == config.MaxRank then
            self.TxtScore.text = config.MinRank
        else
            self.TxtScore.text = config.MinRank .. "-" .. config.MaxRank
        end
    end

    if self.PanelCurRank then
        self.PanelCurRank.gameObject:SetActiveEx(isSelfRank)
    end
end

return XUiFubenBossSingleChallengeRankRewardGrid
