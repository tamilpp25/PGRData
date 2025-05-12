local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local RewardStatus = XGuildWarConfig.RewardStatus

---@class XUiGuildWarLzTaskGrid
local XUiGuildWarLzTaskGrid = XClass(nil, "XUiGuildWarLzTaskGrid")

function XUiGuildWarLzTaskGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self._GridList = {}
    ---@type XUiGuildWarLzTaskGridData
    self._Data = false
    self.IsAnimation = false

    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnClickReceive)
    self.GridCommon.gameObject:SetActiveEx(false)

    self.Bg = self.Bg or XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/Bg", "RectTransform")
    self.Bg2 = self.Bg2 or XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/Bg2", "RectTransform")
end

---@param data XUiGuildWarLzTaskGridData
function XUiGuildWarLzTaskGrid:Update(data)
    self._Data = data
    local rewardList = data.RewardGoodList
    XUiHelper.CreateTemplates(nil, self._GridList, rewardList, XUiGridCommon.New, self.GridCommon, self.GridCommon.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
    if data.Status == RewardStatus.Incomplete then
        self.BtnSkip.gameObject:SetActiveEx(true)
        self.BtnFinish.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.Bg.gameObject:SetActiveEx(true)
        self.Bg2.gameObject:SetActiveEx(false)

    elseif data.Status == RewardStatus.Complete then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(true)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.Bg.gameObject:SetActiveEx(true)
        self.Bg2.gameObject:SetActiveEx(false)

    elseif data.Status == RewardStatus.Received then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(true)
        self.Bg.gameObject:SetActiveEx(false)
        self.Bg2.gameObject:SetActiveEx(true)
    end

    self.TxtTaskName.text = data.Name
end

function XUiGuildWarLzTaskGrid:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskTimeline:PlayTimelineAnimation()
end

function XUiGuildWarLzTaskGrid:OnClickReceive()
    if self._Data then
        XDataCenter.GuildWarManager.RequestReceiveBossReward(self._Data.Id, self._Data.ParentUid)
    end
end

return XUiGuildWarLzTaskGrid
