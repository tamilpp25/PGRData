local XUiTwoSideTowerMain = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerMain")
local XUiGridTwoSideTowerChapter = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerChapter")
function XUiTwoSideTowerMain:OnStart()
    self:Init()
    self.EventId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_TWO_SIDE_TOWER_TASK })
    self:StartTimer()
end

function XUiTwoSideTowerMain:OnEnable()
    self:Update()
end

function XUiTwoSideTowerMain:OnDestroy()
    self:StopTimer()
    XRedPointManager.RemoveRedPointEvent(self.EventId)
end

function XUiTwoSideTowerMain:Init()
    self.ChapterGridDic = {}
    local chapterDic = XDataCenter.TwoSideTowerManager.GetChapterDic()
    for chapterId, chapter in pairs(chapterDic) do
        ---@type UnityEngine.RectTransform
        local grid = CS.UnityEngine.GameObject.Instantiate(self.GridChapter, self["Chapter" .. chapterId])
        grid.anchoredPosition = CS.UnityEngine.Vector2.zero
        self.ChapterGridDic[chapterId] = XUiGridTwoSideTowerChapter.New(grid, chapterId)
        self.ChapterGridDic[chapterId]:Update()
        local desc, isOpen = chapter:GetProcess()
        local saveKey = XDataCenter.TwoSideTowerManager.GetChapterOpenRedKey(chapter:GetId())
        if isOpen and (not XSaveTool.GetData(saveKey)) then
            XSaveTool.SaveData(saveKey, 1)
        end
    end
    self.GridChapter.gameObject:SetActiveEx(false)
    self.TxtName.text = XDataCenter.TwoSideTowerManager.GetActivityName()
    self.BtnTreasure.CallBack = function() XLuaUiManager.Open("UiTwoSideTowerTask") end
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self:BindHelpBtn(self.BtnHelp, "TwoSideTower")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiTwoSideTowerMain:Update()
    for _, grid in pairs(self.ChapterGridDic) do
        grid:Update()
    end
    local now = XTime.GetServerNowTimestamp()
    local endTime = XDataCenter.TwoSideTowerManager.GetEndTime()
    if now >= endTime then
        XUiManager.TipText("ActivityAlreadyOver")
        XLuaUiManager.RunMain()
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(XDataCenter.TwoSideTowerManager.GetLimitTaskId())
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
    self.ImgJindu.fillAmount = passCount / allCount
    self.ImgLingqu.gameObject:SetActiveEx(passCount == allCount)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", passCount, allCount)
end

function XUiTwoSideTowerMain:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, XScheduleManager.SECOND)
end

function XUiTwoSideTowerMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiTwoSideTowerMain:OnCheckRedPoint(count)
    self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
end

return XUiTwoSideTowerMain
