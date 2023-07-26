local XUiSummerEpisode = XLuaUiManager.Register(XLuaUi, "UiSummerEpisode")
local XUiSummerEpisodeChapter = require("XUi/XUiSummerEpisode/XUiSummerEpisodeChapter")
local XUiGridNewSpecialReward = require("XUi/XUiSummerEpisode/XUiGridNewSpecialReward")
function XUiSummerEpisode:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TabPool = {}
    self.CurChapterIndex = 1

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    -- self.BtnHelpCourse.CallBack = function() self:OnBtnHelpCourseClick() end
    self.HelpDataFunc = function () return self:GetHelpDataFunc() end
    self:BindHelpBtnNew(self.BtnHelpCourse, self.HelpDataFunc)
    self.BtnMatchGame.CallBack = function() self:OnBtnHMatchGameClick() end
    self.BtnTemplate.gameObject:SetActiveEx(false)
    
    self.Red.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)

    CsXUiHelper.RegisterClickEvent(self.BtnTreasure, handler(self, self.OnBtnTreasure))
    
    self.BtnTask.CallBack = function() self:OnBtnTreasure() end
end

function XUiSummerEpisode:OnStart(id, chapterId, bOpenTask)
    self.CurActivityId = id
    self.NewRewardGridList = {}

    XDataCenter.FubenSpecialTrainManager.CurActiveId = id
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(id)
    self.Chapters = self.ActivityConfig.ChapterIds
    self.ChapterConfig = {}
    for i, v in ipairs(self.Chapters) do
        if chapterId and chapterId == v then
            self.CurChapterIndex = i
        end

        local chapeter = XFubenSpecialTrainConfig.GetChapterConfigById(v)
        table.insert(self.ChapterConfig, chapeter)
    end
    
    if self.ActivityConfig.EliminateGameId == 0 then
        self.BtnMatchGame.gameObject:SetActiveEx(false)
    else
        self.BtnMatchGame.gameObject:SetActiveEx(true)
    end

    self.ChapterPanel = XUiSummerEpisodeChapter.New(self.FubenChapter, self)
    self.CurChapter = self.ChapterConfig[self.CurChapterIndex]
 
    self:SetupPanel()
    self:TryShowHelpTip()

    if bOpenTask and bOpenTask > 0 then
        self:OnBtnTreasure()
    end
end

--设置面板
function XUiSummerEpisode:SetupPanel()
    self:SetupTitle()
    self:SetupChapter()
    self:SetupEliminateGame()
end

--弹出帮助
function XUiSummerEpisode:TryShowHelpTip()
    local value = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainPrefs(self.CurActivityId, self.CurChapter.Id)
    if value == 0 then
        XUiManager.ShowHelpTipNew(self.HelpDataFunc)
        XDataCenter.FubenSpecialTrainManager.SaveSpecialTrainPrefs(1, self.CurActivityId, self.CurChapter.Id)
    end
end

function XUiSummerEpisode:SetupEliminateGame()
    self.Red.gameObject:SetActiveEx(false)
    
    self.TxtGame.gameObject:SetActiveEx(false)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EliminateGame) then
        return
    end

    local id = self.ActivityConfig.EliminateGameId
    if XDataCenter.EliminateGameManager.CheckTimeOut(id) then
        return
    end

    XDataCenter.EliminateGameManager.TryGetEliminateGameData(id, function()
        local gameData = XDataCenter.EliminateGameManager.GetEliminateGameData(id)

        local totalRewardCount = #gameData.Rewards
        local finish = #gameData.RewardIds
        self.TxtGame.text = string.format("%s/%s", finish, totalRewardCount)
        self.TxtGame.gameObject:SetActiveEx(true)
        self.Red.gameObject:SetActiveEx(XDataCenter.EliminateGameManager.CheckGameHasReward(id))
    end)
end

--设置标题
function XUiSummerEpisode:SetupTitle()
    self:SetTimer()
end

