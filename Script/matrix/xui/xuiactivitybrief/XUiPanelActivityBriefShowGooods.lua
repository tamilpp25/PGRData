local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelActivityBriefShowGoods
local XUiPanelActivityBriefShowGoods = XClass(nil, 'XUiPanelActivityBriefShowGoods')

function XUiPanelActivityBriefShowGoods:Ctor(ui, activityRewardId)
    XTool.InitUiObjectByUi(self, ui)
    self._ActivityRewardId = activityRewardId
    self:InitShowGoods()
end

function XUiPanelActivityBriefShowGoods:Open()
    self:PlayAnimation('PanelRewardEnable')
end

function XUiPanelActivityBriefShowGoods:PlayAnimation(animeName, finCb, beginCb)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    local animRoot = self.Transform:Find("Animation")
    if XTool.UObjIsNil(animRoot) then
        return
    end

    local animTrans = animRoot:FindTransform(animeName)
    if not animTrans or not animTrans.gameObject.activeInHierarchy then
        return
    end
    if beginCb then
        beginCb()
    end
    animTrans:PlayTimelineAnimation(finCb)
end

function XUiPanelActivityBriefShowGoods:InitShowGoods()
    self.GridReward.gameObject:SetActiveEx(false)
    --通用处理
    if XTool.IsNumberValid(self._ActivityRewardId) then
        local showItems = XRewardManager.GetRewardListNotCount(self._ActivityRewardId)
        XUiHelper.RefreshCustomizedList(self.GridReward.transform.parent, self.GridReward, showItems and #showItems or 0, function(index, obj)
            local gridCommont = XUiGridCommon.New(nil, obj)
            gridCommont:Refresh(showItems[index])
        end)
    end
end

return XUiPanelActivityBriefShowGoods