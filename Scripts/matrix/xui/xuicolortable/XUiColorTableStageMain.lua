local XPanelMapPointTip = require("XUi/XUiColorTable/Panel/XPanelMapPointTip")
local XPanelStageDetail = require("XUi/XUiColorTable/Panel/XPanelStageDetail")
local XPanelStudyData = require("XUi/XUiColorTable/Panel/XPanelStudyData")
local XPanelTimeLine = require("XUi/XUiColorTable/Panel/XPanelTimeLine")
local XPanelColorBg = require("XUi/XUiColorTable/Panel/XPanelColorBg")
local XPanelCaptain = require("XUi/XUiColorTable/Panel/XPanelCaptain")
local XPanelLog = require("XUi/XUiColorTable/Panel/XPanelLog")
local XPanelMap = require("XUi/XUiColorTable/Panel/XPanelMap")

local PanelType = {
    ColorBg = 1,        -- 病毒渐变背景
    StudyData = 2,      -- 研究数据面板
    StageDetail = 3,    -- 关卡详情面板
    CaptainDetail = 4,  -- 队长详情面板
    TimeLine = 5,       -- 时间轴面板
    EventLog = 6,       -- 事件生效提示弹窗
    StageMap = 7,       -- 关卡地图
}

local XUiColorTableStageMain = XLuaUiManager.Register(XLuaUi,"UiColorTableStageMain")

function XUiColorTableStageMain:OnAwake()
    self:AddButtonListenr()
    self._GameManager = XDataCenter.ColorTableManager.GetGameManager()
    self._GameData = self._GameManager:GetGameData()

    self.ChildPanels = {}
    self.DramaConditionList = {}
    self:InitChildPanel()
    self.PanelEffectBoss = {
        [XColorTableConfigs.ColorType.Red] = self.PanelEffectRedBoss,
        [XColorTableConfigs.ColorType.Green] = self.PanelEffectGreenBoss,
        [XColorTableConfigs.ColorType.Blue] = self.PanelEffectBlueBoss,
    }
    for _, obj in ipairs(self.PanelEffectBoss) do
        if obj then obj.gameObject:SetActiveEx(false) end
    end
end

function XUiColorTableStageMain:OnStart()
end

function XUiColorTableStageMain:OnEnable()
    self:RefreshUi()
    self:AddEventListener()
    if not self._GameData:CheckIsGuideStage() then
        self:OnBtnDetailClick()
    end
end

function XUiColorTableStageMain:OnDisable()
    self:RemoveEventListener()
end

function XUiColorTableStageMain:OnDestroy()
end



-- Panel Refresh
--=================================================================

function XUiColorTableStageMain:RefreshUi()
    self:RefreshBg()
    self:RefreshLineEffect()
    self:RefreshTimeline()
    self:RefreshEvent()
    self:RefreshCaptain()
    self:RefreshBackGround()
    self:RefreshStudyData()
    self:RefreshMap()
    self:RefreshBtnEsayAction()
    self:RefreshMapWin(true)
end

-- 刷新关卡模式背景
function XUiColorTableStageMain:RefreshBg()
    if not self.BgDay then
        return
    end
    local isNormal = XColorTableConfigs.GetMapType(self._GameData:GetMapId()) ~= XColorTableConfigs.MapType.Commander
    self.BgDay.gameObject:SetActiveEx(isNormal)
    self.DowntownDay.gameObject:SetActiveEx(isNormal)
    self.BgNight.gameObject:SetActiveEx(not isNormal)
    self.DowntownNight.gameObject:SetActiveEx(not isNormal)
end

function XUiColorTableStageMain:RefreshLineEffect()
    -- 因为特效用的是控件加载，不是脚本控制加载，所以下一帧再调用处理
    XScheduleManager.ScheduleNextFrame(function ()
        if XTool.UObjIsNil(self.GameObject) or self.PanelEffectLine.childCount <= 0 then return end
        self.Effect = self.PanelEffectLine.transform:GetChild(0)
        if not self.Effect or self.Effect.childCount <= 0 then return end
        local isNormal = XColorTableConfigs.GetMapType(self._GameData:GetMapId()) ~= XColorTableConfigs.MapType.Commander
        for i = 0, 15, 1 do
            if i >= 8 and i <= 11 then
                self.Effect:GetChild(0):GetChild(i).gameObject:SetActiveEx(isNormal and not self._GameData:CheckIsFirstGuideStage())
            elseif i >= 12 and i <= 15 then
                self.Effect:GetChild(0):GetChild(i).gameObject:SetActiveEx(not isNormal and not self._GameData:CheckIsFirstGuideStage())
            elseif i >= 6 and i <= 7  then
                self.Effect:GetChild(0):GetChild(i).gameObject:SetActiveEx(true)
            else
                self.Effect:GetChild(0):GetChild(i).gameObject:SetActiveEx(not self._GameData:CheckIsFirstGuideStage())
            end
        end
    end)
