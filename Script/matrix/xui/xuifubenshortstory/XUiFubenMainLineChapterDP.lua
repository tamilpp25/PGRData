local XUiGridStoryChapterDP = require("XUi/XUiFubenShortStory/XUiGridStoryChapterDP")
local XUiGridExploreChapterDP = require("XUi/XUiFubenShortStory/XUiGridExploreChapterDP")
local XUiPanelStoryJump = require("XUi/XUiFubenMainLineChapter/XUiPanelStoryJump")
local XUiFubenMainLineChapterDP = XLuaUiManager.Register(XLuaUi,"UiFubenMainLineChapterDP")
local XUiFubenMainLineQuickJumpBtnDP = require("XUi/XUiFubenShortStory/XUiFubenMainLineQuickJumpBtnDP")
local XUiGridTreasureGradeDP = require("XUi/XUiFubenShortStory/XUiGridTreasureGradeDP")
function XUiFubenMainLineChapterDP:OnAwake()
    self:AddListener()
end

-- 浮点纪实
function XUiFubenMainLineChapterDP:OnStart(chapterId, stageId, hideDiffTog)
    if self.LastData then
        self.ChapterId = self.LastData.ChapterId or chapterId
        self.StageId = self.LastData.StageId or stageId
        self.HideDiffTog = self.LastData.HideDiffTog or hideDiffTog
        self.LastData = nil
    else
        self.ChapterId = chapterId
        self.StageId = stageId
        self.HideDiffTog = hideDiffTog
    end
    --当前难度
    self.CurDiff = XFubenShortStoryChapterConfigs.GetDifficultByChapterId(self.ChapterId)
    --是否有探索组id
    self.IsExploreMod = XFubenShortStoryChapterConfigs.CheckChapterTypeIsExplore(self.ChapterId)
    --ShortStoryChapter表的Id
    self.ChapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(self.ChapterId)
    self.OrderId = XFubenShortStoryChapterConfigs.GetChapterOrderIdByChapterId(self.ChapterId)
    self.ZhouMuId = XFubenShortStoryChapterConfigs.GetZhouMuId(self.ChapterMainId)
    
    self.Opened = false
    self.IsOnZhouMu = false
    self.GridTreasureList = {}
    self.GridMultipleWeeksTaskList = {}
    self.GridChapterList = {} --存的是各种Chapter的预制体实例列表
    self.QuickJumpBtnList = {}
    self.PanelExploreBottom = {}
    self.CurChapterGrid = nil
    self.CurChapterGridName = ""
    self.PanelStageDetailInst = nil
    
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.ImgRedProgress.gameObject:SetActiveEx(false)
    
    --保存初始颜色
    self.OriginalColors = {
        TxtChapterNameColor = self.TxtChapterName.color, --章节名称
        TxtLeftTimeTipColor = self.Text_1.color, --剩余时间描述
        TxtLeftTimeColor = self.TxtLeftTime.color, --剩余时间
        StarColor = self.ImageLine.color, --星星
        ImageBottomColor = self.ImageBottom.color, --底部栏
        TxtStarNumColor = self.TxtStarNum.color, --星星数量
        TxtDescrColor = self.Txet.color, --收集进度
        Triangle0Color = self.Triangle0.color, --底部栏左侧三角形
        Triangle1Color = self.Triangle1.color,
        Triangle2Color = self.Triangle2.color,
        Triangle3Color = self.Triangle3.color,
    }

    -- 注册红点事件
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_SHORT_STORY_TREASURE }, self.ChapterId, false)
    self.RedPointZhouMuId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_ZHOUMU_TASK }, self.ZhouMuId, false)
    
    -- 注册stage事件
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)

    -- 难度toggle
    if not self.HideDiffTog then
        self.IsShowDifficultPanel = false
        self:UpdateDifficultToggles()
    else
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
    end
    self:InitPanelBottom()
    self:InitPanelStoryJump()
end

function XUiFubenMainLineChapterDP:OnEnable()
    -- 是否显示周目挑战按钮
    self.ZhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(self.ZhouMuId)
    self.PanelMultipleWeeksInfo.gameObject:SetActiveEx(self.ZhouMuNumber ~= 0)

    if self.GridChapterList then
        for _, v in pairs(self.GridChapterList) do
            v:OnEnable()
        end
    end

    self:UpdateDifficultToggles()
    self:UpdateCurChapter(self.ChapterId)

    self:GoToLastPassStage()
end

function XUiFubenMainLineChapterDP:OnDisable()
    if self.GridChapterList then
        for _, v in pairs(self.GridChapterList) do
            v:OnDisable()
        end
    end

    if not self.IsExploreMod then
        local childUi = self:GetCurDetailChildUi()
        self:CloseChildUi(childUi)
        self:OnCloseStageDetail()
    end
end

function XUiFubenMainLineChapterDP:OnDestroy()
    self:DestroyActivityTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XRedPointManager.RemoveRedPointEvent(self.RedPointId)
    XRedPointManager.RemoveRedPointEvent(self.RedPointZhouMuId)
end

