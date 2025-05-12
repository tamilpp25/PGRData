local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local handler = handler
local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridDailyReward = XClass(nil, "XUiGridDailyReward")

function XUiGridDailyReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.GridCommon.gameObject:SetActiveEx(false)

    self.RewardGrids = {}
end

function XUiGridDailyReward:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridDailyReward:RefreshCommon(id)
    local star = XKillZoneConfigs.GetDailyStarRewardStar(id)
    self.TxtStarNum1.text = "x" .. star

    local rewardGoodsId = XKillZoneConfigs.GetDailyStarRewardGoodsId(id)
    local rewards = XRewardManager.GetRewardList(rewardGoodsId) or {}
    for index, reward in ipairs(rewards or {}) do
        local grid = self.RewardGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCommon or CSUnityEngineObjectInstantiate(self.GridCommon, self.Layout)
            grid = XUiGridCommon.New(self.RootUi, ui)
            self.RewardGrids[index] = grid
        end

        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rewards + 1, #self.RewardGrids do
        local grid = self.RewardGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridDailyReward:Refresh(id)
    local curStar = XDataCenter.KillZoneManager.GetYesterdayStar()
    local targetStar = XKillZoneConfigs.GetDailyStarRewardStar(id)

    for index = 1, 3 do
        self["TxtStarNum" .. index].text = "x" .. targetStar
    end

    self.PanelDisable.gameObject:SetActiveEx(curStar < targetStar)
    self.PanelCur.gameObject:SetActiveEx(curStar == targetStar)
    self.PanelNormal.gameObject:SetActiveEx(curStar > targetStar)

    self:RefreshCommon(id)
end

return XUiGridDailyReward