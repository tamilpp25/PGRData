local XUiGridChapter = require("XUi/XUiFubenMainLineChapter/XUiGridChapter")
local XUiGridExploreChapter = require("XUi/XUiFubenMainLineChapter/XUiGridExploreChapter")
local XUiPanelStoryJump = require("XUi/XUiFubenMainLineChapter/XUiPanelStoryJump")

local XUiFubenMainLineChapter = XLuaUiManager.Register(XLuaUi, "UiFubenMainLineChapter")

function XUiFubenMainLineChapter:OnAwake()
    self:InitAutoScript()
end

function XUiFubenMainLineChapter:OnStart(chapter, stageId, hideDiffTog)
    self.UnderBg = self.Transform:Find("SafeAreaContentPane/ImageUnder")
    self.SafeAreaContentPane = self.Transform:Find("SafeAreaContentPane")
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    self.Chapter = chapter
    self.StageId = stageId
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
    self.PanelBfrtStageDetailInst = nil
    self.CurDiff = self.Chapter.Difficult or XDataCenter.FubenManager.DifficultNightmare --据点战Chapter没有难度配置
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.ImgRedProgress.gameObject:SetActiveEx(false)
    self.IsExploreMod = XDataCenter.FubenMainLineManager.CheckChapterTypeIsExplore(self.Chapter)

    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(self.Chapter.ChapterId)
    self.MainChapterId = chapterInfo and chapterInfo.ChapterMainId or 0
    self.ZhouMuId = XFubenMainLineConfigs.GetZhouMuId(self.MainChapterId)

    -- 注册红点事件
    XEventManager.AddEventListener(XEventId.EVENT_BOUNTYTASK_TASK_COMPLETE_NOTIFY, self.SetupBountyTask, self)
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_MAINLINE_TREASURE }, self.Chapter.ChapterId, false)
    self.RedPointZhouMuId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_ZHOUMU_TASK }, self.ZhouMuId, false)

    self.RedPointBfrtId = XRedPointManager.AddRedPointEvent(self.ImgRedProgressA, self.OnCheckBfrtRewards, self, { XRedPointConditions.Types.CONDITION_BFRT_CHAPTER_REWARD }, nil, false)
    self.RedPointBtnExItemId = XRedPointManager.AddRedPointEvent(self.BtnExItem, self.OnCheckExploreItemNews, self, { XRedPointConditions.Types.CONDITION_EXPLORE_ITEM_GET }, self.MainChapterId)

    -- 注册stage事件
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)

    -- 难度toggle
    if not self.HideDiffTog then
        self.IsShowDifficultPanel = false
        self:UpdateDifficultToggles()
        if XUiManager.IsHideFunc then
            self.PanelTopDifficult.gameObject:SetActiveEx(false)
        end
    else
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
    end

    -- 赏金任务
    self:InitBountyTask()
    self:SetupBountyTask()

    self:InitPanelBottom()
    self:InitPanelStoryJump()
end

function XUiFubenMainLineChapter:OnEnable()
    -- 是否显示周目挑战按钮
    self.PanelMultipleWeeksInfo.gameObject:SetActiveEx(false)
    if not self:CheckIsBfrtType() then
        self.ZhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(self.ZhouMuId)
        self.PanelMultipleWeeksInfo.gameObject:SetActiveEx(self.ZhouMuNumber ~= 0)
    end
    if self.GridChapterList then
        for _, v in pairs(self.GridChapterList) do
            v:OnEnable()
        end
    end

    -- 检查主线副本活动(如果没有隐藏章节和(异变章节、异变未解锁） 直接隐藏toggle)
    local isActivePanelTop = XDataCenter.FubenMainLineManager.CheckActivePanelTopDifficult(self.Chapter.OrderId)
    self.PanelTopDifficult.gameObject:SetActiveEx(isActivePanelTop)

    self:UpdateDifficultToggles()
    self:OnOpenInit()
    self:UpdateCurChapter(self.Chapter)

    self:SetupBountyTask()

    self:GoToLastPassStage()
    
    -- 检测是否有缓存的奖励信息
    local teleportRewardCache = XDataCenter.FubenMainLineManager.GetTeleportRewardCache(self.Chapter.ChapterId)
    if not XTool.IsTableEmpty(teleportRewardCache) then
        XLuaUiManager.Open("UiFubenTip", teleportRewardCache, XFubenConfigs.ChapterType.MainLine)
        -- 清理缓存
        XDataCenter.FubenMainLineManager.RemoveTeleportRewardCache(self.Chapter.ChapterId)
    end
end

function XUiFubenMainLineChapter:OnDisable()
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

function XUiFubenMainLineChapter:OnDestroy()
    self:DestroyActivityTimer()
    XDataCenter.FubenManager.UiFubenMainLineChapterInst = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, self.OnSyncStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYTASK_TASK_COMPLETE_NOTIFY, self.SetupBountyTask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_FIGHT_START, self.OnAutoFightStart, self)
    XRedPointManager.RemoveRedPointEvent(self.RedPointId)
    XRedPointManager.RemoveRedPointEvent(self.RedPointZhouMuId)
    XRedPointManager.RemoveRedPointEvent(self.RedPointBfrtId)
    XRedPointManager.RemoveRedPointEvent(self.RedPointBtnExItemId)
end

function XUiFubenMainLineChapter:OnOpenInit()
    XDataCenter.FubenManager.UiFubenMainLineChapterInst = self
