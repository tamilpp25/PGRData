local XUiGridChapter = require("XUi/XUiFubenMainLineChapter/XUiGridChapter")
local XUiGridExploreChapter = require("XUi/XUiFubenMainLineChapter/XUiGridExploreChapter")
local XUiPanelStoryJump = require("XUi/XUiFubenMainLineChapter/XUiPanelStoryJump")
local XUiFubenExtraChapter = XLuaUiManager.Register(XLuaUi, "UiFubenMainLineChapterFw")

local FirstInTrigger = nil --首次进入的trigger

function XUiFubenExtraChapter:OnAwake()
    self:AddListener()
end

function XUiFubenExtraChapter:OnStart(chapter, stageId, hideDiffTog)
    FirstInTrigger = true
    self.UnderBg = self.Transform:Find("SafeAreaContentPane/ImageUnder")
    self.SafeAreaContentPane = self.Transform:Find("SafeAreaContentPane")
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    if self.LastData then
        self.Chapter = self.LastData.Chapter or chapter
        self.StageId = self.LastData.StageId or stageId
        self.HideDiffTog = self.LastData.HideDiffTog or hideDiffTog
        self.LastData = nil
    else
        self.Chapter = chapter
        self.StageId = stageId
        self.HideDiffTog = hideDiffTog
    end
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
    self.CurDiff = self.Chapter.Difficult
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.ImgRedProgress.gameObject:SetActiveEx(false)
    self.ExtraChapterId = self.Chapter.ChapterId
    self.IsExploreMod = XDataCenter.ExtraChapterManager.CheckChapterTypeIsExplore(self.Chapter)

    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(self.Chapter.ChapterId)
    self.ChapterMainId = (chapterInfo or {}).ChapterMainId or 0
    self.ZhouMuId = XFubenExtraChapterConfigs.GetZhouMuId(self.ChapterMainId)

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
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_EXTRA_TREASURE }, self.Chapter.ChapterId, false)
    self.RedPointZhouMuId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_ZHOUMU_TASK }, self.ZhouMuId, false)

    XRedPointManager.AddRedPointEvent(self.BtnExItem, self.OnCheckExploreItemNews, self, { XRedPointConditions.Types.CONDITION_EXTRA_EXPLORE_ITEM_GET }, self.ExtraChapterId)

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

function XUiFubenExtraChapter:OnEnable()
    -- 是否显示周目挑战按钮
    self.ZhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(self.ZhouMuId)
    self.PanelMultipleWeeksInfo.gameObject:SetActiveEx(self.ZhouMuNumber ~= 0)

    if self.GridChapterList then
        for _, v in pairs(self.GridChapterList) do
            v:OnEnable()
        end
    end

    -- 策划说这个章节特殊处理，以后不会更新外篇。这个章节不显示难度toggle，（极低暗流不显示隐藏）
    self.PanelTopDifficult.gameObject:SetActiveEx(self.Chapter.ChapterId ~= XDataCenter.ExtraChapterManager.ExGetSpecialHideChapterId())

    self:UpdateDifficultToggles()
    self:UpdateCurChapter(self.Chapter)

    self:GoToLastPassStage()
end

function XUiFubenExtraChapter:OnDisable()
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

function XUiFubenExtraChapter:OnDestroy()
    self:DestroyActivityTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
end

function XUiFubenExtraChapter:InitPanelBottom()
    self.PanelExploreBottom.Transform = self.PanelExploreBottomObj.transform
    self.PanelExploreBottom.GameObject = self.PanelExploreBottomObj.gameObject
    XTool.InitUiObject(self.PanelExploreBottom)

    self.PanelExploreBottom.BtnNormalJump.gameObject:SetActiveEx(false)
    self.PanelExploreBottom.BtnHardlJump.gameObject:SetActiveEx(false)
end

function XUiFubenExtraChapter:InitPanelStoryJump()
    ---@type XUiPanelStoryJump
    self.PanelStoryJump = XUiPanelStoryJump.New(self.PanelStoryJumpBottom, self)
end

