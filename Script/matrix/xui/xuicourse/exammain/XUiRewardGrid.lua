local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiRewardGrid = XClass(nil, "XUiRewardGrid")

function XUiRewardGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    -- self.UiGridCommon = XUiGridCommon.New(rootUi, self.GridCommon)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, handler(self, self.OnBtnClicked))
end

function XUiRewardGrid:SetData(chapterId)
    self.ChapterId = chapterId
    local isAllDraw = XDataCenter.CourseManager.CheckRewardAllDraw(chapterId)
    local isCanDraw = XDataCenter.CourseManager.CheckRewardAllCanDraw(chapterId)
    -- 奖励名
    self.TxtNumber.text = XCourseConfig.GetCourseChapterShortName(chapterId)
    -- 是否已领取
    self.ImgRe.gameObject:SetActiveEx(isAllDraw)
    -- 是否可领取图标
    self.ImgActive.gameObject:SetActiveEx(isCanDraw)
    self.ImgNotActive.gameObject:SetActiveEx(not isCanDraw)
    -- 物品信息
    -- local rewardId = XCourseConfig.GetRewardId(courseRewardId)
    -- self.UiGridCommon:Refresh(rewardId)
    self.RImgicon:SetRawImage(XCourseConfig.GetExamChapterGridShowRewardIcon(chapterId))
end

function XUiRewardGrid:OnBtnClicked()
    local rewardId = XCourseConfig.GetExamChapterGridShowReward(self.ChapterId)
    --local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(self.ChapterId)
    --local courseRewardIdList = XRewardManager.GetRewardList(rewardId)
    local title = XUiHelper.GetText("RewardPreview")
    local preTitle = XCourseConfig.GetCourseChapterName(self.ChapterId)
    XUiManager.OpenUiTipRewardByRewardId(rewardId, preTitle .. " " .. title, nil, nil, nil, XUiHelper.GetText("Award"))
end

return XUiRewardGrid