end

function XUiFubenMainLineChapter:InitPanelBottom()
    self.PanelExploreBottom.Transform = self.PanelExploreBottomObj.transform
    self.PanelExploreBottom.GameObject = self.PanelExploreBottomObj.gameObject
    XTool.InitUiObject(self.PanelExploreBottom)

    self.PanelExploreBottom.BtnNormalJump.gameObject:SetActiveEx(false)
    self.PanelExploreBottom.BtnHardlJump.gameObject:SetActiveEx(false)
end

function XUiFubenMainLineChapter:InitPanelStoryJump()
    ---@type XUiPanelStoryJump
    self.PanelStoryJump = XUiPanelStoryJump.New(self.PanelStoryJumpBottom, self)
end

function XUiFubenMainLineChapter:GoToLastPassStage()
    if self.CurChapterGrid then

        if self.IsExploreMod then
            if self.IsCanGoNearestStage or not self.Opened then
                self.CurChapterGrid:GoToNearestStage()
                self.Opened = true
                self.IsCanGoNearestStage = false
            end
        else
            if not self.Opened then
                local lastPassStageId = XDataCenter.FubenMainLineManager.GetLastPassStage(self.Chapter.ChapterId)
                self.CurChapterGrid:GoToStage(lastPassStageId)
                self.Opened = true
            end
        end
    end
end

function XUiFubenMainLineChapter:StageLevelChangeAutoMove()
    if self.CurChapterGrid then
        if self.IsExploreMod then
            self.CurChapterGrid:GoToNearestStage()
        else
            local lastPassStageId = XDataCenter.FubenMainLineManager.GetLastPassStage(self.Chapter.ChapterId)
            self.CurChapterGrid:GoToStage(lastPassStageId)
        end
    end
end

-- 打开关卡详情
function XUiFubenMainLineChapter:OpenStage(stageId, needRefreshChapter)
    local orderId
    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
        local groupId = XDataCenter.BfrtManager.GetGroupIdByStageId(stageId)
        orderId = XDataCenter.BfrtManager.GetGroupOrderId(groupId)
        self.CurDiff = XDataCenter.FubenManager.DifficultNightmare
        XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
    else
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        orderId = stageInfo.OrderId
        self.CurDiff = stageInfo.Difficult
        XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
    end

    self:UpdateDifficultToggles()

    if needRefreshChapter then
        local chapter = self:GetChapterCfgByStageId(stageId)
        self:UpdateCurChapter(chapter)
    end
    self.CurChapterGrid:ClickStageGridByIndex(orderId)
end

function XUiFubenMainLineChapter:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end

    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stage.StageId) then
        --据点战副本类型先跳转到作战部署界面
        local groupId = XDataCenter.BfrtManager.GetGroupIdByBaseStage(stage.StageId)
        XLuaUiManager.Open("UiBfrtDeploy", groupId)
    else
        if XTool.USENEWBATTLEROOM then
            local team = nil
            local proxy = nil
            if stage.HideAction == 1 then
                team = XDataCenter.TeamManager.GetXTeamByStageId(stage.StageId)
                team:UpdateEntityIds(XTool.Clone(stage.RobotId))
                proxy = require("XUi/XUiFubenShortStory/BattleRole/XUiShortStoryBattleRoleRoom")
            end
            XLuaUiManager.Open("UiBattleRoleRoom", stage.StageId, team, proxy)
        else
            XLuaUiManager.Open("UiNewRoomSingle", stage.StageId)
        end
    end
end

-- 是否显示红点
function XUiFubenMainLineChapter:OnCheckRewards(count, chapterId)
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

-- auto
-- Automatic generation of code, forbid to edit
function XUiFubenMainLineChapter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiFubenMainLineChapter:AutoInitUi()
    self.PanelTreasure = self.Transform:Find("SafeAreaContentPane/PanelTreasure")
    self.BtnTreasureBg = self.Transform:Find("SafeAreaContentPane/PanelTreasure/BtnTreasureBg"):GetComponent("Button")
    self.PanelReward = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward")
    self.TxtTreasureTitle = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward/TxtTreasureTitle"):GetComponent("Text")
    self.PanelTreasureGrade = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward/PanelTreasureGrade")
    self.PanelGradeContent = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward/PanelTreasureGrade/Viewport/PanelGradeContent")
    self.GridTreasureGrade = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward/PanelTreasureGrade/Viewport/PanelGradeContent/GridTreasureGrade")
    self.Scrollbar = self.Transform:Find("SafeAreaContentPane/PanelTreasure/PanelReward/PanelTreasureGrade/Scrollbar"):GetComponent("Scrollbar")
    self.PanelMainlineChapter = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter")
    self.PanelChapterName = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelChapterName")
    self.TxtChapter = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelChapterName/TxtChapter"):GetComponent("Text")
    self.TxtChapterName = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelChapterName/TxtChapterName"):GetComponent("Text")
    self.Text_1 = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelInfo/PanelActivityTime/Text_1"):GetComponent("Text")
    self.PanelTopDifficult = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult")
    self.BtnNormal = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnNormal"):GetComponent("Button")
    self.PanelNormalOn = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnNormal/PanelNormalOn")
    self.PanelNormalOff = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnNormal/PanelNormalOff")
    self.BtnHard = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnHard"):GetComponent("Button")
    self.PanelHardOn = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnHard/PanelHardOn")
    self.PanelHardOff = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnHard/PanelHardOff")
    self.BtnVt = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnVt"):GetComponent("Button")
    self.PanelVtOn = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnVt/PanelVtOn")
    self.PanelVtOff = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelTopDifficult/BtnVt/PanelVtOff")
    self.PanelMoney = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney")
    self.PanelMoenyGroup = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup")
    self.PanelBountyTask = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask")
    self.PanelStart = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask/PanelStart")
    self.BtnSkip = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask/PanelStart/BtnSkip"):GetComponent("Button")
    self.TxtLevel = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask/PanelStart/TxtLevel"):GetComponent("Text")
    self.PanelComplete = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask/PanelComplete")
    self.BtnBountyTask = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelMoney/PanelMoenyGroup/PanelBountyTask/PanelComplete/BtnBountyTask"):GetComponent("Button")
    self.PanelChapter = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/PanelChapter")
    self.BtnCloseDifficult = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/BtnCloseDifficult"):GetComponent("Button")
    self.BtnCloseDetail = self.Transform:Find("SafeAreaContentPane/PanelMainlineChapter/BtnCloseDetail"):GetComponent("Button")