function XUiFubenMainLineChapterDP:InitPanelBottom()
    self.PanelExploreBottom.Transform = self.PanelExploreBottomObj.transform
    self.PanelExploreBottom.GameObject = self.PanelExploreBottomObj.gameObject
    XTool.InitUiObject(self.PanelExploreBottom)

    self.PanelExploreBottom.BtnNormalJump.gameObject:SetActiveEx(false)
    self.PanelExploreBottom.BtnHardlJump.gameObject:SetActiveEx(false)
end

function XUiFubenMainLineChapterDP:InitPanelStoryJump()
    ---@type XUiPanelStoryJump
    self.PanelStoryJump = XUiPanelStoryJump.New(self.PanelStoryJumpBottom, self)
end

function XUiFubenMainLineChapterDP:GoToLastPassStage()
    if self.CurChapterGrid then
        if self.IsExploreMod then
            if self.IsCanGoNearestStage or not self.Opened then
                self.CurChapterGrid:GoToNearestStage()
                self.Opened = true
                self.IsCanGoNearestStage = false
            end
        else
            if not self.Opened then
                local lastPassStageId = XDataCenter.ShortStoryChapterManager.GetLastPassStage(self.ChapterId)
                self.CurChapterGrid:GoToStage(lastPassStageId)
                self.Opened = true
            end
        end
    end
end

function XUiFubenMainLineChapterDP:StageLevelChangeAutoMove()
    if self.CurChapterGrid then
        if self.IsExploreMod then
            self.CurChapterGrid:GoToNearestStage()
        else
            local lastPassStageId = XDataCenter.ShortStoryChapterManager.GetLastPassStage(self.ChapterId)
            self.CurChapterGrid:GoToStage(lastPassStageId)
        end
    end
end

-- 打开关卡详情
function XUiFubenMainLineChapterDP:OpenStage(stageId, needRefreshChapter)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    self.CurDiff = stageInfo.Difficult
    XDataCenter.ShortStoryChapterManager.SetCurDifficult(self.CurDiff)

    self:UpdateDifficultToggles()

    if needRefreshChapter then
        self:UpdateCurChapter(stageInfo.ChapterId)
    end
    self.CurChapterGrid:ClickStageGridByIndex(stageInfo.OrderId)
end

function XUiFubenMainLineChapterDP:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end
    local team = nil
    local proxy = nil
    if stage.HideAction == 1 then
        team = XDataCenter.TeamManager.GetXTeamByStageId(stage.StageId)
        team:UpdateEntityIds(XTool.Clone(stage.RobotId))
        proxy = require("XUi/XUiFubenShortStory/BattleRole/XUiShortStoryBattleRoleRoom")
    end
    XLuaUiManager.Open("UiBattleRoleRoom", stage.StageId, team, proxy)
end

-- 是否显示红点
function XUiFubenMainLineChapterDP:OnCheckRewards(count, chapterId)
    if self.IsOnZhouMu then
        if self.ImgRedProgress and chapterId == self.ZhouMuId then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    else
        if self.ImgRedProgress and chapterId == self.ChapterId then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    end
end

function XUiFubenMainLineChapterDP:AddListener()
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick)
    self:RegisterClickEvent(self.Scrollbar, self.OnScrollbarClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnCloseDifficult, self.OnBtnCloseDifficultClick)
    self:RegisterClickEvent(self.BtnCloseDetail, self.OnBtnCloseDetailClick)

    self.BtnExItem.CallBack = function()
        self:OnBtnExItemClick()
    end
    self.BtnNormal.CallBack = function()
        self:OnBtnNormalClick(true)
    end
    self.BtnHard.CallBack = function()
        self:OnBtnHardClick(true)
    end
    self.BtnSwitch1MultipleWeeks.CallBack = function()
        self:OnBtnSwitch1MultipleWeeksClick()
    end
    self.BtnSwitch2Normal.CallBack = function()
        self:OnBtnSwitch2NormalClidk()
    end
end
-- auto
function XUiFubenMainLineChapterDP:OnBtnCloseDetailClick()
    self:OnCloseStageDetail()
end

function XUiFubenMainLineChapterDP:OnBtnCloseDifficultClick()
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineChapterDP:OnScrollbarClick()

end

function XUiFubenMainLineChapterDP:OnBtnExItemClick()
    XLuaUiManager.Open("UiFubenExItemTip", self)
end

function XUiFubenMainLineChapterDP:OnBtnBackClick()
    if self:CloseStageDetail() then
        return
    end
    self:Close()
end

