local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridNewYearLuckReward = XClass(nil,"XUiGridNewYearLuckReward")

---@param obj UnityEngine.RectTransform
---@param config XTable.XTableNewYearLuckLevel
function XUiGridNewYearLuckReward:Ctor(obj,config,parentUi)
    self.GameObject = obj
    self.Transform = obj.transform
    self.Config = config
    self.ParentUi = parentUi
    XTool.InitUiObject(self)
    self:Refresh()
end

function XUiGridNewYearLuckReward:Refresh()
    self.TxtLv.text = self.Config.RewardLevel
    self.TxtLuckNumProbability.text = self.Config.ProbabilityOfWinning
    local isDraw = XDataCenter.NewYearLuckManager.IsCanReward()
    self.TxtLuckNum.gameObject:SetActiveEx(isDraw)
    self.TxtLuckNumLock.gameObject:SetActiveEx(not isDraw)
    local textNum = ""
    for i,num in pairs(self.Config.LuckNums) do
        if i == #self.Config.LuckNums then
            textNum = textNum..num
        else
            textNum = textNum..num.."、"
        end
    end
    self.TxtLuckNum.text = textNum
    local rewardList =  XRewardManager.GetRewardList(self.Config.RewardId)
    if not rewardList then
        return
    end
    if not self.GridCommon then
        self.GridCommon = XUiGridCommon.New(self.ParentUi,self.Grid256New)
    end
    self.GridCommon:Refresh(rewardList[1])
end

return XUiGridNewYearLuckReward