local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--战斗执照-执照奖励弹窗
local XUiCourseLiveWell = XLuaUiManager.Register(XLuaUi, "UiCourseLiveWell")

function XUiCourseLiveWell:OnAwake()
    self:RegisterButtonEvent()
end

function XUiCourseLiveWell:OnStart(chapterId, closeCb)
    self.CloseCb = closeCb

    local courseRewardId = XCourseConfig.GetRewardIdByChapterId(chapterId)
    self.TxtDesc.text = XCourseConfig.GetRewardClearTipsTitle(courseRewardId)

    --奖励格子
    local rewardId = XCourseConfig.GetRewardId(courseRewardId)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local gridCommon = XUiGridCommon.New(self, self.GridCommon)
    gridCommon:Refresh(rewardList[1])
    -- local grid
    -- XUiHelper.RefreshCustomizedList(self.Container, self.GridRole, #rewardList
    -- , function(index, go)
    --     gridCommon = XUiHelper.TryGetComponent(go.transform, "GridCommon")
    --     grid = XUiGridCommon.New(self, gridCommon)
    --     grid:Refresh(rewardList[index])
    -- end)
end

function XUiCourseLiveWell:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiCourseLiveWell:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end