function XUiFubenMainLineChapterDP:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenMainLineChapterDP:OnBtnNormalClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultNormal then
            local unlock = XDataCenter.ShortStoryChapterManager.IsUnlock(self.ChapterId)
            local firstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(self.ChapterId)
            if not unlock then
                XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(firstStage), XUiManager.UiTipType.Wrong)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultNormal
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenMainLineChapterDP:OnBtnHardClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultHard then
            -- 检查困难开启
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
                return false
            end

            -- 检查主线副本活动
            local isActivity = XDataCenter.ShortStoryChapterManager.IsActivity(self.ChapterId)
            if isActivity then
                local chapterId = XFubenShortStoryChapterConfigs.GetChapterIdByIdAndDifficult(self.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local ret, desc = XDataCenter.ShortStoryChapterManager.CheckActivityCondition(chapterId)
                if not ret then
                    XUiManager.TipMsg(desc, XUiManager.UiTipType.Wrong)
                    return false
                end
            end
            -- 检查困难这个章节解锁
            local isOpen = XDataCenter.ShortStoryChapterManager.IsOpen(self.ChapterId)
            local firstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(self.ChapterId)
            if not isOpen then
                local chapterId = XFubenShortStoryChapterConfigs.GetChapterIdByIdAndDifficult(self.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local ret, desc = XDataCenter.ShortStoryChapterManager.CheckOpenCondition(chapterId)
                if not ret then
                    XUiManager.TipError(desc)
                    return false
                end
                local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(firstStage)
                XUiManager.TipMsg(tipMsg)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultHard
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenMainLineChapterDP:UpdateDifficultToggles(showAll)
    if showAll then
        self:SetBtnToggleActive(true, true, true)
        self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    else
        if self.CurDiff == XDataCenter.FubenManager.DifficultNormal then
            self:SetBtnToggleActive(true, false, false)
            self.BtnNormal.transform:SetAsFirstSibling()
        elseif self.CurDiff == XDataCenter.FubenManager.DifficultHard then
            self:SetBtnToggleActive(false, true, false)
            self.BtnHard.transform:SetAsFirstSibling()
        else
            self:SetBtnToggleActive(false, false, true)
        end
        self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    end
    self.IsShowDifficultPanel = showAll
    
    --Progress
    local chapterIds = XFubenShortStoryChapterConfigs.GetShortStoryChapterIds(self.ChapterMainId)
    -- 普通关卡
    if chapterIds[1] then
        local progress = XDataCenter.ShortStoryChapterManager.GetProgressByChapterId(chapterIds[1])
        self.TxtNormalProgress.text = progress
    end
    -- 困难关卡
    if chapterIds[2] then
        local progress = XDataCenter.ShortStoryChapterManager.GetProgressByChapterId(chapterIds[2])
        self.TxtHardProgress.text = progress
    end
    
    -- 抢先体验活动倒计时
    self:UpdateActivityTime()
end

function XUiFubenMainLineChapterDP:UpdateChapterTxt()
    local shortStoryTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(self.ChapterId)
    self.TxtChapter.text = (shortStoryTitle or "")
    self.TxtChapterName.text = XFubenShortStoryChapterConfigs.GetChapterEnByChapterId(self.ChapterId)
end

function XUiFubenMainLineChapterDP:SetBtnToggleActive(isNormal, isHard)
    self.BtnNormal.gameObject:SetActiveEx(isNormal)

    self.BtnHard.gameObject:SetActiveEx(isHard)
    if isHard then
        local hardOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)
        local isOpen = XDataCenter.ShortStoryChapterManager.IsOpen(self.ChapterId)
        hardOpen = hardOpen and isOpen
        self.PanelHardOn.gameObject:SetActiveEx(hardOpen)
        self.PanelHardOff.gameObject:SetActiveEx(not hardOpen)
    end

    -- 刷新蓝点 redpoint
    -- 普通剧情下
    local chapterIds = XFubenShortStoryChapterConfigs.GetShortStoryChapterIds(self.ChapterMainId)
    local normalChapterId = chapterIds[1]
    local hideChapterId = chapterIds[2]
    if self.CurDiff == XDataCenter.FubenManager.DifficultNormal then
        if hideChapterId then
            local viewModel = XDataCenter.ShortStoryChapterManager:ExGetChapterViewModelById(self.ChapterId, XDataCenter.FubenManager.DifficultHard)
            local isUnFinAndUnEnter = XDataCenter.FubenManagerEx.CheckHideChapterRedPoint(viewModel) --v1.30 新入口红点规则，未完成隐藏且没点击过
            local hardRed = XRedPointConditionShortStoryChapterReward.Check(hideChapterId) or isUnFinAndUnEnter

            self.BtnNormal:ShowReddot(not isHard and hardRed)
            self.BtnHard:ShowReddot(hardRed) 
        else
            self.BtnHard:ShowReddot(false)
            self.BtnNormal:ShowReddot(false)
        end
    -- 隐藏模式下
    elseif self.CurDiff == XDataCenter.FubenManager.DifficultHard then
        if normalChapterId then
            local normalRed = XRedPointConditionShortStoryChapterReward.Check(normalChapterId)
            self.BtnHard:ShowReddot(not isNormal and normalRed)
            self.BtnNormal:ShowReddot(normalRed)
        else
            self.BtnNormal:ShowReddot(false)
            self.BtnHard:ShowReddot(false)
        end
    end
end

function XUiFubenMainLineChapterDP:RefreshForChangeDiff(IsAutoMove)
    if XTool.UObjIsNil(self.GameObject) then return end

    XDataCenter.ShortStoryChapterManager.SetCurDifficult(self.CurDiff)
    local chapterId = XFubenShortStoryChapterConfigs.GetChapterIdByDifficultAndOrderId(self.CurDiff, self.OrderId)

    self:UpdateCurChapter(chapterId)
    if IsAutoMove then
        self:StageLevelChangeAutoMove()
    end
    self:PlayAnimation("AnimEnable2")
end

function XUiFubenMainLineChapterDP:SetPanelBottomActive(isActive)
    local panelParent = self.IsExploreMod and self.ExPanel or self.NorPanel
    self.PanelBottom.gameObject:SetActiveEx(isActive)
    self.PanelExploreBottom.GameObject:SetActiveEx(isActive and self.IsExploreMod and not self.IsOnZhouMu)
    self.PanelBottom.transform:SetParent(panelParent, false)
    self.PanelBottom.transform.localPosition = CS.UnityEngine.Vector3.zero
    self.FubenEx.gameObject:SetActiveEx(self.IsExploreMod)
end

function XUiFubenMainLineChapterDP:UpdateCurChapter(chapterId)
    if self.IsOnZhouMu then
        -- 切换到周目模式
        self:OnBtnSwitch1MultipleWeeksClick()
        return
    end

    if not chapterId then
        return
    end

    -- 不判断是不是隐藏关卡了，都存，因为只有隐藏关在取 v1.30 新隐藏关红点规则
    XDataCenter.FubenManagerEx.SaveHideChapterIsOpen(chapterId)
    
    self.ChapterId = chapterId
    self.IsExploreMod = XFubenShortStoryChapterConfigs.CheckChapterTypeIsExplore(self.ChapterId)
    
    for _, v in pairs(self.GridChapterList) do
        v:Hide()
    end
    local data = {
        ChapterId = self.ChapterId,
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }

    data.StageList = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(self.ChapterId)
    
    local grid = self.CurChapterGrid
    local prefabName = XFubenShortStoryChapterConfigs.GetPrefabNameByChapterId(self.ChapterId)
    if self.CurChapterGridName ~= prefabName then
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end

        if self.IsExploreMod then
            grid = XUiGridExploreChapterDP.New(self, gameObject, XDataCenter.FubenManager.StageType.ShortStory)
        else
            self.AnimBeijingEnable = gameObject:FindTransform("BgQieHuan1")
            self.AnimBeijingDisable = gameObject:FindTransform("BgQieHuan2")

            local autoChangeBgArgs
            if self.AnimBeijingEnable and self.AnimBeijingDisable then

                self.RImgBg1 = gameObject:FindTransform("RImgChapterBg1"):GetComponent("CanvasGroup")
                self.RImgBg2 = gameObject:FindTransform("RImgChapterBg2"):GetComponent("CanvasGroup")

                autoChangeBgArgs = {
                    AutoChangeBgCb = function(seletBgIndex, isPlayAnim)
                        -- if autoChangeBgFlag then
                        --     self.AnimBeijingEnable:PlayTimelineAnimation()
                        -- else
                        --     if self.FirstSetBg then
                        --         self.FirstSetBg = nil
                        --         return
                        --     end
                        --     self.AnimBeijingDisable:PlayTimelineAnimation()
                        -- end
                        local selectOrder = math.abs(seletBgIndex)
                        for i = 1, #autoChangeBgArgs.StageIndexList + 1 do
                            local tempCanvasGroup = gameObject:FindTransform("RImgChapterBg"..i):GetComponent("CanvasGroup")
                            if i ~= selectOrder then
                                tempCanvasGroup.alpha = 0
                            else
                                tempCanvasGroup.alpha = 1
                            end
                        end
                        if isPlayAnim then
                            gameObject:FindTransform("BgQieHuan"..seletBgIndex):PlayTimelineAnimation()
                        end
                        -- 切换标题、剩余时间、星数进度文本颜色
                        local chapterTextColorList = XFubenShortStoryChapterConfigs.GetChapterTextColorList(self.ChapterId)
                        if chapterTextColorList then
                            local colorSixTeen = chapterTextColorList[selectOrder]
                            if colorSixTeen then
                                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixTeen) 
                                self.TxtChapter.color = color
                                self.TxtChapterName.color = color
                                self.Text_1.color = color
                                self.BtnBack:SetColor(color)
                                self.BtnMainUi:SetColor(color)
                            end
                        end

                        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiActivityBranch_SwitchBg)
                    end,
                    DatumLinePrecent = XFubenShortStoryChapterConfigs.GetDatumLinePrecentByChapterId(chapterId),
                    StageIndexList = XFubenShortStoryChapterConfigs.GetMoveStageIndexByChapterId(chapterId),
                }
            end

            grid = XUiGridStoryChapterDP.New(self, gameObject, autoChangeBgArgs)
        end
        grid.Transform:SetParent(self.PanelChapter, false)

        self.CurChapterGridColors = grid:GetColors()
        --保存星星颜色，传给XUiPanelStars与XUiGriTreasureGrade改变星星颜色
        self.StarColor = self.CurChapterGridColors.StarColor
        self.StarDisColor = self.CurChapterGridColors.StarDisColor

        self.CurChapterGridName = prefabName
        self.CurChapterGrid = grid
        self.GridChapterList[prefabName] = grid
    end

    grid:UpdateChapterGrid(data)
    grid:Show()
    self:UpdateChapterStars()

    -- if self.AnimBeijingEnable and self.AnimBeijingDisable then
    --     CS.XTool.WaitForEndOfFrame(function()
    --         local fitCondition = grid.FirstSetBg
    --         if not fitCondition then
    --             self.RImgBg1.gameObject:SetActiveEx(true)
    --             self.AnimBeijingEnable.gameObject:SetActiveEx(false)
    --             self.AnimBeijingEnable.gameObject:SetActiveEx(true)
    --             self.RImgBg1.alpha = 1
    --         else
    --             self.RImgBg2.gameObject:SetActiveEx(true)
    --             self.AnimBeijingDisable.gameObject:SetActiveEx(false)
    --             self.AnimBeijingDisable.gameObject:SetActiveEx(true)
    --             self.RImgBg2.alpha = 1
    --         end
    --     end)
    -- end
    --进入首先显示第一个bg
    if self.RImgBg1 and not grid.firstSetChangeBg then
        self.RImgBg1.gameObject:SetActiveEx(true)
        self.RImgBg1.alpha = 1
    end

    --进入初始化标题颜色
    if not grid.firstSetChangeBg then
        local chapterTextColorList = XFubenShortStoryChapterConfigs.GetChapterTextColorList(self.ChapterId)
        if chapterTextColorList then
            local colorSixteen = chapterTextColorList[1]
            if colorSixteen then
                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixteen) 
                self.TxtChapter.color = color
                self.TxtChapterName.color = color
                self.Text_1.color = color
                self.BtnBack:SetColor(color)
                self.BtnMainUi:SetColor(color)
            end
        end
      
    end

    if self.StageId then
        self:OpenStage(self.StageId)
        self.StageId = nil
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    self:UpdateChapterTxt()
    self:UpdateColor()
    self:UpdateExploreBottom()
    self:SetPanelBottomActive(true)
    self:UpdateFubenExploreItem()
    self.PanelStoryJump:Refresh(self.ChapterId, XFubenConfigs.ChapterType.ShortStory)
