local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--奖励预览弹窗
local XUiCourseObtain = XLuaUiManager.Register(XLuaUi,"UiCourseObtain")

function XUiCourseObtain:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
end

-- @bigTitleTxt 大字标题文本
-- @smallTitleTxt 小字标题文本
function XUiCourseObtain:OnStart(stageId, bigTitleTxt, smallTitleTxt)
    self.StageId = stageId
    self.RewardId = XFubenConfigs.GetFirstRewardShow(stageId)
    self.BigTitleTxt = bigTitleTxt
    self.SmallTitleTxt = smallTitleTxt
    self.RewardIdGrids = {}
end

function XUiCourseObtain:OnEnable()
    self:RefreshTitle()
    self:RefreshReward()
end

function XUiCourseObtain:RefreshTitle()
    if not string.IsNilOrEmpty(self.BigTitleTxt) then
        self.BigWordTitle.text = self.BigTitleTxt
    end
    if not string.IsNilOrEmpty(self.SmallTitleTxt) then
        self.SmallWordTitle.text = self.SmallTitleTxt
    end
end

function XUiCourseObtain:RefreshReward()
    if not XTool.IsNumberValid(self.RewardId) then
        self.GridCommon.gameObject:SetActive(false)
        return
    end
    local RewordGoodList = XRewardManager.GetRewardList(self.RewardId)
    for i, rewardGood in ipairs(RewordGoodList) do
        local rewardGoodUi = self.RewardIdGrids[i]
        if not rewardGoodUi then
            rewardGoodUi = XUiGridCommon.New(XUiHelper.Instantiate(self.GridCommon, self.PanelContent))
            self.RewardIdGrids[i] = rewardGoodUi
        end
        rewardGoodUi:Refresh(rewardGood)
        rewardGoodUi.PanelRecive.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckStageIsComplete(self.StageId))
    end
    self.GridCommon.gameObject:SetActive(false)
end