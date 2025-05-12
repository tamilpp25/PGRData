local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridSettleReward = XClass(nil, "XUiGridSettleReward")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridSettleReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridRewardList = {}
end

function XUiGridSettleReward:UpdateGrid(root, rewardId, index, rewardState, sTStage)
    local panel
    
    if self.PanelComplete then
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
    if self.PanelGet then
        self.PanelGet.gameObject:SetActiveEx(false)
    end
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    
    if rewardState == XDataCenter.SuperTowerManager.StageRewardState.Complete then
        panel = self.PanelComplete
    elseif rewardState == XDataCenter.SuperTowerManager.StageRewardState.CanGet then
        panel = self.PanelGet
    elseif rewardState == XDataCenter.SuperTowerManager.StageRewardState.Lock then
        panel = self.PanelLock
    end

    self:UpdatePanelReward(root, rewardId, index, sTStage, panel)
end

function XUiGridSettleReward:UpdatePanelReward(root, rewardId, index, sTStage, panel)
    local rewards = XRewardManager.GetRewardList(rewardId)
    local gridObj = panel:GetObject("Grid256New")
    local parentObj = panel:GetObject("Content")
    
    panel.gameObject:SetActiveEx(true)
    gridObj.gameObject:SetActiveEx(false)
    if rewards then
        for i, item in pairs(rewards) do
            local grid = self.GridRewardList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(gridObj)
                grid = XUiGridCommon.New(root, ui)
                self.GridRewardList[i] = grid
            end
            grid:Refresh(item)
            grid.Transform:SetParent(parentObj, false)
            grid.GameObject:SetActiveEx(true)
        end

        for i = #rewards + 1, #self.GridRewardList do
            self.GridRewardList[i].GameObject:SetActiveEx(false)
        end
    end

    if sTStage:CheckIsMultiWave() then
        local IsSingleTeam = sTStage:CheckIsSingleTeamMultiWave()
        local txtNumObj = panel:GetObject("TxtNum")
        local txtNameObj = panel:GetObject("TxtName")
        local formatStr = index > 9 and "%d" or "0%d"
        txtNumObj.text = string.format(formatStr,index)
        txtNameObj.text = IsSingleTeam and CSTextManagerGetText("STMultiWaveRewardTitle") or CSTextManagerGetText("STMultiTeamRewardTitle")
    end
end

return XUiGridSettleReward