function XUiFubenExtraChapter:GoToLastPassStage()
    if self.CurChapterGrid then
        if self.IsExploreMod then
            if self.IsCanGoNearestStage or not self.Opened then
                self.CurChapterGrid:GoToNearestStage(self.LastStageIndex[self.CurDiff])
                self.Opened = true
                self.IsCanGoNearestStage = false
            end
        else
            if not self.Opened then
                local lastPassStageId = XDataCenter.ExtraChapterManager.GetLastPassStage(self.Chapter.ChapterId)
                self.CurChapterGrid:GoToStage(lastPassStageId)
                self.Opened = true
            end
        end
    end
end

function XUiFubenExtraChapter:StageLevelChangeAutoMove()
    if self.CurChapterGrid then
        if self.IsExploreMod then
            self.CurChapterGrid:GoToNearestStage(self.LastStageIndex[self.CurDiff])
        else
            local lastPassStageId = XDataCenter.ExtraChapterManager.GetLastPassStage(self.Chapter.ChapterId)
            self.CurChapterGrid:GoToStage(lastPassStageId)
        end
    end
end

-- 打开关卡详情
function XUiFubenExtraChapter:OpenStage(stageId, needRefreshChapter)
    local orderId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    orderId = stageInfo.OrderId
    self.CurDiff = stageInfo.Difficult
    XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurDiff)

    self:UpdateDifficultToggles()

    if needRefreshChapter then
        local chapter = self:GetChapterCfgByStageId(stageId)
        self:UpdateCurChapter(chapter)
    end
    self.CurChapterGrid:ClickStageGridByIndex(orderId)
end

function XUiFubenExtraChapter:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end
    if XTool.USENEWBATTLEROOM then
        XLuaUiManager.Open("UiBattleRoleRoom", stage.StageId)
    else
        XLuaUiManager.Open("UiNewRoomSingle", stage.StageId)
    end
end

-- 是否显示红点
function XUiFubenExtraChapter:OnCheckRewards(count, chapterId)
    if self.IsOnZhouMu then
        if self.ImgRedProgress and chapterId == self.ZhouMuId then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    else
        if self.ImgRedProgress and chapterId == self.Chapter.ChapterId then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    end
end

function XUiFubenExtraChapter:AddListener()
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
function XUiFubenExtraChapter:OnBtnCloseDetailClick()
    self:OnCloseStageDetail()
end

function XUiFubenExtraChapter:OnBtnCloseDifficultClick()
    self:UpdateDifficultToggles()
end

function XUiFubenExtraChapter:OnScrollbarClick()

end

function XUiFubenExtraChapter:OnBtnExItemClick()
    XLuaUiManager.Open("UiFubenExItemTip", self)
end

function XUiFubenExtraChapter:OnBtnBackClick()
    if self:CloseStageDetail() then
        return
    end
    self:Close()
end

function XUiFubenExtraChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--[[function XUiFubenExtraChapter:OpenDifficultPanel()

end]]
function XUiFubenExtraChapter:OnBtnNormalClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultNormal then
            local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultNormal, self.Chapter.OrderId)
            if not (chapterInfo and chapterInfo.Unlock) then
                XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage), XUiManager.UiTipType.Wrong)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultNormal
            XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurDiff)
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenExtraChapter:OnBtnHardClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultHard then
            -- 检查困难开启
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
                return false
            end

            -- 检查主线副本活动
            local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultHard, self.Chapter.OrderId)
            if chapterInfo.IsActivity then
                local chapterId = XDataCenter.ExtraChapterManager.GetChapterIdByChapterExtraId(chapterInfo.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local ret, desc = XDataCenter.ExtraChapterManager.CheckActivityCondition(chapterId)
                if not ret then
                    XUiManager.TipMsg(desc, XUiManager.UiTipType.Wrong)
                    return false
                end
            end
            -- 检查困难这个章节解锁
            if not chapterInfo or not chapterInfo.IsOpen then
                local chapterId = XDataCenter.ExtraChapterManager.GetChapterIdByChapterExtraId(chapterInfo.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local ret, desc = XDataCenter.ExtraChapterManager.CheckOpenCondition(chapterId)
                if not ret then
                    XUiManager.TipError(desc)
                    return false
                end
                local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
                XUiManager.TipMsg(tipMsg)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultHard
            XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurDiff)
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenExtraChapter:UpdateDifficultToggles(showAll)
    if showAll then
        self:SetBtnTogleActive(true, true, true)
        self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    else
        if self.CurDiff == XDataCenter.FubenManager.DifficultNormal then
            self:SetBtnTogleActive(true, false, false)
            self.BtnNormal.transform:SetAsFirstSibling()
        elseif self.CurDiff == XDataCenter.FubenManager.DifficultHard then
            self:SetBtnTogleActive(false, true, false)
            self.BtnHard.transform:SetAsFirstSibling()
        else
            self:SetBtnTogleActive(false, false, true)
        end
        self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    end
    self.IsShowDifficultPanel = showAll
    --progress
    local pageDatas = XDataCenter.ExtraChapterManager.GetChapterExtraCfgs(self.CurDiff)
    local chapterIds = {}
    for _, v in pairs(pageDatas) do
        if v.OrderId == self.Chapter.OrderId then
            chapterIds = v.ChapterId
            break
        end
    end
    if chapterIds then
        self.TxtNormalProgress.text = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterIds[1])
        self.TxtHardProgress.text = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterIds[2])
    end
    -- 抢先体验活动倒计时
    self:UpdateActivityTime()