end

function XUiFubenMainLineChapterDP:UpdateColor()
    --章节标题
    -- self.TxtChapter.color = self.CurChapterGridColors.TxtChapterNameColor or self.OriginalColors.TxtChapterNameColor
    -- self.TxtChapterName.color = self.CurChapterGridColors.TxtChapterNameColor or self.OriginalColors.TxtChapterNameColor
    --剩余时间
    -- self.Text_1.color = self.CurChapterGridColors.TxtLeftTimeTipColor or self.OriginalColors.TxtLeftTimeTipColor
    self.TxtLeftTime.color = self.CurChapterGridColors.TxtLeftTimeColor or self.OriginalColors.TxtLeftTimeColor

    --底部栏
    self.ImageBottom.color = self.CurChapterGridColors.ImageBottomColor or self.OriginalColors.ImageBottomColor
    --底部栏左侧三角形
    self.Triangle0.color = self.CurChapterGridColors.Triangle0Color or self.OriginalColors.Triangle0Color
    self.Triangle1.color = self.CurChapterGridColors.Triangle1Color or self.OriginalColors.Triangle1Color
    self.Triangle2.color = self.CurChapterGridColors.Triangle2Color or self.OriginalColors.Triangle2Color
    self.Triangle3.color = self.CurChapterGridColors.Triangle3Color or self.OriginalColors.Triangle3Color

    --章节奖励描述的星星图标
    self.ImageLine.color = self.CurChapterGridColors.StarColor or self.OriginalColors.StarColor
    --章节奖励描述的星星数量描述
    self.TxtStarNum.color = self.CurChapterGridColors.TxtStarNumColor or self.OriginalColors.TxtStarNumColor
    --章节奖励描述的收集进度
    self.Txet.color = self.CurChapterGridColors.TxtDescrColor or self.OriginalColors.TxtDescrColor