--停止计时器
function XUiSummerEpisode:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动时间倒计时
function XUiSummerEpisode:SetTimer()
    local endTimeSecond = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CS.XTextManager.GetText("ArenaOnlineLeftTimeOver")
        self:StopTimer()
        if now <= endTimeSecond then
            self.TextTime.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY))
        else
            self.TextTime.text = activeOverStr
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTimeSecond then
                self:OnActivityEnd()
                return
            end
            if now <= endTimeSecond then
                self.TextTime.text = string.format("%s", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.ACTIVITY))
            else
                self.TextTime.text = activeOverStr
            end
        end, XScheduleManager.SECOND, 0)
    end
end

--活动结束
function XUiSummerEpisode:OnActivityEnd()
    XUiManager.TipMsg(CS.XTextManager.GetText("SpecialTrainTimeOut"))
    self:StopTimer()
    self:Close()
end


function XUiSummerEpisode:OnDestroy()
    --XDataCenter.FubenSpecialTrainManager.CurActiveId = -1
end

--设置奖励
function XUiSummerEpisode:SetupReward()
    if self.ActivityConfig.PointItemId ~= 0 then
        self.PanelBottom.gameObject:SetActiveEx(false)
        self.PanelCourse.gameObject:SetActiveEx(true)
        local func = function ()
            self:SetupRewardNew()
        end
        XDataCenter.ItemManager.AddCountUpdateListener(self.ActivityConfig.PointItemId, func, self.GameObject)
        self:SetupRewardNew()
    end
    self:SetupRewardOld()
end

function XUiSummerEpisode:SetupRewardNew()
    local pointCount = XDataCenter.ItemManager.GetCount(self.ActivityConfig.PointItemId)
    self.TxtPoint.text = pointCount
    local defaultIndex
    for index, pointId in ipairs(self.ActivityConfig.PointRewardId) do
        local tmpPointCfg = XFubenSpecialTrainConfig.GetSpecialPointRewardConfig(pointId)
        local nextPointCfg = self.ActivityConfig.PointRewardId[index + 1] and XFubenSpecialTrainConfig.GetSpecialPointRewardConfig(self.ActivityConfig.PointRewardId[index + 1]) or nil
        local grid
        if not self.NewRewardGridList[index] then
            if index == 1 then
                grid = XUiGridNewSpecialReward.New(self.GridCourse, self)
                self.GridCourse.gameObject:SetActiveEx(true)
                self.GridCourse.transform:SetParent(self.PanelCourseContainer, false)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCourse)
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(self.PanelCourseContainer, false)
                grid = XUiGridNewSpecialReward.New(ui, self)
            end
            self.NewRewardGridList[index] = grid
        else
            grid = self.NewRewardGridList[index]
        end
        grid:UpdateData(tmpPointCfg, nextPointCfg, pointCount)
        if not defaultIndex and not XDataCenter.FubenSpecialTrainManager.CheckPointRewardGet(pointId) then
            defaultIndex = index
        end
    end
    -- 针对全部领取的情况处理滑动
    if not defaultIndex then
        defaultIndex = #self.ActivityConfig.PointRewardId
        local pointId = self.ActivityConfig.PointRewardId[defaultIndex]
        --如果最后一个没有被领取则不是全部被领取
        if not XDataCenter.FubenSpecialTrainManager.CheckPointRewardGet(pointId) then
            defaultIndex = nil
        end
    end

    if defaultIndex then
        self:SetSViewIndex(defaultIndex)
    end
end

function XUiSummerEpisode:SetSViewIndex(defaultIndex)
    local length = #self.ActivityConfig.PointRewardId or 0
    if defaultIndex then
        if defaultIndex <= 1 then
            defaultIndex = 0
        elseif defaultIndex >= 16 then
            defaultIndex = 1
        end

        local percentage = 0
        if length > 0 then
            percentage = (defaultIndex - 1) / length
        end
        self.SViewCourse.horizontalNormalizedPosition = percentage
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
    end
end