end

-- 刷新时间轴
function XUiColorTableStageMain:RefreshTimeline()
    self.ChildPanels[PanelType.TimeLine]:RefreshTimelineData()
end

-- 刷新遭遇事件Ui
function XUiColorTableStageMain:RefreshEvent()
    self.ChildPanels[PanelType.StageDetail]:RefreshEventBuff(self._GameManager:GetShowEvent())
end

-- 刷新行动点和回合数
function XUiColorTableStageMain:RefreshCaptain()
    local round = self._GameData:GetRoundId()
    local actionPoint = self._GameData:GetActionPoint()
    self.ChildPanels[PanelType.CaptainDetail]:RefreshRound(round)
    self.ChildPanels[PanelType.CaptainDetail]:RefreshActionPoint(actionPoint)
end

-- 根据Boss等级刷新背景
function XUiColorTableStageMain:RefreshBackGround()
    local bossLevels = self._GameData:GetBossLevels()
    self.ChildPanels[PanelType.ColorBg]:Refresh(bossLevels, true)
end

-- 刷新能量点数Ui
function XUiColorTableStageMain:RefreshStudyData()
    local studyDatas = self._GameData:GetStudyDatas()
    self.ChildPanels[PanelType.StudyData]:RefreshColorData(studyDatas)
end

-- 刷新研究等级
function XUiColorTableStageMain:RefreshMap()
    self.ChildPanels[PanelType.StageMap]:Refresh()
end

function XUiColorTableStageMain:RefreshBtnEsayAction()
    self.BtnEsayAction.gameObject:SetActiveEx(not self._GameData:CheckIsGuideStage())
    local isEsayMode = self._GameManager:GetEsayActionMode()
    if isEsayMode then
        self.BtnEsayAction.ButtonState = CS.UiButtonState.Select
    else
        self.BtnEsayAction.ButtonState = CS.UiButtonState.Normal
    end
end

function XUiColorTableStageMain:RefreshMapWin(isNotShow)
    if XTool.IsNumberValid(self._GameData:GetIsLose()) then
        self:RefreshGameLose()
        return
    end
    if self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.PlayGame then
        return
    end
    local winConditionId = self._GameData:GetWinConditionId()
    local stageId = self._GameData:GetStageId()
    local IsSpecailWin = XColorTableConfigs.GetStageNormalWinConditionId(stageId) ~= winConditionId

    self.PanelActionBoss.gameObject:SetActiveEx(false)
    self.BtnEsayAction.gameObject:SetActiveEx(false)
    self.BtnEnd:SetNameByGroup(0, XUiHelper.GetText("ColorTableStartBossBattle"))

    if isNotShow then
        self:BeforeBtnClick()
        self.ChildPanels[PanelType.StageMap]:RefreshMapWin(IsSpecailWin)
    else
        XLuaUiManager.Open("UiColorTableHalfSettle", IsSpecailWin, false, function()
            self:BeforeBtnClick()
            self.ChildPanels[PanelType.StageMap]:RefreshMapWin(IsSpecailWin)
        end)
    end
end

function XUiColorTableStageMain:RefreshGameLose()
    XLuaUiManager.Open("UiColorTableHalfSettle", false, true, nil, function ()
        XDataCenter.ColorTableManager.GiveUpGame()
    end, function ()
        self._GameManager:RequestReboot(function ()
            self:RefreshBg()
            self:RefreshTimeline()
            self:RefreshEvent()
            self:RefreshCaptain()
            self:RefreshBackGround()
            self:RefreshStudyData()
            self:RefreshMap()
            self:RefreshBtnEsayAction()
        end)
    end)
end

--=================================================================



-- ChildUi & ChildPanel
--=================================================================

