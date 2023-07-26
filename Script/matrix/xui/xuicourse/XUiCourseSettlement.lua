-- ConditionShow
-- ================================================================================
local XUiGridTargetItem = XClass(nil, "XUiGridTargetItem")
function XUiGridTargetItem:Ctor(ui)
    self.Ui = ui
    XUiHelper.InitUiClass(self, self.Ui)
    self.UiGridCommon = XUiGridCommon.New(self.GridCommon)
end

function XUiGridTargetItem:RefreshUi(clear, count, desc, isLesson)
    self.UiGridCommon.GameObject:SetActiveEx(isLesson)
    if isLesson then
        self.UiGridCommon:Refresh(XDataCenter.CourseManager.GetTipShowItemData())
        self.TxtCount.text = count
        self.UiGridCommon:ShowCount(true)
    end
    self.TxtDesc.text = desc
    local isClear = clear and true or false
    self.Txtnfinish.gameObject:SetActiveEx(isClear)
    self.TxtUnfinished.gameObject:SetActiveEx(not isClear)
    
end


-- 课程关卡结算界面
-- ================================================================================
local XUiCourseSettlement = XLuaUiManager.Register(XLuaUi,"UiCourseSettlement")
local CourseSettleLevelSImgPath = CS.XGame.ClientConfig:GetString("CourseSettleLevelSImgPath")
local CourseSettleLevelAImgPath = CS.XGame.ClientConfig:GetString("CourseSettleLevelAImgPath")
local CourseSettleLevelBImgPath = CS.XGame.ClientConfig:GetString("CourseSettleLevelBImgPath")

function XUiCourseSettlement:OnAwake()
    self:AddButtonListenr()
    self.TxtSaveTips = self.BtnSave.transform:Find("Text")
end

function XUiCourseSettlement:OnStart(data)
    self.SettleData = data
    self.StageId = data.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.StarsCount, self.StarsMap = XTool.GetStageStarsFlag(self.SettleData.StarsMark, #stageCfg.StarDesc)
    self.RewardGrids = {}
end

function XUiCourseSettlement:OnEnable()
    self:RefreshUi()
end

function XUiCourseSettlement:RefreshUi()
    self:RefreshBtn()
    self:RefreshTxt()
    self:RefreshReward()
    self:RefreshCondition()
    self:RefreshResultImg()
end

function XUiCourseSettlement:RefreshBtn()
    local passed = XDataCenter.CourseManager.CheckStageIsComplete(self.StageId)
    self.BtnCancel.gameObject:SetActiveEx(passed)
    self.TxtSaveTips.gameObject:SetActiveEx(passed)
end

function XUiCourseSettlement:RefreshTxt()
    local stageId = self.StageId
    self.TxtDifficult.text = XCourseConfig.GetCourseStageNameById(stageId)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local passTimeLimit = stageCfg.PassTimeLimit
    local leftTime = self.SettleData.LeftTime
    self.TxtStageTime.text = XUiHelper.GetTime(math.max(0, passTimeLimit - leftTime))
end

function XUiCourseSettlement:RefreshResultImg()
    -- 根据通过的标签定级 S-A-B
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local starCfgNumber = #stageCfg.StarDesc
    
    local count = 0
    for _, value in ipairs(self.StarsMap) do
        if value then count = count + 1 end
    end
    if count == 0 then
        self.RImgSame:SetRawImage(CourseSettleLevelBImgPath)
    elseif count > 0 and count < starCfgNumber then
        self.RImgSame:SetRawImage(CourseSettleLevelAImgPath)
    else
        self.RImgSame:SetRawImage(CourseSettleLevelSImgPath)
    end
end

function XUiCourseSettlement:RefreshCondition()
    local stageId = self.StageId
    local descList = XFubenConfigs.GetStarDesc(stageId)
    local points = XCourseConfig.GetCourseStageStarPointById(stageId)
    local chapterId = XCourseConfig.GetChapterIdByStageId(stageId)
    local stageType = XCourseConfig.GetChapterStageType(chapterId)
    local isLesson = stageType == XCourseConfig.SystemType.Lesson
    for index, value in ipairs(self.StarsMap) do
        local rewardGoodUi = XUiGridTargetItem.New(XUiHelper.Instantiate(self.PanelTarget, self.PanelAllTarget))
        rewardGoodUi:RefreshUi(value, points[index], descList[index], isLesson)
    end
    self.PanelTarget.gameObject:SetActive(false)
end

function XUiCourseSettlement:RefreshReward()
    local rewardId = XFubenConfigs.GetFirstRewardShow(self.StageId)
    local passed = XDataCenter.CourseManager.CheckStageIsComplete(self.StageId)
    self.PanelFirstPass.gameObject:SetActiveEx(not passed)
    --通关后不显示首通奖励
    if not XTool.IsNumberValid(rewardId) or passed then
        self.GridCommon.gameObject:SetActive(false)
        return
    end

    local rewordGoodList = XRewardManager.GetRewardList(rewardId)
    for i, rewardGood in ipairs(rewordGoodList) do
        local rewardGoodUi = self.RewardGrids[i]
        if not rewardGoodUi then
            rewardGoodUi = XUiGridCommon.New(XUiHelper.Instantiate(self.GridCommon, self.PanelGift))
            self.RewardGrids[i] = rewardGoodUi
        end
        rewardGoodUi:Refresh(rewardGood)
    end
    self.GridCommon.gameObject:SetActive(false)
end

function XUiCourseSettlement:AddButtonListenr()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnSave, self.SaveResult)
end

function XUiCourseSettlement:OnBtnCancelClick()
    local starTotalCount = #XCourseConfig.GetCourseStageStarPointById(self.StageId)
    if self.StarsCount >= starTotalCount then
        local title = XUiHelper.GetText("TipTitle")
        local content = XCourseConfig.GetCourseClientConfig("SettlementCacelDialogDesc").Values[1]
        local sureCallback = handler(self, self.Close)
        XUiManager.DialogTip(title, content, nil, nil, sureCallback)
        return
    end
    self:Close()
end

function XUiCourseSettlement:SaveResult()
    local stageId = self.StageId
    local chapterId = XCourseConfig.GetChapterIdByStageId(stageId)
    local title = XUiHelper.GetText("TipTitle")
    local content, sureCallback
    
    if XDataCenter.CourseManager.CheckChapterIsFullStar(chapterId) then
        content = XCourseConfig.GetCourseClientConfig("SettlementSaveDialogInoperativeDesc").Values[1]
        sureCallback = function()
            self:Close()
        end
        XUiManager.DialogTip(title, content, XUiManager.DialogType.OnlySure, nil, sureCallback)
    else
        local curStarCount = XDataCenter.CourseManager.GetStageStarsCount(stageId)
        if self.StarsCount < curStarCount then
            content = XCourseConfig.GetCourseClientConfig("SettlementSaveDialogDesc").Values[1] 
            sureCallback = function()
                self:RequestCourseSaveResult()
            end
            XUiManager.DialogTip(title, content, nil, nil, sureCallback)
            return
        end

        self:RequestCourseSaveResult()
    end
end

function XUiCourseSettlement:RequestCourseSaveResult()
    local chapterId = XCourseConfig.GetChapterIdByStageId(self.StageId)
    XDataCenter.CourseManager.RequestCourseSaveResult(handler(self, self.Close), nil, chapterId)
end