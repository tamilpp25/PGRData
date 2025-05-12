local CSGetText = CS.XTextManager.GetText

---@class XUiGridChapterBfrt:XUiNode
local XUiGridChapterBfrt = XClass(XUiNode, "XUiGridChapterBfrt")

function XUiGridChapterBfrt:OnStart()
    ---@type UnityEngine.Transform
    self._ShowProgressObjList = {}
    ---@type XUiBfrtGridReward[]
    self._GridShowRewardList = {}
    self:InitUi()
    self:AddBtnListener()
    self:AddEventListener()
end

function XUiGridChapterBfrt:OnDestroy()
    self:RemoveEventListener()
end

--region Ui - Refresh
function XUiGridChapterBfrt:InitUi()
    if self.PanelReward then
        local XUiBfrtGridReward = require("XUi/XUiBfrt/Main/XUiBfrtGridReward")
        self._GridShowRewardList = {
            XUiBfrtGridReward.New(self.PanelReward, self),
            XUiBfrtGridReward.New(self.PanelReward2, self),
        }
    end
    if self.RImgDes01 then
        self._ShowProgressObjList = {
            self.RImgDes01,
            self.RImgDes02,
            self.RImgDes03,
        }
    end

    self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect")
end

function XUiGridChapterBfrt:RefreshData(chapterId, isFirst, isLast)
    self._IsFirst = isFirst
    self._IsLast = isLast
    self._ChapterId = chapterId
    self._ChapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
    self._BfrtRewardCfg = XDataCenter.BfrtManager.GetBfrtReward(self._ChapterCfg.BfrtRewardId)
    self._ChapterPassCount = XDataCenter.BfrtManager.GetChapterPassCount(chapterId)
    self._ChapterTotalCount = XDataCenter.BfrtManager.GetChapterGroupCount(chapterId)
    self._NextChapterId = XDataCenter.BfrtManager.GetNextChapterIdById(chapterId)
    self._NextChapterTotalCount = XDataCenter.BfrtManager.GetChapterGroupCount(self._NextChapterId)
    self._PassCount = XDataCenter.BfrtManager.GetAllChapterPassCount()
    self._TotalCount = XDataCenter.BfrtManager.GetAllChapterGroupCount(chapterId)

    self:_RefreshChapter()
    self:_RefreshShowReward()
    self:_RefreshProcess()
    self:_RefreshRedPoint()
    self:CloseSelectEffect()
end

function XUiGridChapterBfrt:OpenSelectEffect()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(true)
    end
    for _, grid in ipairs(self._GridShowRewardList) do
        grid:OpenFlashEffect()
    end
    XScheduleManager.ScheduleOnce(function()
        XEventManager.DispatchEvent(XEventId.EVENT_BFRT_CHAPTER_EFFECT_CLOSE)
    end, 500)
end

function XUiGridChapterBfrt:CloseSelectEffect()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    for _, grid in ipairs(self._GridShowRewardList) do
        grid:CloseFlashEffect()
    end
end

function XUiGridChapterBfrt:_RefreshChapter()
    self.RImgIcon:SetRawImage(self._ChapterCfg.Cover)
    self.TxtOrder.text = self._ChapterCfg.ChapterName
    self.TxtName.text = self._ChapterCfg.ChapterEn
    if self.TxtNameProj then
        self.TxtNameProj.text = self._ChapterCfg.ChapterEn
    end

    local chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(self._ChapterId)
    if chapterInfo.Unlock then
        self.BtnUnlockCover.gameObject:SetActiveEx(false)
        self.BtnClick.gameObject:SetActiveEx(true)
    else
        self.TxtUnlockCondition.text = CSGetText("BfrtChpaterLocked", self._PassCount, self._TotalCount)
        self.BtnUnlockCover.gameObject:SetActiveEx(true)
        self.BtnClick.gameObject:SetActiveEx(false)
    end

    self.ImgActivityTab.gameObject:SetActiveEx(chapterInfo.IsActivity)
end

