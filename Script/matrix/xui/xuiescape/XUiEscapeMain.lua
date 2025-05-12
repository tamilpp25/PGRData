local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiEscapeChapterGrid = require("XUi/XUiEscape/XUiEscapeChapterGrid")
local INTERVAL_GRID_COUNT_SET_BG = 3    --间隔多少个格子增加背景图

--大逃杀玩法主界面
local XUiEscapeMain = XLuaUiManager.Register(XLuaUi, "UiEscapeMain")

function XUiEscapeMain:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ImgBgList = {}
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitButtonCallBack()
    self:InitDynamicList()

    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))
end

function XUiEscapeMain:OnStart()
    self:InitImgBgSize()
    self:InitTimes()
end

function XUiEscapeMain:OnEnable()
    XUiEscapeMain.Super.OnEnable(self)
    self.UpdateImgBgPosSchedule = XScheduleManager.ScheduleForeverEx(handler(self, self.UpdateImgBgPos), 0, 0)
    self:Refresh()
end

function XUiEscapeMain:OnDisable()
    XUiEscapeMain.Super.OnDisable(self)
    if self.UpdateImgBgPosSchedule then
        XScheduleManager.UnSchedule(self.UpdateImgBgPosSchedule)
        self.UpdateImgBgPosSchedule = nil
    end
    self:RemoveMoveAnimaTimer()
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))
end

function XUiEscapeMain:RemoveMoveAnimaTimer()
    if self.MoveAnimaTimer then
        XScheduleManager.UnSchedule(self.MoveAnimaTimer)
        self.MoveAnimaTimer = nil
    end
end

function XUiEscapeMain:OnReleaseInst()
    return self.IsNotPlayMoveAnima
end

function XUiEscapeMain:OnResume(value)
    self.IsNotPlayMoveAnima = value
end

--更新背景位置
local LerpPosY
local LastImgBg
function XUiEscapeMain:UpdateImgBgPos()
    LastImgBg = self.ImgBgList and self.ImgBgList[#self.ImgBgList]
    if XTool.UObjIsNil(self.StageListContent) or XTool.UObjIsNil(self.PanelBg) or not self.InitStageListContentPos or XTool.UObjIsNil(LastImgBg) then
        return
    end

    LerpPosY = math.min(math.abs(LastImgBg.transform.localPosition.y), math.abs(self.StageListContent.localPosition.y - self.InitStageListContentPos.y))
    self.PanelBg.localPosition = Vector3(0, -LerpPosY, 0)
end

function XUiEscapeMain:InitImgBgSize()
    self.ImgBgRectSize = self.RImgBg:GetComponent("RectTransform").rect.size
    self.RectSize = self.Ui.GameObject:GetComponent("RectTransform").rect.size
    self.ImgBgHeightLerp = (self.ImgBgRectSize.y - self.RectSize.y) / 2 --锚点在中心
end

function XUiEscapeMain:InitTimes()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(XDataCenter.EscapeManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
            return
        end
        self:UpdateTime()
    end, nil, 0)
end

function XUiEscapeMain:InitChapterBgCount()
    self.ChapterBgCount = math.ceil(#self.ChapterGroupIdList / 3) --每隔3个章节设置一张背景
end

function XUiEscapeMain:InitDynamicList()
    self.ChapterGroupIdList = XEscapeConfigs.GetEscapeChapterGroupIdList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelStageList)
    self.DynamicTable:SetProxy(XUiEscapeChapterGrid)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetDataSource(self.ChapterGroupIdList)
    self.PanelStageContent.gameObject:SetActiveEx(false)

    self:InitChapterBgCount()
end

function XUiEscapeMain:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.PanelMission, self.OnPanelMissionClick)          --任务
    self:BindHelpBtn(self.BtnHelp, XEscapeConfigs.GetHelpKey())
end

function XUiEscapeMain:Refresh()
    self:UpdateImgBgList()
    self.DynamicTable:ReloadDataSync()
    self:CheckRedPoint()
end

function XUiEscapeMain:CheckRedPoint()
    local isShow = XDataCenter.EscapeManager.CheckTaskCanReward()
    self.PanelMission:ShowReddot(isShow)