end

function XUiFubenMainLineChapter:AutoAddListener()
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick)
    self:RegisterClickEvent(self.Scrollbar, self.OnScrollbarClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnBountyTask, self.OnBtnBountyTaskClick)
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
    self.BtnVt.CallBack = function()
        self:OnBtnVtClick(false)
    end
    self.BtnSwitch1MultipleWeeks.CallBack = function()
        self:OnBtnSwitch1MultipleWeeksClick()
    end
    self.BtnSwitch2Normal.CallBack = function()
        self:OnBtnSwitch2NormalClidk()
    end
end
-- auto
function XUiFubenMainLineChapter:OnBtnCloseDetailClick()
    self:OnCloseStageDetail()
end

function XUiFubenMainLineChapter:OnBtnCloseDifficultClick()
    self:UpdateDifficultToggles()
end

function XUiFubenMainLineChapter:OnScrollbarClick()

end

function XUiFubenMainLineChapter:OnBtnSkipClick()

end

function XUiFubenMainLineChapter:OnBtnBountyTaskClick()

end

function XUiFubenMainLineChapter:OnBtnExItemClick()
    XLuaUiManager.Open("UiFubenExItemTip", self)
end

function XUiFubenMainLineChapter:OnBtnBackClick()
    if self:CloseStageDetail() then
        return
    end
    self:Close()
end

function XUiFubenMainLineChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenMainLineChapter:OpenDifficultPanel()

end

function XUiFubenMainLineChapter:OnBtnNormalClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultNormal then
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultNormal, self.Chapter.OrderId)
            if not (chapterInfo and chapterInfo.Unlock) then
                XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage), XUiManager.UiTipType.Wrong)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultNormal
            XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenMainLineChapter:OnBtnHardClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultHard then
            -- 检查主线副本活动
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultHard, self.Chapter.OrderId)
            if not chapterInfo then
                return false
            end

            -- 检查困难开启
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenDifficulty) then
                return false
            end

            if chapterInfo.IsActivity then
                local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterInfo.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
                if not ret then
                    XUiManager.TipMsg(desc, XUiManager.UiTipType.Wrong)
                    return false
                end
            end
            
            -- 检查困难这个章节解锁
            -- if not chapterInfo or not chapterInfo.IsOpen then
            if XDataCenter.FubenMainLineManager:ExGetChapterIsLockAndLockTip(chapterInfo.ChapterMainId, XDataCenter.FubenManager.DifficultHard) then
                local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterInfo.ChapterMainId, XDataCenter.FubenManager.DifficultHard)
                local isOpen, desc = XDataCenter.FubenMainLineManager.CheckOpenCondition(chapterId)
                if not isOpen then
                    XUiManager.TipMsg(desc)
                    return false
                end
                local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
                XUiManager.TipMsg(tipMsg)
                --XUiManager.TipMsg(CS.XTextManager.GetText("FubenNeedComplatePreChapter"), XUiManager.UiTipType.Wrong)
                return false
            end
            self.CurDiff = XDataCenter.FubenManager.DifficultHard
            XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
    return true
end

function XUiFubenMainLineChapter:OnBtnVtClick(IsAutoMove)
    if self.IsShowDifficultPanel then
        if self.CurDiff ~= XDataCenter.FubenManager.DifficultVariations then
            self.CurDiff = XDataCenter.FubenManager.DifficultVariations
            XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
            self:RefreshForChangeDiff(IsAutoMove)
        end
        self:UpdateDifficultToggles()
    else
        self:UpdateDifficultToggles(true)
    end
end

-- 点击切换到周目模式
function XUiFubenMainLineChapter:OnBtnSwitch1MultipleWeeksClick()
    self.IsOnZhouMu = true
    self.TxtCurMWNum.text = self.ZhouMuNumber
    local zhouMuChapter = XDataCenter.FubenZhouMuManager.GetZhouMuChapterData(self.MainChapterId, false)

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

    if self:CheckDetailOpen() then
        self:HideStageDetail()
    end

    grid:UpdateChapterGrid(data)
    grid:Show()

    self:UpdateChapterStars()
    self:UpdateChapterTxt()
    self:SetPanelBottomActive(true)

    self.BtnSwitch1MultipleWeeks.gameObject:SetActiveEx(false)
    self.BtnSwitch2Normal.gameObject:SetActiveEx(true)
    self.TxtCurMWNum.gameObject:SetActiveEx(true)
    self.PanelTopDifficult.gameObject:SetActiveEx(false)
    self:PlayAnimation("AnimEnable2")
