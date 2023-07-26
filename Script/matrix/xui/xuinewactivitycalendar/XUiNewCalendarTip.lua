---@class XUiNewCalendarTip : XLuaUi
local XUiNewCalendarTip = XLuaUiManager.Register(XLuaUi, "UiNewCalendarTip")

function XUiNewCalendarTip:OnAwake()
    self:RegisterUiEvents()
    self.GridRewardList = {}
end

function XUiNewCalendarTip:OnStart(activityId)
    self.ActivityId = activityId
    self.ActivityEntity = XDataCenter.NewActivityCalendarManager.GetActivityEntity(activityId)
    for i = 1, 3 do
        self["GridReward" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiNewCalendarTip:OnEnable()
    self:RefreshText()
    self:RefreshReward()
end

function XUiNewCalendarTip:RefreshText()
    self.TxtActivityName.text = self.ActivityEntity:GetName()
    local desc = self.ActivityEntity:GetDescription()
    self.TxtWorldDesc.text = XUiHelper.ConvertLineBreakSymbol(desc)
end

function XUiNewCalendarTip:RefreshReward()
    self.GridRewardList = self.GridRewardList or {}
    local rewards = XDataCenter.NewActivityCalendarManager.GetRewardItemData(self.ActivityId, true)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.Content)
            grid = XUiGridCommon.New(self, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewards[i].TemplateId)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end
end

function XUiNewCalendarTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick)
end

function XUiNewCalendarTip:OnBtnBackClick()
    self:Close()
end

function XUiNewCalendarTip:OnBtnGoClick()
    if not self.ActivityEntity then
        return
    end
    if self.ActivityEntity:CheckActivityNotOpen() then
        XUiManager.TipText("CommonActivityNotStart")
        return
    end
    if self.ActivityEntity:CheckActivityEnd() then
        XUiManager.TipText("CommonActivityEnd")
        return
    end
    local skipId = self.ActivityEntity:GetSkipId()
    if XTool.IsNumberValid(skipId) then
        XFunctionManager.SkipInterface(skipId)
    end
end

return XUiNewCalendarTip