end

function XUiFubenMainLineChapterDP:UpdateExploreBottom()
    if not self.IsExploreMod then
        return
    end
    self.CanPlayList = {}
    
    local normalChapterId = XFubenShortStoryChapterConfigs.GetChapterIdByDifficultAndOrderId(XDataCenter.FubenManager.DifficultNormal, self.OrderId)
    local hardChapterId = XFubenShortStoryChapterConfigs.GetChapterIdByDifficultAndOrderId(XDataCenter.FubenManager.DifficultHard, self.OrderId)

    self:SetCanPlayStageList(normalChapterId, XDataCenter.FubenManager.DifficultNormal)
    self:SetCanPlayStageList(hardChapterId, XDataCenter.FubenManager.DifficultHard)

    self:ReSetQuickJumpButton(normalChapterId, XDataCenter.FubenManager.DifficultNormal, self.PanelExploreBottom.BtnNormalJump)
    self:ReSetQuickJumpButton(hardChapterId, XDataCenter.FubenManager.DifficultHard, self.PanelExploreBottom.BtnHardlJump)

    if self.CurChapterGrid then
        self.CurChapterGrid:SetCanPlayList(self.CanPlayList[self.CurDiff])
    end
end

function XUiFubenMainLineChapterDP:SetCanPlayStageList(chapterId, diff)
    if not chapterId then
        return
    end 
    local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
    for index, stageId in pairs(stageIds) do
        if not self.CanPlayList[diff] then
            self.CanPlayList[diff] = {}
        end

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local IsEgg = stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG
        local exploreGroupId = XFubenShortStoryChapterConfigs.GetExploreGroupIdByChapterId(chapterId)
        local exploreInfoList = XFubenShortStoryChapterConfigs.GetExploreGroupInfoByGroupId(exploreGroupId)
        local preShowIndex = exploreInfoList[index] or {}
        local IsShow = true
        for _, idx in pairs(preShowIndex or {}) do
            local Info = XDataCenter.FubenManager.GetStageInfo(stageIds[idx])
            if not Info or not Info.Passed then
                IsShow = false
            end
        end

        if stageInfo.Unlock and IsShow then
            if not stageInfo.Passed and not IsEgg then
                table.insert(self.CanPlayList[diff], index)
            end
        end
    end