end

function XUiFubenExtraChapter:UpdateChapterTxt()
    local extraTitle = self.Chapter.StageTitle
    self.TxtChapter.text = (extraTitle or "")
    self.TxtChapterName.text = self.Chapter.ChapterEn
end

function XUiFubenExtraChapter:SetBtnTogleActive(isNormal, isHard)
    self.BtnNormal.gameObject:SetActiveEx(isNormal)

    self.BtnHard.gameObject:SetActiveEx(isHard)
    if isHard then
        local hardOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)
        local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultHard, self.Chapter.OrderId)
        hardOpen = hardOpen and chapterInfo and chapterInfo.IsOpen
        self.PanelHardOn.gameObject:SetActiveEx(hardOpen)
        self.PanelHardOff.gameObject:SetActiveEx(not hardOpen)
    end

    -- 刷新蓝点 redpoint
    -- 普通剧情下
    -- progress
    local pageDatas = XDataCenter.ExtraChapterManager.GetChapterExtraCfgs(self.CurDiff)
    local chapterIds = {}
    for _, v in pairs(pageDatas) do
        if v.OrderId == self.Chapter.OrderId then
            chapterIds = v.ChapterId
            break
        end
    end
    local normalChapterId = chapterIds[1]
    local hideChapterId = chapterIds[2]
    if self.CurDiff == XDataCenter.FubenManager.DifficultNormal then
        if hideChapterId then
            local viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(self.Chapter.ChapterId, XDataCenter.FubenManager.DifficultHard)
            local isUnFinAndUnEnter = XDataCenter.FubenManagerEx.CheckHideChapterRedPoint(viewModel) --v1.30 新入口红点规则，未完成隐藏且没点击过
            local hardRed = XRedPointConditionExtraChapterReward.Check(hideChapterId) or isUnFinAndUnEnter
            self.BtnNormal:ShowReddot(not isHard and hardRed)
            self.BtnHard:ShowReddot(hardRed) 
        else
            self.BtnHard:ShowReddot(false)
            self.BtnNormal:ShowReddot(false)
        end
    -- 隐藏模式下
    elseif self.CurDiff == XDataCenter.FubenManager.DifficultHard then
        if normalChapterId then
            local normalRed = XRedPointConditionExtraChapterReward.Check(normalChapterId)
            self.BtnHard:ShowReddot(not isNormal and normalRed)
            self.BtnNormal:ShowReddot(normalRed)
        else
            self.BtnNormal:ShowReddot(false)
            self.BtnHard:ShowReddot(false)
        end
    end
end

function XUiFubenExtraChapter:RefreshForChangeDiff(IsAutoMove)
    if XTool.UObjIsNil(self.GameObject) then return end

    XDataCenter.ExtraChapterManager.SetCurDifficult(self.CurDiff)
    local chapterList = XDataCenter.ExtraChapterManager.GetChapterList(self.CurDiff)
    local chapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterList[self.Chapter.OrderId])

    self:UpdateCurChapter(chapter)
    if IsAutoMove then
        self:StageLevelChangeAutoMove()
    end
    self:PlayAnimation("AnimEnable2")
end

