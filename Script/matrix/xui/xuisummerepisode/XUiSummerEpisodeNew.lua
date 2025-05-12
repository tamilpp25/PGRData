local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiSummerEpisodeNew = XLuaUiManager.Register(XLuaUi, "UiSummerEpisodeNew")
local HELP_KEY = "SummerEpisodeHelp"
function XUiSummerEpisodeNew:OnAwake()
    --2.6默认为竞争模式
    self.IsPeaceModel = false 
    self.IsRandomStage = true
end

function XUiSummerEpisodeNew:OnStart()
    self.Pos = 1
    self.MaxStageCount = 1
    self:InitUiView()
    self:RegisterButtonEvent()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    self.TaskRedEventId = XRedPointManager.AddRedPointEvent(self.BtnTask, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SPECIALTRAINPOINT_RED },nil,true)
    self.MapRedPointId=XRedPointManager.AddRedPointEvent(self.BtnMap,self.OnCheckMapRedPoint,self,{XRedPointConditions.Types.CONDITION_SPECIALTRAINMAP_RED})
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
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    if self.TaskRedEventId then
        XRedPointManager.RemoveRedPointEvent(self.TaskRedEventId)
    end
    if self.MapRedPointId then
        XRedPointManager.RemoveRedPointEvent(self.MapRedPointId)
    end
end

function XUiSummerEpisodeNew:OnCancelMatching()
    self.BtnMatch.gameObject:SetActiveEx(true)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMask.gameObject:SetActiveEx(false)
end

