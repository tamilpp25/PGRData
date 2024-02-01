local XUiGridRiftJumpRes = XClass(nil, "XUiGridRiftJumpRes")

function XUiGridRiftJumpRes:Ctor(ui, xFightLayer, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.XFightLayer = xFightLayer
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridRewardList = {}
    self:Refresh()
end

function XUiGridRiftJumpRes:Refresh()
    if not self.XFightLayer then
        return -- GM导致
    end

    self.TxtDepth.text = self.XFightLayer:GetId().."km"

    local rewardId = self.XFightLayer:GetConfig().RewardId
    if rewardId > 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        for i, item in ipairs(rewards) do
            local grid = self.GridRewardList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid256, self.Grid256.parent)
                grid = XUiGridCommon.New(self.RootUi, ui)
                self.GridRewardList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
end

return XUiGridRiftJumpRes