function XUiFubenExtraChapter:SetPanelBottomActive(isActive)
    local panelParent = self.IsExploreMod and self.ExPanel or self.NorPanel
    self.PanelBottom.gameObject:SetActiveEx(isActive)
    self.PanelExploreBottom.GameObject:SetActiveEx(isActive and self.IsExploreMod and not self.IsOnZhouMu)
    self.PanelBottom.transform:SetParent(panelParent, false)
    self.PanelBottom.transform.localPosition = CS.UnityEngine.Vector3.zero
    self.FubenEx.gameObject:SetActiveEx(self.IsExploreMod)
end

function XUiFubenExtraChapter:UpdateCurChapter(chapter)
    if self.IsOnZhouMu then
        -- 切换到周目模式
        self:OnBtnSwitch1MultipleWeeksClick()
        return
    end

    if not chapter then
        return
    end

    XDataCenter.FubenManagerEx.SaveHideChapterIsOpen(chapter.ChapterId)

    self.Chapter = chapter
    self.IsExploreMod = XDataCenter.ExtraChapterManager.CheckChapterTypeIsExplore(self.Chapter)
    self.ExtraChapterId = self.Chapter.ChapterId
    for _, v in pairs(self.GridChapterList) do
        v:Hide()
    end
    local data = {
        Chapter = self.Chapter,
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }

    data.StageList = self.Chapter.StageId

    local chapterId = self.Chapter.ChapterId
    local grid = self.CurChapterGrid
    local prefabName = self.Chapter.PrefabName
    if self.CurChapterGridName ~= prefabName then
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end

        if self.IsExploreMod then
            grid = XUiGridExploreChapter.New(self, gameObject, XDataCenter.FubenManager.StageType.ExtraChapter)
        else
            self.AnimBeijingEnable = gameObject:FindTransform("BgQieHuan1")
            self.AnimBeijingDisable = gameObject:FindTransform("BgQieHuan2")

            local autoChangeBgArgs
            if self.AnimBeijingEnable and self.AnimBeijingDisable then

                self.RImgBg1 = gameObject:FindTransform("RImgChapterBg1"):GetComponent("CanvasGroup")
                self.RImgBg2 = gameObject:FindTransform("RImgChapterBg2"):GetComponent("CanvasGroup")

                autoChangeBgArgs = {
                    AutoChangeBgCb = function(seletBgIndex, isPlayAnim)
                        
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
                        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiActivityBranch_SwitchBg)
                    end,
                    DatumLinePrecent = XDataCenter.ExtraChapterManager.GetAutoChangeBgDatumLinePrecent(chapterId),
                    StageIndexList = XDataCenter.ExtraChapterManager.GetAutoChangeBgStageIndex(chapterId),
                }
            end

            grid = XUiGridChapter.New(self, gameObject, autoChangeBgArgs)
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

    if self.AnimBeijingEnable and self.AnimBeijingDisable then
        -- CS.XTool.WaitForEndOfFrame(function()
        --     local fitCondition = grid.FirstSetBg
        --     if fitCondition then
        --         self.RImgBg1.gameObject:SetActiveEx(true)
        --         self.AnimBeijingEnable.gameObject:SetActiveEx(false)
        --         self.AnimBeijingEnable.gameObject:SetActiveEx(true)
        --         self.RImgBg1.alpha = 1
        --     else
        --         self.RImgBg2.gameObject:SetActiveEx(true)
        --         self.AnimBeijingDisable.gameObject:SetActiveEx(false)
        --         self.AnimBeijingDisable.gameObject:SetActiveEx(true)
        --         self.RImgBg2.alpha = 1
        --     end
        -- end)
    end
    
    --进入首先显示第一个bg
    if self.RImgBg1 and FirstInTrigger then
        FirstInTrigger = nil
        self.RImgBg1.gameObject:SetActiveEx(true)
        self.RImgBg1.alpha = 1
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
    self.PanelStoryJump:Refresh(self.Chapter.ChapterId, XFubenConfigs.ChapterType.ExtralChapter)
end

function XUiFubenExtraChapter:UpdateColor()
    --章节标题
    self.TxtChapter.color = self.CurChapterGridColors.TxtChapterNameColor or self.OriginalColors.TxtChapterNameColor
    self.TxtChapterName.color = self.CurChapterGridColors.TxtChapterNameColor or self.OriginalColors.TxtChapterNameColor
    --剩余时间
    self.Text_1.color = self.CurChapterGridColors.TxtLeftTimeTipColor or self.OriginalColors.TxtLeftTimeTipColor
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