end

function XUiFubenMainLineChapter:OnBtnSwitch2NormalClidk()
    self.IsOnZhouMu = false
    self:RefreshForChangeDiff(true)

    self.BtnSwitch1MultipleWeeks.gameObject:SetActiveEx(true)
    self.BtnSwitch2Normal.gameObject:SetActiveEx(false)
    self.TxtCurMWNum.gameObject:SetActiveEx(false)
    if XUiManager.IsHideFunc then
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
    else
        self.PanelTopDifficult.gameObject:SetActiveEx(true)
    end
end

function XUiFubenMainLineChapter:UpdateDifficultToggles(showAll)
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
        elseif self.CurDiff == XDataCenter.FubenManager.DifficultVariations then
            self:SetBtnTogleActive(false, false, true)
            self.BtnVt.transform:SetAsFirstSibling()
        else
            self:SetBtnTogleActive(false, false, false)
        end
        self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    end
    self.IsShowDifficultPanel = showAll
    --progress
    local pageDatas = XDataCenter.FubenMainLineManager.GetChapterMainTemplates(self.CurDiff)
    local chapterIds = {}
    for _, v in pairs(pageDatas) do
        if v.OrderId == self.Chapter.OrderId then
            chapterIds = v.ChapterId
            break
        end
    end
    self.TxtNormalProgress.text = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterIds[1])
    self.TxtHardProgress.text = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterIds[2])
    self.TxtVtProgress.text = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterIds[3])
    -- 抢先体验活动倒计时
    self:UpdateActivityTime()
end

function XUiFubenMainLineChapter:UpdateChapterTxt()
    local orderId = self.Chapter.OrderId
    self.TxtChapter.text = orderId < 10 and "0" .. orderId or orderId
    self.TxtChapterName.text = self.Chapter.ChapterEn
end

function XUiFubenMainLineChapter:SetBtnTogleActive(isNormal, isHard, isVt)
    self.BtnNormal.gameObject:SetActiveEx(isNormal)
    self.BtnHard.gameObject:SetActiveEx(isHard)
    self.BtnVt.gameObject:SetActiveEx(isVt)
    if isNormal then
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultNormal, self.Chapter.OrderId)
        local normalOpen = chapterInfo and chapterInfo.Unlock or false
        self.PanelNormalOn.gameObject:SetActiveEx(normalOpen)
        self.PanelNormalOff.gameObject:SetActiveEx(not normalOpen) 
    end
    if isHard then
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultHard, self.Chapter.OrderId)
        if not chapterInfo then
            self.BtnHard.gameObject:SetActiveEx(false)
        else
            local hardOpen = chapterInfo and chapterInfo.Unlock or false
            self.PanelHardOn.gameObject:SetActiveEx(hardOpen)
            self.PanelHardOff.gameObject:SetActiveEx(not hardOpen)
        end
    end
    if isVt then
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(XDataCenter.FubenManager.DifficultVariations, self.Chapter.OrderId)
        local normalOpen = chapterInfo and chapterInfo.Unlock or false
        self.BtnVt.gameObject:SetActiveEx(normalOpen)
    end
    -- 刷新蓝点
    -- 普通剧情下
    if self.CurDiff == XDataCenter.FubenManager.DifficultNormal then
        local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultHard)
        local hardChapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterList[self.Chapter.OrderId])
        if hardChapter then
            local viewModel = XDataCenter.FubenManagerEx.GetMainLineManager():ExGetChapterViewModelById(self.MainChapterId, XDataCenter.FubenManager.DifficultHard, self.Chapter.OrderId)
            local isUnFinAndUnEnter = XDataCenter.FubenManagerEx.CheckHideChapterRedPoint(viewModel) --v1.30 新入口红点规则，未完成隐藏且没点击过
            local hardRed = XRedPointConditionChapterReward.Check(hardChapter.ChapterId) or isUnFinAndUnEnter

            self.BtnNormal:ShowReddot(not isHard and hardRed)
            self.BtnHard:ShowReddot(hardRed) 
        else
            self.BtnHard:ShowReddot(false)
            self.BtnNormal:ShowReddot(false)
        end
    -- 隐藏模式下
    elseif self.CurDiff == XDataCenter.FubenManager.DifficultHard then
        local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultNormal)
        local normalChapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterList[self.Chapter.OrderId])
        if normalChapter then
            local normalRed = XRedPointConditionChapterReward.Check(normalChapter.ChapterId)
            self.BtnHard:ShowReddot(not isNormal and normalRed)
            self.BtnNormal:ShowReddot(normalRed)
        else
            self.BtnNormal:ShowReddot(false)
            self.BtnHard:ShowReddot(false)
        end
    end
end

function XUiFubenMainLineChapter:RefreshForChangeDiff(IsAutoMove)
    if XTool.UObjIsNil(self.GameObject) then return end
    XDataCenter.FubenMainLineManager.SetCurDifficult(self.CurDiff)
    local chapter
    if self:CheckIsBfrtType() then
        return
    else
        local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(self.CurDiff)
        chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterList[self.Chapter.OrderId])
    end

    self:UpdateCurChapter(chapter)
    if IsAutoMove then
        self:StageLevelChangeAutoMove()
    end
    self:PlayAnimation("AnimEnable2")
