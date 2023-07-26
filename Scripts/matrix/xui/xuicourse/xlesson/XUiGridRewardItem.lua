local XUiGridRewardItem = XClass(nil, "XUiGridRewardItem")

function XUiGridRewardItem:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, self.Ui)
    
    self.BtnReceive.CallBack = function() self:OnBtnReceive() end
    self.RewardGoodUiTable = {}
end

function XUiGridRewardItem:RefreshUi(courseRewardId, chapterId)
    self.CourseRewardId = courseRewardId
    self.RewardId = XCourseConfig.GetRewardId(courseRewardId)
    self.Point = XCourseConfig.GetRewardPoint(courseRewardId)
    self.CurPoint = XDataCenter.CourseManager.GetChapterCurPoint(chapterId)
    self.IsDraw = XDataCenter.CourseManager.CheckRewardIsDraw(self.CourseRewardId)
    self.ChapterId = chapterId

    self:RefreshTxt()
    self:RefreshState()
    self:RefreshRewards()
end

-- 文本显示
function XUiGridRewardItem:RefreshTxt()
    self.TxtGradeStarNums.text = CS.XTextManager.GetText("Fract", math.min(self.CurPoint, self.Point), self.Point)
end

-- 领取状态
function XUiGridRewardItem:RefreshState()
    local reach = self.CurPoint >= self.Point
    self.BtnReceive.gameObject:SetActiveEx(not self.IsDraw)
    self.BtnReceive:SetDisable(not reach, reach)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(self.IsDraw)
end
 
-- 领取状态
function XUiGridRewardItem:RefreshRewards()
    local RewordGoodList = XRewardManager.GetRewardList(self.RewardId)
    for index, rewardGood in ipairs(RewordGoodList) do
        if XTool.IsTableEmpty(self.RewardGoodUiTable[index]) then
            self.RewardGoodUiTable[index] = XUiGridCommon.New(XUiHelper.Instantiate(self.GridCommon, self.PanelTreasureContent))
        end
        self.RewardGoodUiTable[index]:Refresh(rewardGood)
    end
    self.GridCommon.gameObject:SetActiveEx(false)
end

-- 领取奖励
function XUiGridRewardItem:OnBtnReceive()
    if self.CurPoint < self.Point then return end
    XDataCenter.CourseManager.RequestCourseGetReward({ self.CourseRewardId }, function ()
        self:RefreshUi(self.CourseRewardId, self.ChapterId)
    end)
end

return XUiGridRewardItem