end

function XUiFubenMainLineChapterDP:ReSetQuickJumpButton(chapterId, diff, jumpButton)
    if not chapterId then  
        return                                          
    end                                                 
  
    if not self.QuickJumpBtnList[diff] then
        self.QuickJumpBtnList[diff] = {}
    end

    local canPlayList = self.CanPlayList[diff]
    local quickJumpBtnList = self.QuickJumpBtnList[diff]
    local lenght = #canPlayList
    local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
    
    for i = 1, lenght do
        local stageId = stageIds[canPlayList[i]]
        local quickJumpBtn = quickJumpBtnList[i]
        if not quickJumpBtn then
            local tempBtn = CS.UnityEngine.Object.Instantiate(jumpButton)
            tempBtn.gameObject:SetActiveEx(true)

            quickJumpBtn = XUiFubenMainLineQuickJumpBtnDP.New(tempBtn, canPlayList[i], chapterId,
                    function(index, clickStageId)
                        self:OnQuickJumpClick(diff, index)
                        XDataCenter.ShortStoryChapterManager.MarkNewJumpStageButtonEffectByStageId(clickStageId)
                        quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(false)
                    end, XDataCenter.FubenManager.StageType.ShortStory)
            quickJumpBtnList[i] = quickJumpBtn
        else
            quickJumpBtn:UpdateNode(canPlayList[i], chapterId)
            quickJumpBtn.GameObject:SetActiveEx(true)
        end

        quickJumpBtn.Transform:SetParent(self.transform, false)
        quickJumpBtn.Transform:SetParent(self.PanelExploreBottom.PanelNodeList, false)

        XDataCenter.ShortStoryChapterManager.SaveNewJumpStageButtonEffect(stageId)
        local IsHaveNew = XDataCenter.ShortStoryChapterManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(IsHaveNew)
    end

    lenght = #quickJumpBtnList
    for i = #canPlayList + 1, lenght do
        quickJumpBtnList[i].GameObject:SetActiveEx(false)
    end
end

function XUiFubenMainLineChapterDP:OnQuickJumpClick(diff, index)
    if diff ~= self.CurDiff then
        local IsLock = false
        self.IsShowDifficultPanel = true
        if diff == XDataCenter.FubenManager.DifficultNormal then
            IsLock = self:OnBtnNormalClick(false)
        elseif diff == XDataCenter.FubenManager.DifficultHard then
            IsLock = self:OnBtnHardClick(false)
        end

        if IsLock then
            self.CurChapterGrid:OnQuickJumpClick(index)
        end
    else
        self.CurChapterGrid:OnQuickJumpClick(index)
    end
end

function XUiFubenMainLineChapterDP:CheckDetailOpen()
    local childUi = self:GetCurDetailChildUi()
    return XLuaUiManager.IsUiShow(childUi)
end

function XUiFubenMainLineChapterDP:ShowStageDetail(stage)
    self.Stage = stage
    if self.IsExploreMod or self.IOnZhouMu then
        self:OpenExploreDetail()
    else
        local childUi = self:GetCurDetailChildUi()
        local enterStoryCb = handler(self, self.EnterFight)
        self:OpenOneChildUi(childUi, self, enterStoryCb)
    end
end

function XUiFubenMainLineChapterDP:OnEnterStory(stageId)
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    local childUi = self:GetCurDetailChildUi()
    local enterStoryCb = handler(self, self.EnterFight)
    self:OpenOneChildUi(childUi, self, enterStoryCb)
end

function XUiFubenMainLineChapterDP:HideStageDetail()
    if not self.Stage then
        return
    end

    local childUi = self:GetCurDetailChildUi()
    local childUiObj = self:FindChildUiObj(childUi)
    if childUiObj then
        childUiObj:Hide()
    end
end

function XUiFubenMainLineChapterDP:OnCloseStageDetail()
    if self.CurChapterGrid then
        self.CurChapterGrid:CancelSelect()
    end
end