function XUiSummerEpisode:SetupRewardOld()
    if self.CurChapter.RewardType == XDataCenter.FubenSpecialTrainManager.RewardType.StarReward then
        local totalStars = 0
        local isRed = false
        local curStars = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainNormalChapterStar(self.CurChapter.Id)
        local starRewardList = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainNormalChapterReward(self.CurChapter.Id)

        for i, v in ipairs(starRewardList) do
            totalStars = totalStars < v.RequireStar and v.RequireStar or totalStars
            if v.IsFinish and not v.IsReward then
                isRed = true
            end
        end

        self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
        self.ImgJindu.gameObject:SetActiveEx(true)
        self.ImgLingqu.gameObject:SetActiveEx(totalStars <= curStars and (not isRed))
        self.ImgRedProgress.gameObject:SetActiveEx(isRed)

        self.MultiyPlayerNum.gameObject:SetActiveEx(false)
        self.SinglePlayerNum.gameObject:SetActiveEx(true)

        self.TxtSinglePlayerFinishNum.text = string.format("%s<size=30>/%s</size>", curStars, totalStars)
        --    self.TxtSinglePlayerTotalNum.text = "/" .. tostring(totalStars)
    elseif self.CurChapter.RewardType == XDataCenter.FubenSpecialTrainManager.RewardType.Task then
        local isRed = false
        local tasks = XDataCenter.FubenSpecialTrainManager.GetSpecialTrainChapterTask(self.CurChapter.Id)
        local finishCount = 0
        local achievedCount = 0

        for i, v in ipairs(tasks) do
            local task = XDataCenter.TaskManager.GetTaskDataById(v)
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                achievedCount = achievedCount + 1
                isRed = true
            end

            if task.State == XDataCenter.TaskManager.TaskState.Finish then
                finishCount = finishCount + 1
            end
        end

        local taskCount = #tasks

        self.ImgJindu.fillAmount = taskCount > 0 and (finishCount + achievedCount) / taskCount or 0
        self.ImgLingqu.gameObject:SetActiveEx(taskCount == finishCount)
        self.ImgRedProgress.gameObject:SetActiveEx(isRed)
        
        self.TaskRed.gameObject:SetActiveEx(isRed)

        self.MultiyPlayerNum.gameObject:SetActiveEx(true)
        self.SinglePlayerNum.gameObject:SetActiveEx(false)

        self.TxtMultiyPlayerFinishNum.text = tostring(finishCount)
        self.TxtMultiyPlayerTotalNum.text = tostring(taskCount)
    end
end



--设置章节
function XUiSummerEpisode:SetupChapter()
    if not self.ChapterConfig then
        return
    end

    --self.HelpIds = {}
    --小型缓冲池
    if self.BtnTabList and #self.BtnTabList then
        for i, v in ipairs(self.BtnTabList) do
            table.insert(self.TabPool, v)
            v.gameObject:SetActive(false)
        end
    end

    self.BtnTabList = {}
    local chapterCount = 0

    for i, v in ipairs(self.ChapterConfig) do
        if not self.TabPool or #self.TabPool <= 0 then
            local go = CS.UnityEngine.GameObject.Instantiate(self.BtnTemplate.gameObject)
            go.transform:SetParent(self.PanelTab.transform, false)
            local btn = go:GetComponent("XUiButton")
            table.insert(self.TabPool, btn)
        end

        local tab = table.remove(self.TabPool, 1)
        tab.gameObject:SetActive(true)
        table.insert(self.BtnTabList, tab)

        tab:SetSprite(v.TabImage)
        tab:SetNameByGroup(0, v.Name)
        tab:SetNameByGroup(1, v.SecondName)
        
        chapterCount = chapterCount + 1
    end

    -- 初始化按钮
    self.PanelTab:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)
    self.PanelTab:SelectIndex(self.CurChapterIndex)

    self.PanelTab.gameObject:SetActiveEx(chapterCount > 1)

end

function XUiSummerEpisode:OnBtnTabListClick(index)
    if self.CurChapterIndex == index then
        return
    end

    if XDataCenter.RoomManager.Matching then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, function() self.PanelTab:SelectIndex(self.CurChapterIndex) end, function()
            XDataCenter.RoomManager.CancelMatch(function()
                self:ChangeChapter(index)
            end)
        end)
    else
        self:ChangeChapter(index)
    end
end

