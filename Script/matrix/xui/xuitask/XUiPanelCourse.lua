local XUiGridCourse = require("XUi/XUiTask/XUiGridCourse")
---@class XUiPanelCourse
local XUiPanelCourse = XClass(nil, "XUiPanelCourse")
local Vector2 = CS.UnityEngine.Vector2
local V3Z = CS.UnityEngine.Vector3.zero
local ProTime = 2

function XUiPanelCourse:Ctor(rootUi, ui, chapterId, stroyUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.StroyUi = stroyUi
    self.GridCourseList = {}
    XTool.InitUiObject(self)

    self.GridCourse.gameObject:SetActive(false)
    self:RefreshCourseList(chapterId)

end

function XUiPanelCourse:RefreshCourse()
    self:RefreshCourseList(self.ChapterId)
end

function XUiPanelCourse:RefreshCourseList(chapterId)
    if not chapterId then return end
    self.CourseInfo = XDataCenter.TaskManager.GetCourseInfo(chapterId)
    if not self.CourseInfo then
        return
    end
    self.ChapterId = chapterId
    self.SViewCourse.horizontalNormalizedPosition = 0

    self.CurPrIndex = 0
    local index = 0

    -- 过滤重复数据。排查bug单#139385，出现重复关卡奖励
    local list = {}
    local stageIdDic = {}
    for _, course in pairs(self.CourseInfo.Courses) do
        local stageId = course.StageId
        if stageIdDic[stageId] then
            XLog.Error(string.format( "TaskManager.GetCourseInfo获取chapterId = %s对应的Courses出现重复关卡数据，stageId = %s", chapterId, stageId))
        else
            table.insert(list, course)
            stageIdDic[stageId] = true
        end
    end

    for i = 1, #list do
        local grid = self.GridCourseList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCourse)
            grid = XUiGridCourse.New(self.RootUi, ui, self.StroyUi, function(cId)
                self:RefreshCourseList(cId)
            end, function()
                -- self:SetSViewIndex()
            end)
            grid.GameObject.name = list[i].StageId
            grid.Transform:SetParent(self.PanelCourseContainer, false)
            self.GridCourseList[i] = grid
        end

        local stageInfo = XDataCenter.FubenManager.GetStageInfo(list[i].StageId)
        if self:IsPass(list[i].StageId) or (stageInfo and stageInfo.Passed) then
            self.CurPrIndex = index
        end

        grid:Refresh(list[i], self.CourseInfo.LastStageId, self.CourseInfo.NextChapterId)
        grid.GameObject:SetActive(true)
        index = index + 1
    end

    for i = #list + 1, #self.GridCourseList do
        self.GridCourseList[i].GameObject:SetActive(false)
    end

    local prowidth = (self.GridCourse.sizeDelta.x + self.PanelCourseContainerLayout.spacing) * (index - 1)
    local contentwidth = prowidth + self.GridCourse.sizeDelta.x + self.PanelCourseContainerLayout.padding.left
    self.Container.sizeDelta = Vector2(contentwidth, self.GridCourse.sizeDelta.y)
    self.ProgressBgRec.sizeDelta = Vector2(prowidth, self.ImgProgressRec.sizeDelta.y)
    self.ImgProgressRec.sizeDelta = Vector2(prowidth, self.ImgProgressRec.sizeDelta.y)
    self.ProgressBgRec:SetParent(self.GridCourseList[1].ProGo, true)
    self.ProgressBgRec.localPosition = V3Z

    self:SetSViewIndex()
    self:PlayImgFill()
end

function XUiPanelCourse:IsPass(id)
    if not id then
        return false
    end

    local result = XMVCA.XFuben:GetFubenSettleResult()
    return result and result.IsWin and result.StageId == id
end

function XUiPanelCourse:SetSViewIndex()
    if not self.CourseInfo then return end
    local rewardIndex = XDataCenter.TaskManager.GetCourseCurRewardIndex(self.ChapterId)
    local length = #self.CourseInfo.Courses or 0
    if rewardIndex then
        if rewardIndex <= 1 then
            rewardIndex = 0
        elseif rewardIndex >= 16 then
            rewardIndex = 1
        end

        local percentage = 0
        if length > 0 then
            percentage = (rewardIndex - 1) / length
        end
        self.SViewCourse.horizontalNormalizedPosition = percentage
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
    end
    self.CurLen = length
end

function XUiPanelCourse:FillPro(v)
    self.ImgProgress.fillAmount = v or 0
end

function XUiPanelCourse:PlayImgFill()
    local r = 0
    if self.CurPrIndex and self.CurLen and self.CurPrIndex > 0 and self.CurLen > 1 then
        r = (self.CurPrIndex) / (self.CurLen - 1)
    end

    if r == self.CurRa then
        return
    end

    self.CurRa = r
    self:FillPro()
    self.ImgProgress:DOFillAmount(r, ProTime)
end

return XUiPanelCourse