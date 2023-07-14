-- XUiBiancaTheatrePreviewTips 肉鸽2.1 成就奖励提示弹窗
-- ===================================================================
local XGridAchievementReward = XClass(nil, "XGridAchievementReward")

function XGridAchievementReward:Ctor(ui, rootUi, rewardId, needCount)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    self.RewardId = rewardId
    self.NeedCount = needCount
end

function XGridAchievementReward:Refresh()
    self.TxtNum.text = self.NeedCount
    local rewardItems = XRewardManager.GetRewardList(self.RewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    local gridCommon = XUiGridCommon.New(self.RootUi, self.GridReward)
    gridCommon:Refresh(rewardGoodsList[1])
    if gridCommon.BtnClick then
        XUiHelper.RegisterClickEvent(gridCommon, gridCommon.BtnClick, function ()
            self:OnClickReward()
        end)
    end
end

function XGridAchievementReward:OnClickReward()
    if not XTool.IsNumberValid(self.RewardId) then
        return
    end
    local rewardList = XRewardManager.GetRewardList(self.RewardId)
    XLuaUiManager.Open("UiBiancaTheatreTips", rewardList[1].TemplateId)
end


-- XUiBiancaTheatrePreviewTips 肉鸽2.1 成就奖励提示弹窗
-- ===================================================================
local XUiBiancaTheatrePreviewTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatrePreviewTips")

function XUiBiancaTheatrePreviewTips:OnAwake()
    self.GridRewards = {}
    self:AddClickListener()
end

function XUiBiancaTheatrePreviewTips:OnStart(achievementId)
    self.NeedCounts = XDataCenter.BiancaTheatreManager.GetAchievementNeedCounts()
    self.RewardIdList = XDataCenter.BiancaTheatreManager.GetAchievementRewardIds()
end

function XUiBiancaTheatrePreviewTips:OnEnable()
    self:RefreshReward()
end

function XUiBiancaTheatrePreviewTips:RefreshReward()
    self.GridPreview.gameObject:SetActiveEx(false)
    if XTool.IsTableEmpty(self.NeedCounts) then
        return
    end
    for index, value in ipairs(self.NeedCounts) do
        if not self.GridRewards[index] then
            self.GridRewards[index] = 
                XGridAchievementReward.New(XUiHelper.Instantiate(self.GridPreview, self.PanelList), self, self.RewardIdList[index], value)
        end
        self.GridRewards[index]:Refresh()
        self.GridRewards[index].GameObject:SetActiveEx(true)
    end
end

function XUiBiancaTheatrePreviewTips:AddClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnOk, self.Close)
end

return XUiBiancaTheatrePreviewTips
