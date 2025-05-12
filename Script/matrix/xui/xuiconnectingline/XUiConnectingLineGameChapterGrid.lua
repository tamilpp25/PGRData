local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiConnectingLineGameChapterGrid : XUiNode
---@field _Control XConnectingLineControl
local XUiConnectingLineGameChapterGrid = XClass(XUiNode, "XUiConnectingLineGameChapterGrid")

function XUiConnectingLineGameChapterGrid:OnStart()
    self._Data = false
    ---@type XUiGridCommon
    self._Reward = XUiGridCommon.New(self.RootUi, self.GridReward)
    self._RewardList = { self._Reward }
    XUiHelper.RegisterClickEvent(self, self.Button, self._OnClick)
end

---@param data XConnectingLineStageData
function XUiConnectingLineGameChapterGrid:Update(data)
    self._Data = data
    self.Text.text = data.Name
    for i = 1, #data.Reward do
        local gridCommon = self._RewardList[i]
        if not gridCommon then
            local uiReward = CS.UnityEngine.Object.Instantiate(self.GridReward.gameObject, self.GridReward.transform.parent)
            gridCommon = XUiGridCommon.New(uiReward)
            self._RewardList[#self._RewardList + 1] = gridCommon
        end
        gridCommon:Refresh(data.Reward[i])
        gridCommon.GameObject:SetActiveEx(true)
        gridCommon:SetName("")
        gridCommon:SetReceived(data.IsPassed)
    end
    for i = #data.Reward + 1, #self._RewardList do
        local gridCommon = self._RewardList[i]
        gridCommon.GameObject:SetActiveEx(false)
    end
    if self.TextCost and self.RawImage2 then
        if (data.CostItemNum == 0) or (not self._Control:GetUiData().IconMoney) then
            self.TextCost.gameObject:SetActiveEx(false)
            self.RawImage2.gameObject:SetActiveEx(false)
        else
            self.TextCost.text = data.CostItemNum
            self.RawImage2:SetRawImage(self._Control:GetUiData().IconMoney)
        end
    end
    if data.IsPassed then
        self.CG:SetRawImage(data.CG)
        self.Passed.gameObject:SetActiveEx(true)
        self.Start.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(false)
    else
        self.Passed.gameObject:SetActiveEx(false)
        if data.IsUnlock then
            self.Start.gameObject:SetActiveEx(true)
            self.Lock.gameObject:SetActiveEx(false)
            ---@type UnityEngine.RectTransform
            local transform = self.Transform
            transform:SetSiblingIndex(transform.parent.childCount)
        else
            self.Start.gameObject:SetActiveEx(false)
            self.Lock.gameObject:SetActiveEx(true)

        end
    end
end

function XUiConnectingLineGameChapterGrid:_OnClick()
    self._Control:OnClickStage(self._Data.StageId)
end

return XUiConnectingLineGameChapterGrid