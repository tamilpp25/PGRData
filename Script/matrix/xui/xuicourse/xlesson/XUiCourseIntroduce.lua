local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- ConditionShow
-- ================================================================================
local XUiGridConditionItem = XClass(nil, "XUiGridLessonItem")
function XUiGridConditionItem:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, self.Ui)
end

function XUiGridConditionItem:RefreshUi(desc, isClear)
    self.Finish.gameObject:SetActiveEx(isClear)
    self.UnFinish.gameObject:SetActiveEx(not isClear)
    self.TxtFinish.text = desc
    self.TxtUnFinish.text = desc
end


-- 课程详情界面
-- ================================================================================
local XUiCourseIntroduce = XLuaUiManager.Register(XLuaUi,"UiCourseIntroduce")

function XUiCourseIntroduce:OnAwake()
    self:AddButtonListenr()
    self.GridReward.gameObject:SetActive(false)
end

function XUiCourseIntroduce:OnStart(chapterId)
    self.ChapterId = chapterId
    self.RewardGrids = {}
    self:RefreshUi()
end

function XUiCourseIntroduce:OnEnable()

end

function XUiCourseIntroduce:OnDisable()

end

function XUiCourseIntroduce:RefreshUi()
    self:RefreshTxt()
    self:RefreshCondition()
    self:RefreshReward()
    self:RefreshBtn()
end

function XUiCourseIntroduce:RefreshTxt()
    local chapterId = self.ChapterId
    self.NameTitle.text = XCourseConfig.GetCourseChapterName(chapterId)
    self.DescTitle.text = XCourseConfig.GetCourseLessonDetailDescTitleById(chapterId)
    self.Desc.text = XCourseConfig.GetCourseLessonDetailDescById(chapterId)
end

--参与条件
function XUiCourseIntroduce:RefreshCondition()
    local chapterId = self.ChapterId
    local unlockLessonPoint = XCourseConfig.GetCourseChapterUnlockLessonPoint(chapterId)
    local prevChapterIdList = XCourseConfig.GetCourseChapterPrevChapterId(chapterId)
    local unlockLv = XCourseConfig.GetCourseChapterUnlockLv(chapterId)
    local lessonPointDesc, prevChapterDesc = XCourseConfig.GetChapterTipsUnlockDesc()
    local desc, isClear

    if unlockLessonPoint and unlockLessonPoint > 0 then
        --条件1：解锁需要总课程绩点
        desc = string.format(lessonPointDesc, unlockLessonPoint)
        isClear = XDataCenter.CourseManager.IsChapterUnlockPoint(chapterId)
        local conditionUi = XUiGridConditionItem.New(XUiHelper.Instantiate(self.GridCondition, self.PanelAllCondition))
        conditionUi:RefreshUi(desc, isClear)
    end

    if unlockLv and unlockLv > 0 then
        --条件2：解锁所需等级
        local conditionUiLv = XUiGridConditionItem.New(XUiHelper.Instantiate(self.GridCondition, self.PanelAllCondition))
        conditionUiLv:RefreshUi(XCourseConfig.GetCourseChapterLockDesc(chapterId), XPlayer.GetLevel() >= unlockLv)
    end
   
    
    for i, id in ipairs(prevChapterIdList) do
        if XTool.IsNumberValid(id) then
            local chapterName = XCourseConfig.GetCourseChapterName(id)
            desc = string.format(prevChapterDesc, chapterName)
            isClear = XDataCenter.CourseManager.IsChapterUnlockPrevChapter(id, i)
            local item = XUiGridConditionItem.New(XUiHelper.Instantiate(self.GridCondition, self.PanelAllCondition))
            item:RefreshUi(desc, isClear)
        end
    end
    self.GridCondition.gameObject:SetActive(false)
end

--课程奖励
function XUiCourseIntroduce:RefreshReward()
    local rewardId = XCourseConfig.GetLessonShowReward(self.ChapterId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end

    local rewordGoodList = XRewardManager.GetRewardList(rewardId)
    for i, rewardGood in ipairs(rewordGoodList or {}) do
        local rewardGoodUi = self.RewardGrids[i]
        if not rewardGoodUi then
            rewardGoodUi = XUiGridCommon.New(XUiHelper.Instantiate(self.GridReward, self.PanelGift))
        end
        rewardGoodUi:Refresh(rewardGood)
    end
end

function XUiCourseIntroduce:RefreshBtn()
    local isOpen = XDataCenter.CourseManager.CheckChapterIsOpen(self.ChapterId)
    self.BtnEnter:SetDisable(not isOpen, isOpen)
end

function XUiCourseIntroduce:AddButtonListenr()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self.BtnEnter.CallBack = function() self:OnEnterChapter() end
end

function XUiCourseIntroduce:OnEnterChapter()
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Course, self.ChapterId) then
        return
    end
    XLuaUiManager.PopThenOpen("UiCourseTutorial", self.ChapterId)
end