function XUiSummerEpisodeNew:OnBeginMatch()
    self.BtnMatch.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMask.gameObject:SetActiveEx(true)
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
    self.HelpDataFunc = function () return self:GetHelpDataFunc() end
    self:BindHelpBtnNew(self.BtnHelpCourse, self.HelpDataFunc)
    local isSave = XDataCenter.FubenSpecialTrainManager.GetSavePhotoValue()
    if isSave == true then
        self.BtnCircuit:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnCircuit:SetButtonState(CS.UiButtonState.Normal)
    end
    
    --2.6取消竞争模式
    if self.BtnPeace then
        --self.BtnPeace:SetButtonState(self.IsPeaceModel and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self.BtnPeace.gameObject:SetActiveEx(false)
    end
    
    self.StageIds = XDataCenter.FubenSpecialTrainManager.GetAllStageIdByActivityId(activityConfig.Id, true)
    self.MaxStageCount = #self.StageIds
    self:UpdateStageId()
    
end

function XUiSummerEpisodeNew:UpdateStageDetail()
    self:UpdateStageId()
    if not self.CurrentStageId then return end
    -- 当前选择的关卡是否为随机关卡
    self.IsRandomStage = XDataCenter.FubenSpecialTrainManager.CheckHasRandomStage(self.CurrentStageId)
    self.BtnCreateRoom:SetButtonState(self.IsRandomStage and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    -- 刷新关卡图片
    if not self.IsRandomStage then
        local imgPath = XDataCenter.FubenManager.GetStageIcon(self.CurrentStageId)
        self.PanelPhoto:SetRawImage(imgPath)
        self.MapName.text=XDataCenter.FubenManager.GetStageName(self.CurrentStageId)
    else
        local icon = XFubenSpecialTrainConfig.GetRandomStageIconById(self.CurrentStageId)
        self.MapName.text=XFubenSpecialTrainConfig.GetRandomStageNameById(self.CurrentStageId)
        self.PanelPhoto:SetRawImage(icon)
    end
    
end

function XUiSummerEpisodeNew:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        if XDataCenter.RoomManager.Matching then
            XDataCenter.RoomManager.CancelPhotoMatch(function()
                XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(nil)
                self:Close()
            end)
        else
            XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(nil)
            self:Close()
        end
    end
    self:BindHelpBtn(self.BtnHelpCourse, HELP_KEY)
    self.BtnMainUi.CallBack = function()
        XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(nil)
        XLuaUiManager.RunMain() 
    end
    self.BtnTask.CallBack = function() XLuaUiManager.Open("UiSummerEpisodeNewTask",function() XRedPointManager.Check(self.TaskRedEventId) end)  end
    self.BtnMatch.CallBack = function() self:OnClickBtnMatch() end
    self.BtnCreateRoom.CallBack = function() self:OnClickBtnCreateRoom() end
    self.BtnCircuit.CallBack = function() self:OnClickBtnCircuit() end
    self.BtnMapName.CallBack=function() self:OnClickBtnMap() end
    --2.6取消竞争模式
    --self.BtnPeace.CallBack = function() self:OnClickBtnPeace() end
    
    if self.BtnMatching then
        self:RegisterClickEvent(self.BtnMatching,self.OnClickBtnMatching)
    end
    self.BtnYou.CallBack = function() self:OnClickBtnYou() end
    self.BtnZuo.CallBack = function() self:OnClickBtnZuo() end
    self.BtnMap.CallBack = function() self:OnClickBtnMap() end
end

function XUiSummerEpisodeNew:OnClickBtnMatching()
    XDataCenter.RoomManager.CancelPhotoMatch(function()
        self:OnCancelMatching()
    end)
end

function XUiSummerEpisodeNew:OnClickBtnMatch()
    self:Match(true)
end

function XUiSummerEpisodeNew:OnClickBtnCreateRoom()
    if self.IsRandomStage then
        XUiManager.TipMsg(CSXTextManagerGetText("SpecialTrainRandomMapTip"))
        return
    end

    local stageId = self.CurrentStageId
    if self.IsPeaceModel then
        stageId = XFubenSpecialTrainConfig.GetHellStageId(self.CurrentStageId)
    end
    
    XDataCenter.RoomManager.PhotoCreateRoom(stageId)
end

function XUiSummerEpisodeNew:OnClickBtnCircuit()
    local isSave = self.BtnCircuit:GetToggleState()
    XDataCenter.FubenSpecialTrainManager.SetSavePhotoValue(isSave)
end

-- 右
function XUiSummerEpisodeNew:OnClickBtnYou()
    if self.Pos then
        local nextPos = self.Pos + 1
        if nextPos > self.MaxStageCount then
            nextPos = 1
        end
        self:GotoStage(nextPos)
    end
end

-- 左
function XUiSummerEpisodeNew:OnClickBtnZuo()
    if self.Pos then
        local lastPos = self.Pos - 1
        if lastPos < 1 then
            lastPos = self.MaxStageCount
        end
        self:GotoStage(lastPos)
    end
end

--2.6取消竞争模式，没有模式切换
--[[
function XUiSummerEpisodeNew:OnClickBtnPeace()
    self.IsPeaceModel = self.BtnPeace:GetToggleState()
end
--]]

function XUiSummerEpisodeNew:OnClickBtnMap()
    XLuaUiManager.Open("UiSummerEpisodeMap", self.CurrentStageId, true, handler(self, self.BtnSwitchCallback))
end

function XUiSummerEpisodeNew:BtnSwitchCallback(stageId)
    for index, id in pairs(self.StageIds) do
        if id == stageId then
            self.Pos = index
        end
    end
    self.CurrentStageId = stageId
    XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(stageId)
    self:UpdateStageDetail()
end

function XUiSummerEpisodeNew:UpdateStageId()
    self.CurrentStageId=XDataCenter.FubenSpecialTrainManager.GetCurrentStageId()
    if not self.CurrentStageId then
        self.CurrentStageId = self.StageIds[self.Pos]
        XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(self.CurrentStageId)
    else
        for index, id in pairs(self.StageIds) do
            if id == self.CurrentStageId then
                self.Pos = index
            end
        end
    end
    if XDataCenter.FubenSpecialTrainManager.CheckStageIsNewUnLock(self.CurrentStageId) then
        XDataCenter.FubenSpecialTrainManager.SaveForOldUnLock(self.CurrentStageId)
    end
    XRedPointManager.Check(self.MapRedPointId)
end

function XUiSummerEpisodeNew:GotoStage(index)
    if self.Pos == index then
        return
    end
    
    self.Pos = index
    self.CurrentStageId = self.StageIds[index]
    self:UpdateStageDetail()
    self:PlayAnimation("QieHuan")
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

function XUiSummerEpisodeNew:OnCheckMapRedPoint(count)
    self.BtnMap:ShowReddot(count>=0)
end

-- 匹配人数过多
function XUiSummerEpisodeNew:OnMatchPlayers(recommendStageId)
    self:OnCancelMatching()
    XUiManager.DialogTip(CS.XTextManager.GetText("SpecialTrainMatchTipTitle"),
            CS.XTextManager.GetText("SpecialTrainMatchTipContent"),
            XUiManager.DialogType.Normal,
            function()
                self:Match(false)
            end, function()
                --根据服务端下方的id创建房间
                XDataCenter.RoomManager.PhotoCreateRoom(recommendStageId)
            end)
end

function XUiSummerEpisodeNew:Match(needMatchCountCheck)
    -- 随机关卡匹配
    local stageIds = XDataCenter.FubenSpecialTrainManager.GetStageIdsByHellMode(self.IsPeaceModel)
    XDataCenter.RoomManager.PhotoMatch(stageIds, function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching")
    end, needMatchCountCheck)
end

return XUiSummerEpisodeNew