function XUiSummerEpisode:ChangeChapter(index)
    self.CurChapterIndex = index
    self.CurChapter = self.ChapterConfig[self.CurChapterIndex]
    self:SetupChapterStage()

    self:TryShowHelpTip()

    self:PlayAnimation("AnimStartEnable", function()
        XLuaUiManager.SetMask(false)
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

--设置关卡
function XUiSummerEpisode:SetupChapterStage()
    if not self.CurChapter then
        return
    end

    self:SwitchChapterBg()
    self:SetupReward()
    self.ChapterPanel:SetupChapterStage(self.CurChapter)
end

--切换背景
function XUiSummerEpisode:SwitchChapterBg()
    local icon = self.CurChapter.BgIcon
    self.Background:SetRawImage(icon)
end


function XUiSummerEpisode:OnEnable()
    if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(self.CurActivityId, true) then
        XLuaUiManager.RunMain()
        return
    end

    self:SetupChapterStage()
    self:SetupEliminateGame()
    self:SetTimer()

    self:PlayAnimation("AnimStartEnable", function()
        XLuaUiManager.SetMask(false)
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

function XUiSummerEpisode:OnDisable()
    self:StopTimer()
end

function XUiSummerEpisode:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL then
        self.StageDetailOpen = false
        self.ChildUi = nil
        -- self.PanelAsset.gameObject:SetActiveEx(true)
    elseif evt == XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD or evt == XEventId.EVENT_TASK_SYNC then
        self:SetupReward()
    end
end

function XUiSummerEpisode:OnGetEvents()
    return { XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL, XEventId.EVENT_FUBEN_SPECIAL_TRAIN_ACTIVITY_CHANGE, XEventId.EVENT_FUBEN_SPECIAL_TRAIN_REWARD, XEventId.EVENT_TASK_SYNC }
end

function XUiSummerEpisode:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSummerEpisode:OnBtnBackClick()
    if XDataCenter.RoomManager.Matching then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.CancelMatch(function()
                self:Close()
            end)
        end)
    else
        self:Close()
    end
end

-- 获取教程数据函数
function XUiSummerEpisode:GetHelpDataFunc()
    self.ChapterPanel:CancelSelect()

    local helpIds = {}
    for _, var in ipairs(self.CurChapter.HelpId) do
        table.insert(helpIds, var)
    end

    if not helpIds then
        return
    end

    local helpConfigs = {}
    for i = 1, #helpIds do
        helpConfigs[i] = XHelpCourseConfig.GetHelpCourseTemplateById(helpIds[i])
    end

    return helpConfigs
end

--打开小游戏
function XUiSummerEpisode:OnBtnHMatchGameClick()
    if XDataCenter.RoomManager.Matching then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RoomManager.CancelMatch(function()
                self:OpenMatchGame()
            end)
        end)
    else
        self:OpenMatchGame()
    end
end

function XUiSummerEpisode:OpenMatchGame()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EliminateGame) then
        return
    end

    self.ChapterPanel:CancelSelect()

    local id = self.ActivityConfig.EliminateGameId
    if XDataCenter.EliminateGameManager.CheckTimeOut(id, true) then
        return
    end
    XDataCenter.EliminateGameManager.TryGetEliminateGameData(id, function()
        XLuaUiManager.Open("UiSummerMatch", self.ActivityConfig.EliminateGameId)
    end)
end

--打开关卡详情
function XUiSummerEpisode:OpenStageDetail(stage)
    if not stage then
        return
    end

    local childUi

    if stage.IsMultiplayer then
        childUi = "UiSummerOnlineSection"
    else
        childUi = "UiSummerStageDetail"
    end


    -- if self.StageDetailOpen and childUi == self.ChildUi then
    --     return
    -- end
    self.StageDetailOpen = true

    self.ChildUi = childUi

    self.Stage = stage

    self:OpenOneChildUi(self.ChildUi, self, stage)

    --self.PanelAsset.gameObject:SetActiveEx(false)
end

--关闭关卡详情
function XUiSummerEpisode:CloseStageDetail()
    if self.StageDetailOpen and self.ChildUi then
        self:CloseChildUi(self.ChildUi)
        self.StageDetailOpen = false
        self.ChildUi = nil

        --self.PanelAsset.gameObject:SetActiveEx(true)
    end
end

--打开任务或者任务
function XUiSummerEpisode:OnBtnTreasure()
    self.ChapterPanel:CancelSelect()
    if self.CurChapter.RewardType == XDataCenter.FubenSpecialTrainManager.RewardType.StarReward then
        self:OpenOneChildUi("UiSummerStarReward", self)
    else
        self:OpenOneChildUi("UiSummerTaskReward", self)
    end
end