function XUiColorTableStageMain:InitChildPanel()
    local stageId = self._GameData:GetStageId()
    local captainId = self._GameData:GetCaptainId()
    local mapId = self._GameData:GetMapId()
    local mapType = XColorTableConfigs.GetMapType(mapId)

    self.ChildPanels[PanelType.ColorBg] = XPanelColorBg.New(self, self.PanelInfected)
    self.ChildPanels[PanelType.StudyData] = XPanelStudyData.New(self, self.PanelSpecialTool)
    self.ChildPanels[PanelType.StageDetail] = XPanelStageDetail.New(self, self.PanelDetails, stageId)
    self.ChildPanels[PanelType.CaptainDetail] =
        XPanelCaptain.New(self, self.PanelCaptain, captainId, function()
            self:BeforeBtnClick()
            self:OpenTips(XColorTableConfigs.TipsType.CaptainInfoTip, captainId)
        end)
    self.ChildPanels[PanelType.TimeLine] = XPanelTimeLine.New(self, self.PanelActionBoss)
    self.ChildPanels[PanelType.EventLog] = XPanelLog.New(self, self.PanelLog)
    self.PanelStage1.gameObject:SetActiveEx(mapType ~= XColorTableConfigs.MapType.Commander)
    self.PanelStage2.gameObject:SetActiveEx(mapType == XColorTableConfigs.MapType.Commander)
    if mapType == XColorTableConfigs.MapType.Commander then
        self.ChildPanels[PanelType.StageMap] = XPanelMap.New(self, self.PanelStage2, mapId)
    else
        self.ChildPanels[PanelType.StageMap] = XPanelMap.New(self, self.PanelStage1, mapId)
    end
end

-- 打开介绍弹窗
function XUiColorTableStageMain:OpenTips(tipsType, captainId, eventId, cb)
    XLuaUiManager.Open("UiColorTableStageMainInfo", tipsType, captainId, eventId, function()
        if cb then cb() end
    end)
end

function XUiColorTableStageMain:OpenEventTips(eventId, callback)
    if not XTool.IsNumberValid(eventId) then
        return
    end
    self:BeforeBtnClick()
    self:OpenTips(XColorTableConfigs.TipsType.EventTip, nil, eventId, callback)
end

-- 打开点位操作弹窗
function XUiColorTableStageMain:OpenMapTips(pointObj, pointPosition)
    self._GameManager:StopDramaIdleTimer()
    if not self.MapPointTip or not self.MapPointTip:IsSamePoint(pointObj) then
        self._GameManager:StopDramaIdleTimer()
        self.MapPointTip = self:LoadMapTips(pointObj)
    end

    -- 弹窗刷新
    self.PanelTip.gameObject:SetActiveEx(true)
    if pointObj:IsMapPoint() and self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.PlayGame then
        self._GameManager:RequestTargetPoint(pointObj:GetPositionId(), function(data)
            self.MapPointTip:SetData(data, pointObj)
            self.MapPointTip:Refresh()
            self.MapPointTip:UpdatePosition(pointPosition)
        end)
    else
        self.MapPointTip:SetData(nil, pointObj)
        self.MapPointTip:Refresh()
        self.MapPointTip:UpdatePosition(pointPosition)
    end
end

-- 关闭点位操作弹窗
function XUiColorTableStageMain:CloseMapTips()
    if self.MapPointTip then
        self.PanelTip.gameObject:SetActiveEx(false)
        self.MapPointTip.GameObject:SetActive(false)
        self._GameManager:AddDramaConditionCount(XColorTableConfigs.DramaConditionType.TipCondition, self.MapPointTip:GetNothingDoCount())
    end
    self:StartDramaIdleTimer()
end

-- 加载点位操作弹窗
function XUiColorTableStageMain:LoadMapTips(pointObj)
    -- 加载Prefab
    self.PanelTip.gameObject:SetActiveEx(true)
    local tipObj
    local pointType = pointObj:GetType()
    if pointType == XColorTableConfigs.PointType.Boss or pointType == XColorTableConfigs.PointType.HideBoss then
        tipObj = self.PanelTip.gameObject:LoadPrefab(XColorTableConfigs.GetBossPointTipPrefab())
    else
        local tipPrefabUrl = XColorTableConfigs.GetMapPointTipPrefab(pointType)
        tipObj = self.PanelTip.gameObject:LoadPrefab(tipPrefabUrl)
    end
    if self.MapPointTip and self.MapPointTip.GameObject == tipObj then
        return self.MapPointTip
    end
    return XPanelMapPointTip.New(self, tipObj)