end

function XUiFubenMainLineChapter:SetPanelBottomActive(isActive)
    local isVariations = self.CurDiff == XDataCenter.FubenManager.DifficultVariations
    local panelParent = self.IsExploreMod and self.ExPanel or self.NorPanel
    self.PanelBottom.gameObject:SetActiveEx(isActive and not isVariations)
    self.PanelExploreBottom.GameObject:SetActiveEx(isActive and self.IsExploreMod)
    self.PanelBottom.transform:SetParent(panelParent, false)
    self.PanelBottom.transform.localPosition = CS.UnityEngine.Vector3.zero
    self.FubenEx.gameObject:SetActiveEx(self.IsExploreMod)
end

function XUiFubenMainLineChapter:UpdateCurChapter(chapter)
    if self.IsOnZhouMu then
        -- 切换到周目模式
        self:OnBtnSwitch1MultipleWeeksClick()
        return
    end

    if not chapter then
        return
    end

    -- 不判断是不是隐藏关卡了，都存，因为只有隐藏关在取 v1.30 新隐藏关红点规则
    XDataCenter.FubenManagerEx.SaveHideChapterIsOpen(chapter.ChapterId)

    self.Chapter = chapter
    self.IsExploreMod = XDataCenter.FubenMainLineManager.CheckChapterTypeIsExplore(self.Chapter)

    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(chapter.ChapterId)
    self.MainChapterId = chapterInfo and chapterInfo.ChapterMainId or 0
    for _, v in pairs(self.GridChapterList) do
        v:Hide()
    end

    local data = {
        Chapter = self.Chapter,
        HideStageCb = handler(self, self.HideStageDetail),
        ShowStageCb = handler(self, self.ShowStageDetail),
    }

    if self:CheckIsBfrtType() then
        data.StageList = XDataCenter.BfrtManager.GetBaseStageList(self.Chapter.ChapterId)
    else
        data.StageList = XDataCenter.FubenMainLineManager.GetStageList(self.Chapter.ChapterId)
    end

    local grid = self.CurChapterGrid
    local prefabName = self.Chapter.PrefabName
    if self.CurChapterGridName ~= prefabName then
        local gameObject = self.PanelChapter:LoadPrefab(prefabName)
        if gameObject == nil or not gameObject:Exist() then
            return
        end

        if self.IsExploreMod then
            grid = XUiGridExploreChapter.New(self, gameObject)
        else
            local autoChangeBgArgs
            self.bg1Trans = gameObject:FindTransform("RImgChapterBg1")
            if self.bg1Trans then
                self.RImgBg1 = self.bg1Trans:GetComponent("CanvasGroup")

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
                        -- 切换标题、剩余时间、星数进度文本颜色
                        if self.Chapter.ChapterTextColor then
                            local colorList = self.Chapter.ChapterTextColor
                            local colorSixTeen = colorList[selectOrder]
                            if colorSixTeen then
                                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixTeen) 
                                self.TxtChapter.color = color
                                self.TxtChapterName.color = color
                                self.Text_1.color = color
                            end
                        end

                        if self.Chapter.LeftTimeTextColor then
                            local colorList = self.Chapter.LeftTimeTextColor
                            local colorSixTeen = colorList[selectOrder]
                            if colorSixTeen then
                                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixTeen) 
                                self.TxtLeftTime.color = color
                            end
                        end
                
                        if self.Chapter.StarProgressTextColor then
                            local colorList = self.Chapter.StarProgressTextColor
                            local colorSixTeen = colorList[selectOrder]
                            if colorSixTeen then
                                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixTeen) 
                                self.TxtStarNum.color = color
                                self.TxtDesc.color = color
                                self.BtnBack:SetColor(color)
                                self.BtnMainUi:SetColor(color)
                            end
                        end
                        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiActivityBranch_SwitchBg)
                    end,
                    DatumLinePrecent = XDataCenter.FubenMainLineManager.GetAutoChangeBgDatumLinePrecent(chapter.ChapterId),
                    StageIndexList = XDataCenter.FubenMainLineManager.GetAutoChangeBgStageIndex(chapter.ChapterId),
                }
            end
            grid = XUiGridChapter.New(self, gameObject, autoChangeBgArgs)
        end
        grid.Transform:SetParent(self.PanelChapter, false)
        self.CurChapterGridName = prefabName
        self.CurChapterGrid = grid
        self.GridChapterList[prefabName] = grid
    end

    grid:UpdateChapterGrid(data)
    grid:Show()
    if self:CheckIsBfrtType() then
        self:UpdatePanelBfrtTask()
    else
        self:UpdateChapterStars()
    end

    if self.GridChapterList then
        for _, v in pairs(self.GridChapterList) do
            if v.PlayParallelAnime then
                v:PlayParallelAnime()
            end
        end
    end

    --进入首先显示第一个bg
    if self.RImgBg1 and not grid.firstSetChangeBg then
        self.RImgBg1.gameObject:SetActiveEx(true)
        self.RImgBg1.alpha = 1
    end

    --进入初始化标题颜色(18章特殊处理)
    if not grid.firstSetChangeBg then
        if self.Chapter.ChapterTextColor then
            local colorList = self.Chapter.ChapterTextColor
            local colorSixteen = colorList[1]
            if colorSixteen then
                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixteen) 
                self.TxtChapter.color = color
                self.TxtChapterName.color = color
                self.Text_1.color = color
            end
        end

        if self.Chapter.LeftTimeTextColor then
            local colorList = self.Chapter.LeftTimeTextColor
            local colorSixteen = colorList[1]
            if colorSixteen then
                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixteen)
                self.TxtLeftTime.color = color
            end
        end

        if self.Chapter.StarProgressTextColor then
            local colorList = self.Chapter.StarProgressTextColor
            local colorSixteen = colorList[1]
            if colorSixteen then
                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorSixteen)
                self.TxtStarNum.color = color
                self.TxtDesc.color = color
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
    self:UpdateExploreBottom()
    self:SetPanelBottomActive(true)
    self:UpdateFubenExploreItem()
    if not self:CheckIsBfrtType() then
        self.PanelStoryJump:Refresh(self.Chapter.ChapterId, XFubenConfigs.ChapterType.MainLine)
    end
