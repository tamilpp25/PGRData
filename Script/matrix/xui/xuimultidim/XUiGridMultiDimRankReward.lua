local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridMultiDimRankReward = XClass(nil, "XUiGridMultiDimRankReward")

function XUiGridMultiDimRankReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridReward.gameObject:SetActive(false)
    self.RewardGridList = {}
end

function XUiGridMultiDimRankReward:Refresh(config, rankNum, memberCount)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    
    if XTool.IsTableEmpty(rewards) then
        for i = 1, #self.RewardGridList do
            self.RewardGridList[i].GameObject:SetActiveEx(false)
        end
        return
    end
    
    for i = 1, #rewards do
        local panel = self.RewardGridList[i]
        if not panel then
            local go = XUiHelper.Instantiate(self.GridReward, self.PanelRewardContent)
            panel = XUiGridCommon.New(self.RootUi, go)
            table.insert(self.RewardGridList, panel)
        end
        panel:Refresh(rewards[i])
    end
    for i = #rewards + 1, #self.RewardGridList do
        self.RewardGridList[i].GameObject:SetActiveEx(false)
    end

    if config.MinRank <= 1 and config.MaxRank <= 1 then
        local min
        if config.MinRank > 0 then
            min = string.format("%s%%-", config.MinRank)
        else
            min = "≤"
        end
        local max = string.format("%s%%", config.MaxRank)
        self.TxtScore.text = string.format("%s%s", min, max)
    else
        self.TxtScore.text = string.format("%s%%-%s%%", config.MinRank, config.MaxRank)
    end

    -- 个人所占的百分比
    if rankNum > 0 then
        local percentCount, percent = XDataCenter.MultiDimManager.GetSingleRankFringe(rankNum, memberCount, true)
        local isShow = false
        if rankNum <= percentCount then
            isShow = percent >= config.MinRank and percent <= config.MaxRank
        else
            isShow = percent > config.MinRank and percent <= config.MaxRank
        end
        self.PanelCurRank.gameObject:SetActive(isShow)
    else
        self.PanelCurRank.gameObject:SetActive(false)
    end
end

return XUiGridMultiDimRankReward