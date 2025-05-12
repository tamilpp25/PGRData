local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridStageReward = XClass(nil, "XUiGridStageReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
function XUiGridStageReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Grid256.gameObject:SetActiveEx(false)
    self.GridRewardList = {}
end

function XUiGridStageReward:UpdateGrid(root, rewardId, index, sTStage)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in pairs(rewards) do
            local grid = self.GridRewardList[i]
            if not grid then
                local ui = CSObjectInstantiate(self.Grid256,self.PanelRewardList)
                grid = XUiGridCommon.New(root, ui)
                self.GridRewardList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
        
        for i = #rewards + 1, #self.GridRewardList do
            self.GridRewardList[i].GameObject:SetActiveEx(false)
        end
    end
    
    local formatStr = index > 9 and "%d" or "0%d"
    self.TxtNumber.text = string.format(formatStr, index)
    
    local IsSingleTeam = sTStage:CheckIsSingleTeamMultiWave()
    local titleStr = IsSingleTeam and CSTextManagerGetText("STMultiWaveRewardTitle") or CSTextManagerGetText("STMultiTeamRewardTitle")
    self.TxtName.text = CSTextManagerGetText("STRewardText", titleStr)
    
    self.PanelClear.gameObject:SetActiveEx(sTStage:GetCurrentProgress() >= index)
end

return XUiGridStageReward