end

function XUiFubenMainLineChapter:UpdateExploreBottom()
    if not self.IsExploreMod then
        return
    end
    self.CanPlayList = {}

    local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultNormal)
    local normalChapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterList[self.Chapter.OrderId])

    chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultHard)
    local hardChapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterList[self.Chapter.OrderId])

    self:SetCanPlayStageList(normalChapter, XDataCenter.FubenManager.DifficultNormal)
    self:SetCanPlayStageList(hardChapter, XDataCenter.FubenManager.DifficultHard)

    self:ReSetQuickJumpButton(normalChapter, XDataCenter.FubenManager.DifficultNormal, self.PanelExploreBottom.BtnNormalJump)
    self:ReSetQuickJumpButton(hardChapter, XDataCenter.FubenManager.DifficultHard, self.PanelExploreBottom.BtnHardlJump)

    if self.CurChapterGrid then
        self.CurChapterGrid:SetCanPlayList(self.CanPlayList[self.CurDiff])
    end
end

function XUiFubenMainLineChapter:SetCanPlayStageList(chapter, diff)
    for index, stageId in pairs(chapter.StageId) do
        if not self.CanPlayList[diff] then
            self.CanPlayList[diff] = {}
        end

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local IsEgg = stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG
        local exploreInfoList = XDataCenter.FubenMainLineManager.GetExploreGroupInfoByGroupId(chapter.ExploreGroupId)
        local exploreInfo = exploreInfoList[index] or {}
        local IsShow = true
        for _, idx in pairs(exploreInfo.PreShowIndex or {}) do
            local Info = XDataCenter.FubenManager.GetStageInfo(chapter.StageId[idx])
            if not Info or not Info.Passed then
                IsShow = IsShow and false
            end
        end

        if stageInfo.Unlock and IsShow then
            if not stageInfo.Passed and not IsEgg then
                table.insert(self.CanPlayList[diff], index)
            end
        end
    end
end

function XUiFubenMainLineChapter:ReSetQuickJumpButton(chapter, diff, jumpButton)
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
                XDataCenter.FubenMainLineManager.MarkNewJumpStageButtonEffectByStageId(clickStageId)
                quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(false)
            end)
            quickJumpBtnList[i] = quickJumpBtn
        else
            quickJumpBtn:UpdateNode(canPlayList[i], chapter)
            quickJumpBtn.GameObject:SetActiveEx(true)
        end

        quickJumpBtn.Transform:SetParent(self.transform, false)
        quickJumpBtn.Transform:SetParent(self.PanelExploreBottom.PanelNodeList, false)

        XDataCenter.FubenMainLineManager.SaveNewJumpStageButtonEffect(stageId)
        local IsHaveNew = XDataCenter.FubenMainLineManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        quickJumpBtn.Transform:GetComponent("XUiButton"):ShowTag(IsHaveNew)
    end

    lenght = #quickJumpBtnList
    for i = #canPlayList + 1, lenght do
        quickJumpBtnList[i].GameObject:SetActiveEx(false)
    end
end

function XUiFubenMainLineChapter:OnQuickJumpClick(diff, index)
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

function XUiFubenMainLineChapter:CheckDetailOpen()
    local childUi = self:GetCurDetailChildUi()
    return XLuaUiManager.IsUiShow(childUi)
end

function XUiFubenMainLineChapter:ShowStageDetail(stage)
    self.PanelMoney.gameObject:SetActiveEx(false)
    self.Stage = stage
    if self.IsExploreMod or self.IsOnZhouMu then
        self:OpenExploreDetail()
    else
        local childUi = self:GetCurDetailChildUi()
        self:OpenOneChildUi(childUi, self)
    end
end

function XUiFubenMainLineChapter:OnEnterStory(stageId)
    self.Stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    local childUi = self:GetCurDetailChildUi()
    self:OpenOneChildUi(childUi, self)
end

function XUiFubenMainLineChapter:HideStageDetail()
    if not self.Stage then
        return
    end

    local childUi = self:GetCurDetailChildUi()
    local childUiObj = self:FindChildUiObj(childUi)
    if childUiObj then
        childUiObj:Hide()
    end
end

function XUiFubenMainLineChapter:OnCloseStageDetail()
    if self.BountyInfo and #self.BountyInfo.TaskCards > 0 then
        local taskCards = self.BountyInfo.TaskCards
        for i = 1, XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT do
            if taskCards[i] and taskCards[i].Status ~= XDataCenter.BountyTaskManager.BountyTaskStatus.AcceptReward then
                self.PanelMoney.gameObject:SetActiveEx(true and not self.IsExploreMod)
            end
        end
    end
    if self.CurChapterGrid then
        self.CurChapterGrid:CancelSelect()
    end