function XUiFubenExtraChapter:UpdateExploreBottom()
    if not self.IsExploreMod then
        return
    end
    self.CanPlayList = {}
    self.LastStageIndex = {} --最后一次通关的关卡索引
    local chapterList = XDataCenter.ExtraChapterManager.GetChapterList(XDataCenter.FubenManager.DifficultNormal)
    local normalChapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterList[self.Chapter.OrderId])

    chapterList = XDataCenter.ExtraChapterManager.GetChapterList(XDataCenter.FubenManager.DifficultHard)
    local hardChapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterList[self.Chapter.OrderId])

    self:SetCanPlayStageList(normalChapter, XDataCenter.FubenManager.DifficultNormal)
    self:SetCanPlayStageList(hardChapter, XDataCenter.FubenManager.DifficultHard)

    self:ReSetQuickJumpButton(normalChapter, XDataCenter.FubenManager.DifficultNormal, self.PanelExploreBottom.BtnNormalJump)
    self:ReSetQuickJumpButton(hardChapter, XDataCenter.FubenManager.DifficultHard, self.PanelExploreBottom.BtnHardlJump)

    if self.CurChapterGrid then
        self.CurChapterGrid:SetCanPlayList(self.CanPlayList[self.CurDiff])
    end
end

function XUiFubenExtraChapter:SetCanPlayStageList(chapter, diff)
    local lastPassStageId = XDataCenter.ExtraChapterManager.GetLastPassStage(self.Chapter.ChapterId)
    for index, stageId in pairs(chapter.StageId) do
        if not self.CanPlayList[diff] then
            self.CanPlayList[diff] = {}
        end
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local IsEgg = stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG
        local exploreInfoList = XDataCenter.ExtraChapterManager.GetExploreGroupInfoByGroupId(chapter.ExploreGroupId)
        local exploreInfo = exploreInfoList[index] or {}
        local IsShow = true
        for _, idx in pairs(exploreInfo.PreShowIndex or {}) do
            local Info = XDataCenter.FubenManager.GetStageInfo(chapter.StageId[idx])
            if not Info or not Info.Passed then
                IsShow = false
            end
        end

        if stageInfo.Unlock and IsShow then
            if not stageInfo.Passed and not IsEgg then
                table.insert(self.CanPlayList[diff], index)
            end
            if lastPassStageId == stageCfg.StageId then
                self.LastStageIndex[diff] = index
            end
        end
    end
end

function XUiFubenExtraChapter:ReSetQuickJumpButton(chapter, diff, jumpButton)
    if not self.QuickJumpBtnList[diff] then
        self.QuickJumpBtnList[diff] = {}
    end

    local canPlayList = self.CanPlayList[diff]
    local quickJumpBtnList = self.QuickJumpBtnList[diff]
    local lenght = #canPlayList

    for i = 1, lenght do
        local stageId = chapter.StageId[canPlayList[i]]
        local quickJumpBtn = quickJumpBtnList[i]
        if not quickJumpBtn then
            local tempBtn = CS.UnityEngine.Object.Instantiate(jumpButton)
            tempBtn.gameObject:SetActiveEx(true)

            quickJumpBtn = XUiFubenMainLineQuickJumpBtn.New(tempBtn, canPlayList[i], chapter,
            function(index, clickStageId)
                self:OnQuickJumpClick(diff, index)
                XDataCenter.ExtraChapterManager.MarkNewJumpStageButtonEffectByStageId(clickStageId)
                quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(false)
            end, XDataCenter.FubenManager.StageType.ExtraChapter)
            quickJumpBtnList[i] = quickJumpBtn
        else
            quickJumpBtn:UpdateNode(canPlayList[i], chapter)
            quickJumpBtn.GameObject:SetActiveEx(true)
        end

        quickJumpBtn.Transform:SetParent(self.transform, false)
        quickJumpBtn.Transform:SetParent(self.PanelExploreBottom.PanelNodeList, false)

        XDataCenter.ExtraChapterManager.SaveNewJumpStageButtonEffect(stageId)
        local IsHaveNew = XDataCenter.ExtraChapterManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(IsHaveNew)
    end

    lenght = #quickJumpBtnList
    for i = #canPlayList + 1, lenght do
        quickJumpBtnList[i].GameObject:SetActiveEx(false)
    end