-- 更新左下角的奖励按钮的状态
function XUiFubenMainLineChapterDP:UpdateChapterStars()
    local curStars
    local totalStars
    local received = true
    self.PanelDesc.gameObject:SetActiveEx(true)

    if self.IsOnZhouMu then
        -- 周目奖励
        self.MultipleWeeksTxet.gameObject:SetActiveEx(true)
        self.TxtDesc.gameObject:SetActiveEx(false)
        self.ImgStarIcon.gameObject:SetActiveEx(false)

        curStars, totalStars = XDataCenter.FubenZhouMuManager.GetZhouMuTaskProgress(self.ZhouMuId)
        received = XDataCenter.FubenZhouMuManager.ZhouMuTaskIsAllFinish(self.ZhouMuId)

        XRedPointManager.Check(self.RedPointZhouMuId, self.ZhouMuId)
    else
        -- 收集奖励
        curStars, totalStars = XDataCenter.ShortStoryChapterManager.GetChapterStars(self.ChapterId)
        local treasureId = XFubenShortStoryChapterConfigs.GetTreasureIdByChapterId(self.ChapterId)
        for _, v in pairs(treasureId) do
            if not XDataCenter.ShortStoryChapterManager.IsTreasureGet(v) then
                received = false
                break
            end
        end
        self.MultipleWeeksTxet.gameObject:SetActiveEx(false)
        self.TxtDesc.gameObject:SetActiveEx(true)
        self.ImgStarIcon.gameObject:SetActiveEx(true)

        XRedPointManager.Check(self.RedPointId, self.ChapterId)
    end

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curStars, totalStars)
    self.ImgLingqu.gameObject:SetActiveEx(received)
end

function XUiFubenMainLineChapterDP:OnBtnTreasureClick()
    if self:CloseStageDetail() then
        return
    end
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self.PanelTop.gameObject:SetActiveEx(true)
    self:SetPanelBottomActive(true)
    self:PlayAnimation("TreasureEnable")
end

function XUiFubenMainLineChapterDP:PcClose()
    if self.PanelTreasure.gameObject.activeSelf then
        self:OnBtnTreasureBgClick()
        return
    end
    self:Close()
end

function XUiFubenMainLineChapterDP:CloseStageDetail()
    if self:CheckDetailOpen() then
        if self.CurChapterGrid then
            self.CurChapterGrid:ScrollRectRollBack()
        end
        self:HideStageDetail()
        return true
    end
    return false
end

function XUiFubenMainLineChapterDP:OnBtnTreasureBgClick()
    self:PlayAnimation("TreasureDisable", handler(self, function()
        self.PanelTreasure.gameObject:SetActiveEx(false)
        self.PanelTop.gameObject:SetActiveEx(true)
        self:SetPanelBottomActive(true)
        self:UpdateChapterStars()
    end))
end

-- 点击切换到周目模式
function XUiFubenMainLineChapterDP:OnBtnSwitch1MultipleWeeksClick()
    self.IsOnZhouMu = true
    self.TxtCurMWNum.text = self.ZhouMuNumber

    local zhouMuChapter = XDataCenter.FubenZhouMuManager.GetZhouMuChapterData(self.ChapterMainId, true)

    for _, v in pairs(self.GridChapterList) do
        v:Hide()
    end
    local data = {
        ChapterId = zhouMuChapter,
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }
    data.StageList = XFubenZhouMuConfigs.GetZhouMuChapterStages(zhouMuChapter.Id)

    local grid = self.CurChapterGrid
    local prefabName = zhouMuChapter.PrefabName
    if self.CurChapterGridName ~= prefabName then
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end

        grid = XUiGridStoryChapterDP.New(self, gameObject, nil, true)
        grid.Transform:SetParent(self.PanelChapter, false)
        self.CurChapterGridName = prefabName
        self.CurChapterGrid = grid
        self.GridChapterList[prefabName] = grid
    end

    grid:UpdateChapterGrid(data)
    grid:Show()

    self:UpdateChapterStars()
    self:UpdateChapterTxt()
    self:SetPanelBottomActive(true)

    self.BtnSwitch1MultipleWeeks.gameObject:SetActiveEx(false)
    self.BtnSwitch2Normal.gameObject:SetActiveEx(true)
    self.PanelTopDifficult.gameObject:SetActiveEx(false)
    self.TxtCurMWNum.gameObject:SetActiveEx(true)
    self:PlayAnimation("AnimEnable2")
end

function XUiFubenMainLineChapterDP:OnBtnSwitch2NormalClidk()
    self.IsOnZhouMu = false
    self:RefreshForChangeDiff(true)
    self.BtnSwitch1MultipleWeeks.gameObject:SetActiveEx(true)
    self.BtnSwitch2Normal.gameObject:SetActiveEx(false)
    self.TxtCurMWNum.gameObject:SetActiveEx(false)
    self.PanelTopDifficult.gameObject:SetActiveEx(not self.HideDiffTog)
end