end

function XUiFubenMainLineChapter:UpdateBfrtRewards()
    local chapterId = self.Chapter.ChapterId
    local taskId = XDataCenter.BfrtManager.GetBfrtTaskId(chapterId)
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    local rewardId = taskConfig.RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)

    self.BfrtRewardGrids = self.BfrtRewardGrids or {}
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.BfrtRewardGrids[i]
        if not grid then
            local go = i == 1 and self.GridCommonPopUp or CS.UnityEngine.Object.Instantiate(self.GridCommonPopUp)
            grid = XUiGridCommon.New(self, go)
            self.BfrtRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.Transform:SetParent(self.PanelBfrtRewrds, false)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.BfrtRewardGrids do
        self.BfrtRewardGrids[i].GameObject:SetActiveEx(false)
    end
end

function XUiFubenMainLineChapter:OnCheckBfrtRewards(count)
    self.ImgRedProgressA.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenMainLineChapter:UpdatePanelBfrtTask()
    local chapterId = self.Chapter.ChapterId
    self.ImgJindu.gameObject:SetActiveEx(false)
    self.ImgLingqu.gameObject:SetActiveEx(XDataCenter.BfrtManager.CheckAllTaskRewardHasGot(chapterId))
    self.PanelDesc.gameObject:SetActiveEx(false)
    self.PanelBfrtTask.gameObject:SetActiveEx(true)

    self:UpdateBfrtRewards()
    XRedPointManager.Check(self.RedPointBfrtId, self.Chapter.ChapterId)
end

-- 更新左下角的奖励按钮的状态
function XUiFubenMainLineChapter:UpdateChapterStars()
    local curStars
    local totalStars
    local received = true

    self.PanelBfrtTask.gameObject:SetActiveEx(false)
    
    local isVariations = self.CurDiff == XDataCenter.FubenManager.DifficultVariations
    self.PanelDesc.gameObject:SetActiveEx(not isVariations)

    if self.IsOnZhouMu then
        -- 周目奖励
        self.MultipleWeeksTxet.gameObject:SetActiveEx(true)
        self.TxtDesc.gameObject:SetActiveEx(false)
        self.ImgStarIcon.gameObject:SetActiveEx(false)

        curStars, totalStars = XDataCenter.FubenZhouMuManager.GetZhouMuTaskProgress(self.ZhouMuId)
        received = XDataCenter.FubenZhouMuManager.ZhouMuTaskIsAllFinish(self.ZhouMuId)

        XRedPointManager.Check(self.RedPointZhouMuId, self.ZhouMuId)
    else
        -- 主线收集奖励
        curStars, totalStars = XDataCenter.FubenMainLineManager.GetChapterStars(self.Chapter.ChapterId)
        local chapterTemplate = XDataCenter.FubenMainLineManager.GetChapterCfg(self.Chapter.ChapterId)

        for _, v in pairs(chapterTemplate.TreasureId or {}) do
            if not XDataCenter.FubenMainLineManager.IsTreasureGet(v) then
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

function XUiFubenMainLineChapter:OnBtnTreasureClick()
    if self:CloseStageDetail() then
        return
    end
    if self:CheckIsBfrtType() then
        local chapterId = self.Chapter.ChapterId
        if XDataCenter.BfrtManager.CheckAllTaskRewardHasGot(chapterId) then
            XUiManager.TipText("TaskAlreadyFinish")
            return
        elseif not XDataCenter.BfrtManager.CheckAnyTaskRewardCanGet(chapterId) then
            XUiManager.TipText("TaskDoNotFinish")
            return
        end

        local taskId = XDataCenter.BfrtManager.GetBfrtTaskId(chapterId)
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self:UpdatePanelBfrtTask()
        end)
    else
        self:InitTreasureGrade()
        self.PanelTreasure.gameObject:SetActiveEx(true)
        self.PanelTop.gameObject:SetActiveEx(true)
        self:SetPanelBottomActive(true)
    end
    self:PlayAnimation("TreasureEnable")
end

function XUiFubenMainLineChapter:CloseStageDetail()
    if self:CheckDetailOpen() then
        if self.CurChapterGrid then
            self.CurChapterGrid:ScrollRectRollBack()
        end
        self:HideStageDetail()
        return true
    end
    return false
end

function XUiFubenMainLineChapter:OnBtnTreasureBgClick()
    self:PlayAnimation("TreasureDisable", handler(self, function()
        self.PanelTreasure.gameObject:SetActiveEx(false)
        self.PanelTop.gameObject:SetActiveEx(true)
        self:SetPanelBottomActive(true)
        if not self:CheckIsBfrtType() then
            self:UpdateChapterStars()
        end
    end))
end

function XUiFubenMainLineChapter:PcClose()
    if self.PanelTreasure.gameObject.activeSelf then
        self:OnBtnTreasureBgClick()
        return
    end
    self:Close()
end