end

function XUiFubenExtraChapter:OnQuickJumpClick(diff, index)
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

function XUiFubenExtraChapter:CheckDetailOpen()
    local childUi = self:GetCurDetailChildUi()
    return XLuaUiManager.IsUiShow(childUi)
end

function XUiFubenExtraChapter:ShowStageDetail(stage)
    self.Stage = stage
    if self.IsExploreMod or self.IOnZhouMu then
        self:OpenExploreDetail()
    else
        local childUi = self:GetCurDetailChildUi()
        self:OpenOneChildUi(childUi, self)
    end
end

function XUiFubenExtraChapter:OnEnterStory(stageId)
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    local childUi = self:GetCurDetailChildUi()
    self:OpenOneChildUi(childUi, self)
end

function XUiFubenExtraChapter:HideStageDetail()
    if not self.Stage then
        return
    end

    local childUi = self:GetCurDetailChildUi()
    local childUiObj = self:FindChildUiObj(childUi)
    if childUiObj then
        childUiObj:Hide()
    end
end

function XUiFubenExtraChapter:OnCloseStageDetail()
    if self.CurChapterGrid then
        self.CurChapterGrid:CancelSelect()
    end
end

-- 更新左下角的奖励按钮的状态
function XUiFubenExtraChapter:UpdateChapterStars()
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
        curStars, totalStars = XDataCenter.ExtraChapterManager.GetChapterStars(self.Chapter.ChapterId)
        local chapterTemplate = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(self.Chapter.ChapterId)
        for _, v in pairs(chapterTemplate.TreasureId) do
            if not XDataCenter.ExtraChapterManager.IsTreasureGet(v) then
                received = false
                break
            end
        end
        self.MultipleWeeksTxet.gameObject:SetActiveEx(false)
        self.TxtDesc.gameObject:SetActiveEx(true)
        self.ImgStarIcon.gameObject:SetActiveEx(true)

        XRedPointManager.Check(self.RedPointId, self.Chapter.ChapterId)
    end

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curStars, totalStars)
    self.ImgLingqu.gameObject:SetActiveEx(received)
end

function XUiFubenExtraChapter:OnBtnTreasureClick()
    if self:CloseStageDetail() then
        return
    end
    self:InitTreasureGrade()
    self:OpenTreasurePanel()
    self.PanelTop.gameObject:SetActiveEx(true)
    self:SetPanelBottomActive(true)
    self:PlayAnimation("TreasureEnable")
end

function XUiFubenExtraChapter:OpenTreasurePanel()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnTreasureBgClick")
end

function XUiFubenExtraChapter:CloseStageDetail()
    if self:CheckDetailOpen() then
        if self.CurChapterGrid then
            self.CurChapterGrid:ScrollRectRollBack()
        end
        self:HideStageDetail()
        return true
    end
    return false
end

function XUiFubenExtraChapter:OnBtnTreasureBgClick()
    self:PlayAnimation("TreasureDisable", handler(self, function()
        self:CloseTreasurePanel()
        self.PanelTop.gameObject:SetActiveEx(true)
        self:SetPanelBottomActive(true)
        self:UpdateChapterStars()
    end))
end

function XUiFubenExtraChapter:CloseTreasurePanel()
    self.PanelTreasure.gameObject:SetActiveEx(false)
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
end