end

function XUiEscapeMain:UpdateImgBgList()
    local imgBg
    local imgBgPath
    for index = 1, self.ChapterBgCount do
        imgBg = self.ImgBgList[index]
        imgBgPath = XEscapeConfigs.GetMainBg(index)
        if not imgBg then
            imgBg = index == 1 and self.RImgBg or XUiHelper.Instantiate(self.RImgBg, self.PanelBg)
            self.ImgBgList[index] = imgBg

            if index ~= 1 then
                imgBg.transform.localPosition = Vector3(0, self.ImgBgRectSize.y / 2 * index, 0)
            end
        end

        if imgBgPath then
            imgBg:SetRawImage(imgBgPath)
        end
    end
end

function XUiEscapeMain:UpdateTime()
    local endTime = XDataCenter.EscapeManager.GetActivityEndTime()
    local nowTimeStamp = XTime.GetServerNowTimestamp()
    local time, timeDesc = XUiHelper.GetTime(endTime - nowTimeStamp, XUiHelper.TimeFormatType.ESCAPE_ACTIVITY)
    self.TxtDay.text = XUiHelper.GetText("EscapeActivityTime", time, timeDesc)
end

function XUiEscapeMain:OnPanelMissionClick()
    XLuaUiManager.Open("UiEscapeTask")
end

function XUiEscapeMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.RootUi
        grid.GameObject.name = self.PanelStageContent.name .. index
        grid:Refresh(self.ChapterGroupIdList[index], index, index == #self.ChapterGroupIdList)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.InitStageListContentPos then
            self.InitStageListContentPos = self.StageListContent.localPosition
        end
        self:PlayMoveAnima()
    end
end

--首次打开界面，从最高点的章节，往当前挑战中或最新可挑战的章节移动的动画
function XUiEscapeMain:PlayMoveAnima()
    if self.PlayingMoveAnima or self.IsNotPlayMoveAnima then
        return
    end
    self.PlayingMoveAnima = true
    self.IsNotPlayMoveAnima = true
    XLuaUiManager.SetMask(true)

    local reloadDataIndex = self:GetReloadDataIndex()
    self.DynamicTable:ReloadDataSync(reloadDataIndex, false)
    local jumpLocalPosition = self.StageListContent.localPosition
    
    self.DynamicTable:ReloadDataSync(#self.ChapterGroupIdList, false)
    local curContentPos = self.StageListContent.localPosition
    local lerp = curContentPos - jumpLocalPosition
    local onRefresh = function(f)
        self.StageListContent.localPosition = curContentPos - lerp * f
    end
    local onFinish = function()
        XLuaUiManager.SetMask(false)
        self.PlayingMoveAnima = false
    end

    if not XTool.IsNumberValid(lerp.y) then
        onFinish()
        return
    end
    self.MoveAnimaTimer = XUiHelper.Tween(1, onRefresh, onFinish)
end

--获得动态列表定位到的格子下标
--一级：正在挑战中
--二级：当前已解锁的最高层区域
function XUiEscapeMain:GetReloadDataIndex()
    local reloadDataIndex
    local curChapterId = self.EscapeData:GetChapterId()
    local chapterOpenId = XDataCenter.EscapeManager.GetChapterOpenId()
    local chapterIdList
    for index, groupId in ipairs(self.ChapterGroupIdList) do
        chapterIdList = XEscapeConfigs.GetEscapeChapterIdListByGroupId(groupId)
        for _, chapterId in ipairs(chapterIdList) do
            if curChapterId == chapterId then
                return index
            end
            if chapterOpenId == chapterId then
                reloadDataIndex = index
            end

            if reloadDataIndex and not XTool.IsNumberValid(curChapterId) then
                return reloadDataIndex
            end
        end
    end

    return reloadDataIndex
end

function XUiEscapeMain:OnGuideStart()
    self:RemoveMoveAnimaTimer()
    XLuaUiManager.ClearMask(true)
    self.DynamicTable:ReloadDataSync(1, false)
end