-- 初始化 treasure grade grid panel，填充数据
-- 周目奖励和进度奖励使用不同的Grid模板，用GridTreasureList、GridMultipleWeeksTaskList分别存储
function XUiFubenMainLineChapterDP:InitTreasureGrade()
    local baseItem = self.IsOnZhouMu and self.GridMultipleWeeksTask or self.GridTreasureGrade
    self.GridMultipleWeeksTask.gameObject:SetActiveEx(false)
    self.GridTreasureGrade.gameObject:SetActiveEx(false)

    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end
    for j = 1, #self.GridMultipleWeeksTaskList do
        self.GridMultipleWeeksTaskList[j].GameObject:SetActiveEx(false)
    end

    local targetList
    if self.IsOnZhouMu then
        targetList = XFubenZhouMuConfigs.GetZhouMuTasks(self.ZhouMuId)
    else
        targetList = XFubenShortStoryChapterConfigs.GetTreasureIdByChapterId(self.ChapterId)
    end
    if not targetList then
        return
    end

    local offsetValue = 260
    local gridCount = #targetList

    for i = 1, gridCount do
        local offerY = (1 - i) * offsetValue
        local grid
        if self.IsOnZhouMu then
            grid = self.GridMultipleWeeksTaskList[i]
        else
            grid = self.GridTreasureList[i]
        end
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)  -- 复制一个item
            grid = XUiGridTreasureGradeDP.New(self, item, XDataCenter.FubenManager.StageType.ShortStory)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            grid.Transform.localPosition = CS.UnityEngine.Vector3(item.transform.localPosition.x, item.transform.localPosition.y + offerY, item.transform.localPosition.z)
            if self.IsOnZhouMu then
                self.GridMultipleWeeksTaskList[i] = grid
            else
                self.GridTreasureList[i] = grid
            end
        end

        if self.IsOnZhouMu then
            grid:UpdateGradeGridTask(targetList[i])
        else
            local stars , totalStars = XDataCenter.ShortStoryChapterManager.GetChapterStars(self.ChapterId)
            grid:UpdateGradeGrid(stars, targetList[i], self.ChapterId)
        end
        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiFubenMainLineChapterDP:OnSyncStage(stageId)
    if not stageId then
        return
    end
    local stageData = XDataCenter.FubenManager.GetStageData(stageId)
    if not stageData then
        return
    end
    if stageData.PassTimesToday > 1 then
        return
    end
    if not self.CurDiff or self.CurDiff < 0 then
        return
    end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo then
        self:UpdateCurChapter(stageInfo.ChapterId)
    end

    if self.CurChapterGrid then
        if self.CurChapterGrid.IsNotPassedFightStage then
            self.IsCanGoNearestStage = true
        end
    end
end

function XUiFubenMainLineChapterDP:OnGetEvents()
    return 
    { 
        XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL
    }
end

--事件监听
function XUiFubenMainLineChapterDP:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self:OnCloseStageDetail()
    end
end

function XUiFubenMainLineChapterDP:UpdateActivityTime()
    if not XDataCenter.ShortStoryChapterManager.IsShortStoryActivityOpen() then
        self:DestroyActivityTimer()
        self.PanelActivityTime.gameObject:SetActiveEx(false)
        return
    end

    self:CreateActivityTimer()

    local curDiffHasActivity = XDataCenter.ShortStoryChapterManager.CheckDiffHasActivity(self.ChapterId)
    self.PanelActivityTime.gameObject:SetActiveEx(curDiffHasActivity)
end

function XUiFubenMainLineChapterDP:UpdateFubenExploreItem()
    self.PanelFubenExItem.gameObject:SetActiveEx(false)
end

function XUiFubenMainLineChapterDP:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.ShortStoryChapterManager.GetActivityEndTime()
    self.TxtLeftTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtLeftTime) then
            self:DestroyActivityTimer()
            return
        end

        local leftTime = endTime - time
        time = time + 1

        if leftTime >= 0 then
            self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        else
            self:DestroyActivityTimer()
            XDataCenter.ShortStoryChapterManager.OnActivityEnd()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiFubenMainLineChapterDP:DestroyActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenMainLineChapterDP:GetCurDetailChildUi()
    local stageCfg = self.Stage
    if not stageCfg then return "" end

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        return "UiStoryStageDetailDP"
    else
        return "UiFubenMainLineDetailDP"
    end
end

function XUiFubenMainLineChapterDP:GoToStage(stageId)
    if self.CurChapterGrid then
        self.CurChapterGrid:GoToStage(stageId)
    end
end

function XUiFubenMainLineChapterDP:OpenExploreDetail()
    XLuaUiManager.Open("UiFubenExploreDetail", self, self.Stage, function()
        if (self.CurChapterGrid or {}).ScaleBack and self.IsExploreMod then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
    end, XDataCenter.FubenManager.StageType.ShortStory)
end

function XUiFubenMainLineChapterDP:OnCheckExploreItemNews(count)
    self.BtnExItem:ShowReddot(count >= 0)
end

function XUiFubenMainLineChapterDP:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId then
        if self.CurChapterGrid and self.IsExploreMod then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
        XLuaUiManager.Remove("UiFubenExploreDetail")
    end
end

function XUiFubenMainLineChapterDP:OnReleaseInst()
    return { ChapterId = self.ChapterId, StageId = self.StageId, HideDiffTog = self.HideDiffTog }
end

function XUiFubenMainLineChapterDP:OnResume(data)
    self.LastData = data
end

return XUiFubenMainLineChapterDP