-- 初始化 treasure grade grid panel，填充数据
-- 周目奖励和进度奖励使用不同的Grid模板，用GridTreasureList、GridMultipleWeeksTaskList分别存储
function XUiFubenMainLineChapter:InitTreasureGrade()
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
            grid = XUiGridTreasureGrade.New(self, item)
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
            local treasureCfg = XDataCenter.FubenMainLineManager.GetTreasureCfg(targetList[i])
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(self.Chapter.ChapterId)
            grid:UpdateGradeGrid(chapterInfo.Stars, treasureCfg, self.Chapter.ChapterId)
        end

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiFubenMainLineChapter:OnSyncStage(stageId)
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

--设置任务卡
function XUiFubenMainLineChapter:InitBountyTask()
    self.TaskGrid = {}
    self.TaskGrid[1] = XUiPanelBountyTask.New(self.PanelBountyTask, self)
    self.PanelMoney.gameObject:SetActiveEx(false)

    for i = 2, XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT do
        local ui = CS.UnityEngine.Object.Instantiate(self.PanelBountyTask)
        self.TaskGrid[i] = XUiPanelBountyTask.New(ui, self)
        self.TaskGrid[i].Transform:SetParent(self.PanelMoenyGroup, false)
        self.TaskGrid[i].GameObject:SetActiveEx(false)
    end
end

--设置赏金任务标签
function XUiFubenMainLineChapter:SetupBountyTask()
    self.PanelMoney.gameObject:SetActiveEx(false)

    self.BountyInfo = XDataCenter.BountyTaskManager.GetBountyTaskInfo()
    if not self.BountyInfo or #self.BountyInfo.TaskCards <= 0 then
        self.PanelMoney.gameObject:SetActiveEx(false)
        return
    end

    local taskCards = self.BountyInfo.TaskCards
    for i = 1, XDataCenter.BountyTaskManager.MAX_BOUNTY_TASK_COUNT do
        if taskCards[i] and taskCards[i].Status ~= XDataCenter.BountyTaskManager.BountyTaskStatus.AcceptReward then
            self.TaskGrid[i]:SetupContent(taskCards[i])
            self.TaskGrid[i].GameObject:SetActiveEx(true)
            self.PanelMoney.gameObject:SetActiveEx(true and not self.IsExploreMod)

        else
            self.TaskGrid[i]:SetActiveEx(false)
        end
    end
end

function XUiFubenMainLineChapter:CheckIsBfrtType()
    return self.CurDiff and self.CurDiff == XDataCenter.FubenManager.DifficultNightmare
end

function XUiFubenMainLineChapter:GetChapterCfgByStageId(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local chapter
    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageId) then
        chapter = XDataCenter.BfrtManager.GetChapterCfg(stageInfo.ChapterId)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.Mainline then
        chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
    else
        return
    end

    return chapter
end

function XUiFubenMainLineChapter:OnGetEvents()
    return { XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, XEventId.EVENT_FUBEN_ENTERFIGHT }
end

--事件监听
function XUiFubenMainLineChapter:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self:OnCloseStageDetail()
    elseif evt == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(...)
    end
end

function XUiFubenMainLineChapter:UpdateActivityTime()
    if self:CheckIsBfrtType() or not XDataCenter.FubenMainLineManager.IsMainLineActivityOpen() then
        self:DestroyActivityTimer()
        self.PanelActivityTime.gameObject:SetActiveEx(false)
        return
    end

    self:CreateActivityTimer()

    local curDiffHasActivity = XDataCenter.FubenMainLineManager.CheckDiffHasAcitivity(self.Chapter)
    self.PanelActivityTime.gameObject:SetActiveEx(curDiffHasActivity)
end

function XUiFubenMainLineChapter:UpdateFubenExploreItem()
    local itemCurCount = #XDataCenter.FubenMainLineManager.GetChapterExploreItemList(self.MainChapterId)
    self.PanelFubenExItem.gameObject:SetActiveEx(itemCurCount > 0 and self.IsExploreMod)
end

function XUiFubenMainLineChapter:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.FubenMainLineManager.GetActivityEndTime()
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
            XDataCenter.FubenMainLineManager.OnActivityEnd()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiFubenMainLineChapter:DestroyActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenMainLineChapter:GetCurDetailChildUi()
    local stageCfg = self.Stage
    if not stageCfg then return "" end

    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stageCfg.StageId) then
        return "UiBfrtStageDetail"
    elseif stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        return "UiStoryStageDetail"
    else
        return "UiFubenMainLineDetail"
    end
end

function XUiFubenMainLineChapter:GoToStage(stageId)
    if self.CurChapterGrid then
        self.CurChapterGrid:GoToStage(stageId)
    end
end

function XUiFubenMainLineChapter:OpenExploreDetail()
    XLuaUiManager.Open("UiFubenExploreDetail", self, self.Stage, function()
        if (self.CurChapterGrid or {}).ScaleBack then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
    end)
end

function XUiFubenMainLineChapter:OnCheckExploreItemNews(count)
    self.BtnExItem:ShowReddot(count >= 0)
end

function XUiFubenMainLineChapter:OnAutoFightStart(stageId)
    if self.Stage.StageId == stageId and self.IsExploreMod then
        if self.CurChapterGrid then
            self.CurChapterGrid:ScaleBack()
        end
        self:OnCloseStageDetail()
        XLuaUiManager.Remove("UiFubenExploreDetail")
    end
end

function XUiFubenMainLineChapter:OnReleaseInst()
    return {Chapter = self.Chapter, StageId = self.StageId, HideDiffTog = self.HideDiffTog}
end

function XUiFubenMainLineChapter:OnResume(data)
    self.LastData = data
end