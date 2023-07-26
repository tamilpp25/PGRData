local XUiPanelMultiDimRoomReward = XClass(nil, "XUiPanelMultiDimRoomReward")

---@param transform UnityEngine.RectTransform
function XUiPanelMultiDimRoomReward:Ctor(transform,parentUi)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.ParentUi = parentUi
    self.GridList = {}
    XTool.InitUiObject(self)
end

function XUiPanelMultiDimRoomReward:Refresh(stageId)
    local difficultyCfg = XMultiDimConfig.GetMultiDimDifficultyStageData(stageId)
    local rewards = XRewardManager.GetRewardList(difficultyCfg.DifficultyFirstPassReward)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid256New,self.Transform)
                grid = XUiGridCommon.New(self.ParentUi, ui)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
    self.Grid256New.gameObject:SetActiveEx(false)
end

function XUiPanelMultiDimRoomReward:SetActive(isShow)
    self.GameObject:SetActiveEx(isShow)
end

return XUiPanelMultiDimRoomReward