-- 点击切换到周目模式
function XUiFubenExtraChapter:OnBtnSwitch1MultipleWeeksClick()
    self.IsOnZhouMu = true
    self.TxtCurMWNum.text = self.ZhouMuNumber

    local zhouMuChapter = XDataCenter.FubenZhouMuManager.GetZhouMuChapterData(self.ChapterMainId, true)

    for _, v in pairs(self.GridChapterList) do
        v:Hide()
    end
    local data = {
        Chapter = zhouMuChapter,
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

        grid = XUiGridChapter.New(self, gameObject, nil, true)
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

function XUiFubenExtraChapter:OnBtnSwitch2NormalClidk()
    self.IsOnZhouMu = false
    self:RefreshForChangeDiff(true)
    self.BtnSwitch1MultipleWeeks.gameObject:SetActiveEx(true)
    self.BtnSwitch2Normal.gameObject:SetActiveEx(false)
    self.TxtCurMWNum.gameObject:SetActiveEx(false)
    self.PanelTopDifficult.gameObject:SetActiveEx(true)
end

-- 初始化 treasure grade grid panel，填充数据
-- 周目奖励和进度奖励使用不同的Grid模板，用GridTreasureList、GridMultipleWeeksTaskList分别存储
function XUiFubenExtraChapter:InitTreasureGrade()
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
        targetList = self.Chapter.TreasureId
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
            grid = XUiGridTreasureGrade.New(self, item, XDataCenter.FubenManager.StageType.ExtraChapter)
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
            local treasureCfg = XDataCenter.ExtraChapterManager.GetTreasureCfg(targetList[i])
            local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(self.Chapter.ChapterId)
            grid:UpdateGradeGrid(chapterInfo.Stars, treasureCfg, self.Chapter.ChapterId)
        end
        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiFubenExtraChapter:OnSyncStage(stageId)
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

    local chapter = self:GetChapterCfgByStageId(stageId)
    if chapter then
        self:UpdateCurChapter(chapter)
    end

    if self.CurChapterGrid then
        if self.CurChapterGrid.IsNotPassedFightStage then
            self.IsCanGoNearestStage = true
        end
    end
end

function XUiFubenExtraChapter:GetChapterCfgByStageId(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local chapter
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
        chapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(stageInfo.ChapterId)
    else
        return
    end

    return chapter
end

function XUiFubenExtraChapter:OnGetEvents()
    return { XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, XEventId.EVENT_FUBEN_ENTERFIGHT }
end

--事件监听
function XUiFubenExtraChapter:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self:OnCloseStageDetail()
    elseif evt == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(...)
    end
end

function XUiFubenExtraChapter:UpdateActivityTime()
    if not XDataCenter.ExtraChapterManager.IsExtraActivityOpen() then
        self:DestroyActivityTimer()
        self.PanelActivityTime.gameObject:SetActiveEx(false)
        return
    end

    self:CreateActivityTimer()

    local curDiffHasActivity = XDataCenter.ExtraChapterManager.CheckDiffHasAcitivity(self.Chapter)
    self.PanelActivityTime.gameObject:SetActiveEx(curDiffHasActivity)
end

function XUiFubenExtraChapter:UpdateFubenExploreItem()
    local itemCurCount = #XDataCenter.ExtraChapterManager.GetChapterExploreItemList(self.ExtraChapterId)
    self.PanelFubenExItem.gameObject:SetActiveEx(itemCurCount > 0 and self.IsExploreMod)
end

function XUiFubenExtraChapter:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.ExtraChapterManager.GetActivityEndTime()
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
            XDataCenter.ExtraChapterManager.OnActivityEnd()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiFubenExtraChapter:DestroyActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenExtraChapter:GetCurDetailChildUi()
    local stageCfg = self.Stage
    if not stageCfg then return "" end

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        return "UiStoryStageDetailFw"
    else
        return "UiFubenMainLineDetailFw"
    end
end

function XUiFubenExtraChapter:GoToStage(stageId)
    if self.CurChapterGrid then
        self.CurChapterGrid:GoToStage(stageId)
    end
end

function XUiFubenExtraChapter:OpenExploreDetail()
    XLuaUiManager.Open("UiFubenExploreDetail", self, self.Stage, function()
        if (self.CurChapterGrid or {}).ScaleBack and self.IsExploreMod then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
    end, XDataCenter.FubenManager.StageType.ExtraChapter)
end

function XUiFubenExtraChapter:OnCheckExploreItemNews(count)
    self.BtnExItem:ShowReddot(count >= 0)
end

function XUiFubenExtraChapter:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId then
        if self.CurChapterGrid and self.IsExploreMod then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
        XLuaUiManager.Remove("UiFubenExploreDetail")
    end
end

function XUiFubenExtraChapter:OnReleaseInst()
    return { Chapter = self.Chapter, StageId = self.StageId, HideDiffTog = self.HideDiffTog }
end

function XUiFubenExtraChapter:OnResume(data)
    self.LastData = data
end