function XUiGridChapterBfrt:_RefreshShowReward()
    if XTool.IsTableEmpty(self._GridShowRewardList) then
        return
    end
    if not self._BfrtRewardCfg or XTool.IsTableEmpty(self._BfrtRewardCfg.ShowItems) then
        for _, grid in ipairs(self._GridShowRewardList) do
            grid:Close()
        end
        return
    end
    local showItems = self._BfrtRewardCfg.ShowItems
    self.BtnRecv.gameObject:SetActiveEx(XDataCenter.BfrtManager.CheckCanRecvCourseReward(self._ChapterId))
    local showCount = 0
    for i, itemStr in ipairs(showItems) do
        local showItemList = XDataCenter.BfrtManager.GetBfrtRewardShowItemListByStr(itemStr)
        for j, showId in ipairs(showItemList) do
            if self._GridShowRewardList[j] then
                self._GridShowRewardList[j]:RefreshItem(self._BfrtRewardCfg.Id, i, showId)
                self._GridShowRewardList[j]:Open()
                showCount = showCount + 1
            end
        end
    end
    for i = showCount + 1, #self._GridShowRewardList do
        self._GridShowRewardList[i]:Close()
    end
end

function XUiGridChapterBfrt:_RefreshProcess()
    if not self.PanelProgress then
        return
    end

    local processTxt = CSGetText("BfrtCourseProcess", self._PassCount, XDataCenter.BfrtManager.GetAllChapterGroupCount(0))
    self.TxtProcess.text = self._TotalCount
    self.TxtCurProcess.text = self._TotalCount
    self.TxtProcess.gameObject:SetActiveEx(self._ChapterPassCount ~= self._ChapterTotalCount)
    self.TxtCurProcess.gameObject:SetActiveEx(self._ChapterPassCount == self._ChapterTotalCount)

    for i = 1, self._ChapterTotalCount do
        if self._ShowProgressObjList[i] then
            self._ShowProgressObjList[i].gameObject:SetActiveEx(i <= self._ChapterPassCount)
        end 
    end

    if self._IsLast then
        self.PanelProgress.gameObject:SetActiveEx(false)
    else
        self.PanelProgress.gameObject:SetActiveEx(true)
        self.ImgProgress.fillAmount = (self._ChapterPassCount - self._ChapterTotalCount) / self._NextChapterTotalCount
    end

    if self._IsFirst then
        self.TxtProcessAll.text = processTxt
        self.TxtProcessAll.gameObject:SetActiveEx(true)
        self.PanelProgressLeft.gameObject:SetActiveEx(false)
    else
        self.TxtProcessAll.gameObject:SetActiveEx(false)
        self.PanelProgressLeft.gameObject:SetActiveEx(true)
        self.ImgProgressLeft.fillAmount = self._ChapterPassCount / self._ChapterTotalCount
    end
end

function XUiGridChapterBfrt:_RefreshRedPoint()
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_BFRT_CHAPTER_REWARD }, self._ChapterId)
end

function XUiGridChapterBfrt:OnCheckRedPoint(count)
    self.ImgRedDot.gameObject:SetActiveEx(count >= 0)
end
--endregion

--region Ui - BtnListener
function XUiGridChapterBfrt:AddBtnListener()
    self.BtnUnlockCover.CallBack = function()
        local chapterId = self._ChapterId
        local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
        local chapterInfo = XDataCenter.BfrtManager.GetChapterInfo(chapterId)

        local conditionId = chapterCfg.ActivityCondition
        if conditionId ~= 0 then
            local ret, des = XConditionManager.CheckCondition(chapterCfg.ActivityCondition)
            if not ret then
                XUiManager.TipMsg(des)
                return
            end
        end

        if not chapterInfo.Unlock then
            XUiManager.TipMsg(CSGetText("BfrtChapterUnlockCondition"))
            return
        end
    end
    XUiHelper.RegisterClickEvent(self, self.BtnRecv, self.OnRecvCourseReward)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnOpenChapter)
end

function XUiGridChapterBfrt:OnRecvCourseReward()
    if XDataCenter.BfrtManager.CheckCanRecvCourseReward(self._ChapterId) then
        XDataCenter.BfrtManager.RequestReceiveCourseReward()
    end
end

function XUiGridChapterBfrt:OnOpenChapter()
    --分包资源检测
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Bfrt, self._ChapterId) then
        return
    end
    local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(self._ChapterId)
    XLuaUiManager.Open("UiFubenMainLineChapter", chapterCfg, nil, true)
end
--endregion

--region Event
function XUiGridChapterBfrt:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_CHAPTER_EFFECT_CLOSE, self.CloseSelectEffect, self)
end

function XUiGridChapterBfrt:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_CHAPTER_EFFECT_CLOSE, self.CloseSelectEffect, self)
end
--endregion

return XUiGridChapterBfrt