local XUiSummerEpisodeNew = XLuaUiManager.Register(XLuaUi, "UiSummerEpisodeNew")
local XUiGridSummerEpisodePicture = require("XUi/XUiSummerEpisode/XUiGridSummerEpisodePicture")
local HELP_KEY = "SummerEpisodeHelp"
function XUiSummerEpisodeNew:OnAwake()
    self.GameObject.transform:FindGameObject("BtnPhotograph"):SetActiveEx(false) -- 海外屏蔽自动存图
end

function XUiSummerEpisodeNew:OnStart()
    self.Lock = false
    self:InitUiView()
    self:RegisterButtonEvent()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    self.TaskRedEventId = XRedPointManager.AddRedPointEvent(self.BtnTask, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SPECIALTRAIN_RED })
end

function XUiSummerEpisodeNew:OnEnable()
    self:UpdateActivityTime()
    self:UpdateStageDetail()
    self:StartTimer()
    self.BtnMatching.gameObject:SetActiveEx(XDataCenter.RoomManager.Matching)
    self.BtnMatch.gameObject:SetActiveEx(not XDataCenter.RoomManager.Matching)
end

function XUiSummerEpisodeNew:OnDisable()
    self:StopTimer()
end

function XUiSummerEpisodeNew:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    if self.TaskRedEventId then
        XRedPointManager.RemoveRedPointEvent(self.TaskRedEventId)
    end
end

function XUiSummerEpisodeNew:OnCancelMatching()
    self.BtnMatch.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(false)
end

function XUiSummerEpisodeNew:InitUiView()
    local activityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    if not activityConfig then
        return
    end
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
    self.Chapters = activityConfig.ChapterIds
    self.CurChapter = {Id = self.Chapters[1]}
    self.TxtName.text = activityConfig.Name
    self.HelpDataFunc = function () return self:GetHelpDataFunc() end
    self:BindHelpBtnNew(self.BtnHelpCourse, self.HelpDataFunc)
    local isSave = XDataCenter.FubenSpecialTrainManager.GetSavePhotoValue()
    if isSave == true then
        self.BtnCircuit:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnCircuit:SetButtonState(CS.UiButtonState.Normal)
    end
    self:InitDynamicTable()
end

function XUiSummerEpisodeNew:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelMapList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridSummerEpisodePicture)
    self:SetupDynamicTable()
end

function XUiSummerEpisodeNew:SetupDynamicTable()
    local stages = XDataCenter.FubenSpecialTrainManager.GetPhotoStages()
    self.DynamicTable:SetDataSource(stages)
    self.DynamicTable:ReloadData(1)
end

function XUiSummerEpisodeNew:OnDynamicTableEvent(event,index,grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self.CurIndex = index
        local i = (index - 1) % #self.DynamicTable.DataSource + 1
        self.StageId = self.DynamicTable.DataSource[i]
        grid:Refresh(XDataCenter.FubenManager.GetStageIcon(self.StageId))
        self:UpdateStageDetail()
    end
end

function XUiSummerEpisodeNew:UpdateStageDetail()
    --照相特训关只有一关直接取第一章节第一关的数据作为展示
    if not self.StageId then return end
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self:PlayAnimation("TxtMapNameEnable")
    self.TxtStageDesc.text = stageConfig.Description
    self.TxtCostNum.text = stageConfig.RequireActionPoint
    self.TxtPeople.text = stageConfig.OnlinePlayerLeast
    self.TxtMapName.text = stageConfig.Name
end

function XUiSummerEpisodeNew:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        if XDataCenter.RoomManager.Matching then
            XDataCenter.RoomManager.CancelMatch(function()
                self:Close()
            end)
        else
            self:Close()
        end
    end
    self:BindHelpBtn(self.BtnHelpCourse, HELP_KEY)
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnTask.CallBack = function() self:OpenOneChildUi("UiSummerTaskReward",self)  end
    self.BtnMatch.CallBack = function() self:OnClickBtnMatch() end
    self.BtnCreateRoom.CallBack = function() self:OnClickBtnCreateRoom() end
    self.BtnCircuit.CallBack = function() self:OnClickBtnCircuit() end
    self.BtnSwitch.CallBack = function() self.DynamicTable:TweenToIndex(self.CurIndex + 1) end
    if self.BtnMatching then
        self:RegisterClickEvent(self.BtnMatching,self.OnClickBtnMatching)
    end
end
function XUiSummerEpisodeNew:OnClickBtnMatching()
    XDataCenter.RoomManager.CancelMatch(function()
        self.BtnMatch.gameObject:SetActiveEx(true)
        self.BtnMatching.gameObject:SetActiveEx(false)
    end)
end

function XUiSummerEpisodeNew:OnClickBtnMatch()
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatch.gameObject:SetActiveEx(false)
    XDataCenter.RoomManager.PhotoMatch(self.StageId,function()
        XLuaUiManager.Open("UiOnLineMatching",self.StageId)
    end)
end

function XUiSummerEpisodeNew:OnClickBtnCreateRoom()
    XDataCenter.RoomManager.PhotoCreateRoom(self.StageId)
end

function XUiSummerEpisodeNew:OnClickBtnCircuit()
    local isSave = self.BtnCircuit:GetToggleState()
    XDataCenter.FubenSpecialTrainManager.SetSavePhotoValue(isSave)
end

function XUiSummerEpisodeNew:UpdateActivityTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTimer()
        return
    end
    local now = XTime.GetServerNowTimestamp()
    local offset = self.EndTime - now
    if offset < 0 then
        offset = 0
        XUiManager.TipText("SummerEpisodeActivityEnd")
        XLuaUiManager.RunMain()
        self:StopTimer()
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiSummerEpisodeNew:StartTimer()
    if self.Timer then self:StopTimer() end
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityTime), XScheduleManager.SECOND)
end

function XUiSummerEpisodeNew:StopTimer()
    if not self.Timer then return end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

-- 获取教程数据函数
function XUiSummerEpisodeNew:GetHelpDataFunc()
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

function XUiSummerEpisodeNew:OnCheckRedPoint(count)
    self.BtnTask:ShowReddot(count >= 0)
end

return XUiSummerEpisodeNew