end

-- 病毒大爆发
function XUiColorTableStageMain:BurstSettle(settle, callback)
    if XTool.IsTableEmpty(settle) then
        callback()
        return
    end
    local effectTime = 2
    local index = 1
    self.PanelReview.gameObject:SetActiveEx(true)
    local func = function ()
        if XTool.UObjIsNil(self.Transform) then return end
        -- 最后一次用以等待最后特效完毕
        if index > #settle then
            self.PanelReview.gameObject:SetActiveEx(false)
            for _, obj in ipairs(self.PanelEffectBoss) do
                obj.gameObject:SetActiveEx(false)
            end
            callback()
            return
        end
        local burstBoss = settle[index].BossIndex + 1
        if XTool.IsNumberValid(burstBoss) and self.PanelEffectBoss[burstBoss] then
            self.PanelEffectBoss[burstBoss].gameObject:SetActiveEx(false)
            self.PanelEffectBoss[burstBoss].gameObject:SetActiveEx(true)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_COLOR_TABLE_ACTION_BOSSLEVELCHANGE, settle[index].LevelChanges)
        self._GameData:SetBossLevels(settle[index].LevelChanges)
        index = index + 1
    end
    -- 由于Schedule方法第一次执行在延迟时间之后，因此先执行一次
    func()
    XScheduleManager.Schedule(func, effectTime * XScheduleManager.SECOND, #settle)
end

-- 胜利结算
function XUiColorTableStageMain:WinSettle(data, callback)
    if XTool.IsTableEmpty(data) then
        callback()
        return
    end
    local winConditionId = self._GameData:GetWinConditionId()
    local stageId = self._GameData:GetStageId()
    local IsSpecailWin = XColorTableConfigs.GetStageNormalWinConditionId(stageId) ~= winConditionId

    XLuaUiManager.Open("UiColorTableHalfSettle", IsSpecailWin, false, function()
        local isFirstPass = not XDataCenter.ColorTableManager.IsStagePassed(stageId)
        XDataCenter.ColorTableManager.SetPassedStageId({stageId})
        XDataCenter.ColorTableManager.SavePassWinType(stageId, 0)

        -- 打开结算界面
        XDataCenter.ColorTableManager.OpenUiSettleWin(data, stageId, isFirstPass)
        self:Close()
        -- 重置当前挑战关卡
        XDataCenter.ColorTableManager.ClearCurStageId()
        if callback then callback() end
    end)
end

--=================================================================



-- Button
--=================================================================

function XUiColorTableStageMain:AddButtonListenr()
    self.PanelDrag:AddPointerDownListener(function ()
        self.ChildPanels[PanelType.StageMap]:UnSelectPoint()
    end)
    self.PanelDrag:AddBeginDragListener(function ()
        self.ChildPanels[PanelType.StageMap]:UnSelectPoint()
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDetails, self.OnBtnDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDetailMask, self.OnBtnDetailMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSpecialToolClick, self.OnBtnSpecialToolClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEsayAction, self.OnBtnEsayActionClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnd, self.OnBtnEndClick)
    XUiHelper.RegisterClickEvent(self, self.PanelActionBoss, self.OnPanelActionBossClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick)
end

-- 点击前重置部分Ui状态
function XUiColorTableStageMain:BeforeBtnClick()
    self.ChildPanels[PanelType.StageMap]:UnSelectPoint()
end

function XUiColorTableStageMain:OnBtnBackClick()
    self:BeforeBtnClick()
    self:Close()
end

-- 研究资料提示
function XUiColorTableStageMain:OnBtnSpecialToolClick()
    self:BeforeBtnClick()
    self:OpenTips(XColorTableConfigs.TipsType.StudyDataTip)
end

function XUiColorTableStageMain:OnBtnEndClick()
    self:BeforeBtnClick()
    -- 阶段一为结束回合
    if self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.PlayGame then
        if self._GameData:GetActionPoint() > 0 then
            XUiManager.DialogTip(XUiHelper.GetText("ColorTableEndDialogTitle"),
                XUiHelper.ReadTextWithNewLine("ColorTableEndDialogContext"),
                XUiManager.DialogType.Normal, nil, function ()
                self._GameManager:RequestEndRound()
                self._GameManager:StopDramaIdleTimer()
            end)
        else
            self._GameManager:RequestEndRound()
            self._GameManager:StopDramaIdleTimer()
        end
    -- 阶段二为挑战Boss
    elseif self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.Fight then
        local stageId = self._GameData:GetStageId()
        local winConditionId = self._GameData:GetWinConditionId()
        local IsSpecailWin = XColorTableConfigs.GetStageNormalWinConditionId(stageId) ~= winConditionId
        if not self._GameData:CheckIsHideBoss() or not IsSpecailWin then
            XDataCenter.ColorTableManager.OpenUiBattleRoleRoom(XColorTableConfigs.GetStageNormalStageId(stageId))
        else
            XDataCenter.ColorTableManager.OpenUiBattleRoleRoom(XColorTableConfigs.GetStageSpecialStageId(stageId))
        end
    end
end

-- 研究资料提示
function XUiColorTableStageMain:OnPanelActionBossClick()
    self:BeforeBtnClick()
    self:OpenTips(XColorTableConfigs.TipsType.RoundTip)
end

-- 便捷模式
function XUiColorTableStageMain:OnBtnEsayActionClick()
    self:BeforeBtnClick()
    local ifEsayMode = self._GameManager:GetEsayActionMode()
    if ifEsayMode then
        self._GameManager:SetEsayActionMode(false)
        self.BtnEsayAction.ButtonState = CS.UiButtonState.Normal
    else
        self:OpenTips(XColorTableConfigs.TipsType.EsayActionModeTip)
        self._GameManager:SetEsayActionMode(true)
        self.BtnEsayAction.ButtonState = CS.UiButtonState.Select
    end
end

-- 开启关卡详情
function XUiColorTableStageMain:OnBtnDetailClick()
    self:BeforeBtnClick()
    local isOpen = self.ChildPanels[PanelType.StageDetail]:GetIsOpen()
    if isOpen then
        self:OnBtnDetailMaskClick()
    else
        self:PlayAnimationWithMask("PanelDetailsEnable")
        self.ChildPanels[PanelType.StageDetail]:OpenDetail()
        self.BtnDetailMask.gameObject:SetActiveEx(true)
        self._GameManager:StopDramaIdleTimer()
    end
end

-- 关闭关卡详情
function XUiColorTableStageMain:OnBtnDetailMaskClick()
    self:BeforeBtnClick()
    self:PlayAnimationWithMask("PanelDetailsDisable")
    self.ChildPanels[PanelType.StageDetail]:CloseDetail()
    self.BtnDetailMask.gameObject:SetActiveEx(false)
    self:StartDramaIdleTimer()
end

function XUiColorTableStageMain:OnBtnHelpClick()
    XUiManager.ShowHelpTip(XColorTableConfigs.GetUiStageMainHelpKey(), nil, nil, function ()
        self._GameManager:AddDramaConditionCount(XColorTableConfigs.DramaConditionType.HelpCondition, 1)
    end)
end

function XUiColorTableStageMain:StartDramaIdleTimer()
    self._GameManager:StartDramaIdleTimer()
end

--=================================================================



-- EventListener
--=================================================================

function XUiColorTableStageMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_OPEN_MAPPOINT_TIP, self.OpenMapTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_CLOSE_MAPPOINT_TIP, self.CloseMapTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_MAPWIN, self.RefreshMapWin, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_GAMELOSE, self.RefreshGameLose, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_ADDEVENT, self.OpenEventTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BURSTSETTLE, self.BurstSettle, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STAGESETTLE, self.WinSettle, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_OVER, self.StartDramaIdleTimer, self)

    for _, childPanel in pairs(self.ChildPanels) do
        if childPanel.AddEventListener then
            childPanel:AddEventListener()
        end
    end
end
function XUiColorTableStageMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_OPEN_MAPPOINT_TIP, self.OpenMapTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_CLOSE_MAPPOINT_TIP, self.CloseMapTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_MAPWIN, self.RefreshMapWin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_GAMELOSE, self.RefreshGameLose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_ADDEVENT, self.OpenEventTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_BURSTSETTLE, self.BurstSettle, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_STAGESETTLE, self.WinSettle, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_OVER, self.StartDramaIdleTimer, self)

    for _, childPanel in pairs(self.ChildPanels) do
        if childPanel.RemoveEventListener then
            childPanel:RemoveEventListener()
        end
    end
end

--=================================================================