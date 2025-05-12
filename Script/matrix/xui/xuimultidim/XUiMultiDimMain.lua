local XUiMultiDimMain = XLuaUiManager.Register(XLuaUi, "UiMultiDimMain")
local XUiMultiDimMainDetail = require("XUi/XUiMultiDim/XUiMultiDimMainDetail")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local UiState = {
    Main = 1,
    Detail = 2,
}

function XUiMultiDimMain:OnAwake()
    self:RegisterUiEvents()
    self:InitSceneRoot()
    
    self.ThemeBtnInfo = {}
    self.ThemeBtnRad = {}
end

function XUiMultiDimMain:OnStart()
    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)

    self:InitView()
    self:InitThemeView()
    
    self.UiState = UiState.Main
    self:SwitchState(self.UiState)

    self.TeamFightRad = XRedPointManager.AddRedPointEvent(
            self.BtnTeamFight, 
            self.TeamFightRedPoint, 
            self, 
            { XRedPointConditions.Types.CONDITION_MULTI_DIM_FIRST_REWARD }, 
            self.CurrentThemeId, false)

    -- 播放镜头动画
    if self.SceneAnimEnable then
        self.SceneAnimEnable:PlayTimelineAnimation()
    end
end

function XUiMultiDimMain:OnEnable()
    self:StartTime()
    self:RefreshThemeBtnInfo()
    self:RefreshModel()
    self:RefreshTeamBtn()
    self:RefreshTaskRedPoint()
    self:OpenOnceThemeUnlockDialog()
    XLoginManager.SpeedUpHearbeatInterval()
end

function XUiMultiDimMain:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiMultiDimMain:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskRedPoint()
    end
end

function XUiMultiDimMain:OnDisable()
    self:StopTime()
    XLoginManager.ResetHearbeatInterval()
end

function XUiMultiDimMain:OnDestroy()
    if self.UiMultiDimMainDetail then
        self.UiMultiDimMainDetail:OnDestroy()
    end
end

--region 按钮相关

function XUiMultiDimMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuff, self.OnBtnBuffClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTeamFight, self.OnBtnTeamFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSingleFight, self.OnBtnSingleFightClick)
    self:BindHelpBtn(self.BtnHelp, "MultiDimMain")
end

function XUiMultiDimMain:OnBtnBackClick()
    if self.UiState == UiState.Main then
        self:Close()
    elseif self.UiState == UiState.Detail then
        if XDataCenter.RoomManager.Matching then
            local title = CsXTextManagerGetText("TipTitle")
            local cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceCancelMatch")
            XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
                XDataCenter.RoomManager.CancelMatch(function()
                    self:SwitchState(UiState.Main)
                end)
            end)
        else
            self:SwitchState(UiState.Main)
        end
    end
end

function XUiMultiDimMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
-- 多维任务
function XUiMultiDimMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiMultiDimTask")
end
-- 天赋技能
function XUiMultiDimMain:OnBtnBuffClick()
    local isUnlock, desc = XDataCenter.MultiDimManager.CheckTalentIsOpen()
    if not isUnlock then
        XUiManager.TipMsg(desc)
        return
    end
    XLuaUiManager.Open("UiMultiDimTalent")
end
-- 多维排行
function XUiMultiDimMain:OnBtnRankClick()
    XLuaUiManager.Open("UiMultiDimTeamRanking")
end
-- 单人副本
function XUiMultiDimMain:OnBtnSingleFightClick()
    -- 保存选择的主题
    XDataCenter.MultiDimManager.SaveDefaultActivityThemeId(self.CurrentThemeId)
    XLuaUiManager.Open("UiMultiDimSingleCopy", self.CurrentThemeId)
end
-- 多人副本
function XUiMultiDimMain:OnBtnTeamFightClick()
    -- 前置条件Condition
    local isUnlock, desc = XDataCenter.MultiDimManager.CheckThemeTeamFubenCondition(self.CurrentThemeId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
        return
    end
    -- 是否在开启时间内
    if not XDataCenter.MultiDimManager.CheckTeamIsOpen(true) then
        return
    end
    -- 保存选择的主题
    XDataCenter.MultiDimManager.SaveDefaultActivityThemeId(self.CurrentThemeId)
    -- 保存点击
    if not XDataCenter.MultiDimManager.CheckClickMainTeamFightBtn(self.CurrentThemeId) then
        local key = XDataCenter.MultiDimManager.GetFirstRewardKey(self.CurrentThemeId)
        local todayTime = XTime.GetSeverTodayFreshTime()
        XSaveTool.SaveData(key, todayTime)
        self:RefreshThemeRedPoint()
    end
    -- 默认难度
    local currentDifficulty = XDataCenter.MultiDimManager.GetCurrentThemeDefaultDifficultyId(self.CurrentThemeId)
    self.UiMultiDimMainDetail:Refresh(self.CurrentThemeId, currentDifficulty)
    self:SwitchState(UiState.Detail)
end
--endregion

--region 3D模型

function XUiMultiDimMain:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelModel = root:FindTransform("PanelModel")
    self.SceneAnimEnable = root:FindTransform("AnimEnable")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true)
end

function XUiMultiDimMain:RefreshModel()
    -- 模型根据主题去加载
    local modelId = XDataCenter.MultiDimManager.GetThemeModelId(self.CurrentThemeId)
    local modelScale = XMultiDimConfig.GetThemeModelScale(self.CurrentThemeId)
    self.RoleModelPanel:UpdateBossModel(modelId, XModelManager.MODEL_UINAME.XUiMultiDimMain, nil, function(model)
        model.transform.localScale = CS.UnityEngine.Vector3(modelScale, modelScale, modelScale)
    end)
    self.RoleModelPanel:ShowRoleModel()
end

--endregion

function XUiMultiDimMain:InitView()
    -- 活动名称
    self.TxtTitleName.text = XDataCenter.MultiDimManager.GetActivityName()
    -- 多人副本开启时间
    self.MultiTxtTime.text = XDataCenter.MultiDimManager.GetTeamFubenOpenTimeText()
    -- 天赋技能
    local isUnlock = XDataCenter.MultiDimManager.CheckTalentIsOpen()
    self.BtnBuff:SetButtonState(isUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
    -- 关卡详情界面
    self.UiMultiDimMainDetail = XUiMultiDimMainDetail.New(self.PanelDetail, self)

    self.GameObjectGroup = {
        [UiState.Main] = {
            self.PanelMain.gameObject,
            self.UiModelGo.transform:FindTransform("UiCamFarMain").gameObject,
            self.UiModelGo.transform:FindTransform("UiCamNearMain").gameObject,
        },
        [UiState.Detail] = {
            self.PanelDetail.gameObject,
            self.UiModelGo.transform:FindTransform("UiCamFarPanelMatch").gameObject,
            self.UiModelGo.transform:FindTransform("UiCamNearPanelMatch").gameObject,
        },
    }
end

function XUiMultiDimMain:SwitchState(state)
    self.UiState = state
    for _, v in pairs(self.GameObjectGroup) do
        for _, go in pairs(v) do
            go:SetActiveEx(false)
        end
    end

    for _, go in pairs(self.GameObjectGroup[state]) do
        go:SetActiveEx(true)
    end
end

function XUiMultiDimMain:OpenOnceThemeUnlockDialog()
    -- 当天赋满足配置的开启condition后 且位于活动主面板时，弹出一次性弹窗
    local isUnlock, desc = XDataCenter.MultiDimManager.CheckTalentIsOpen()
    local isOpenOnceDialog = XDataCenter.MultiDimManager.CheckThemeOpenOnceDialog()
    if isUnlock and not isOpenOnceDialog then
        XLuaUiManager.Open("UiMultiDimTalentOpenTip")
    end
end

--region 主题相关
    
function XUiMultiDimMain:InitThemeView()
    self:InitThemeBtnGroup() 
end

function XUiMultiDimMain:InitThemeBtnGroup()
    self.BtnTab.gameObject:SetActiveEx(false)
    self.ThemeBtnInfo = {}
    local themeIds = XDataCenter.MultiDimManager.GetThemeAllId()
    for index, id in pairs(themeIds) do
        local go = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        local btn = go:GetComponent("XUiButton")
        btn.gameObject:SetActiveEx(true)
        -- 主题名称
        local themeName = XDataCenter.MultiDimManager.GetThemeNameById(id)
        btn:SetNameByGroup(0, themeName)
        -- 多维积分 默认显示暂无积分
        btn:ActiveTextByGroup(2, false)
        btn:ActiveTextByGroup(4, true)
        -- 开启时间
        local startText = XDataCenter.MultiDimManager.GetThemeStartTimeText(id)
        btn:SetNameByGroup(3, XUiHelper.ConvertLineBreakSymbol(startText))
        -- 添加红点
        self.ThemeBtnRad[id] = XRedPointManager.AddRedPointEvent(btn, function(_, count)
            btn:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.CONDITION_MULTI_DIM_FIRST_REWARD }, id, false)
        self.ThemeBtnInfo[index] = { Id = id, Button = btn }
    end
end

function XUiMultiDimMain:OnClickTabCallBack(tabIndex)
    if self.CurrentThemeSelect and self.CurrentThemeSelect == tabIndex then
        return
    end

    self.CurrentThemeSelect = tabIndex
    local info = self.ThemeBtnInfo[tabIndex]
    self.CurrentThemeId = info.Id
    self:RefreshModel()
    self:RefreshThemeInfo(self.CurrentThemeId)
    self:RefreshTeamBtn()
    self:RefreshSingleBtn()
end

function XUiMultiDimMain:RefreshThemeBtnInfo()
    local tabGroup = {}
    for index, info in pairs(self.ThemeBtnInfo) do
        -- 是否开启
        local isThemeOpen = XDataCenter.MultiDimManager.CheckThemeIsOpen(info.Id)
        info.Button:SetButtonState(isThemeOpen and XUiButtonState.Normal or XUiButtonState.Disable)
        -- 每日首通
        local isFirstPassOpen = XDataCenter.MultiDimManager.CheckThemeIsFirstPassOpen(info.Id)
        info.Button:ShowTag(isThemeOpen and isFirstPassOpen)
        -- 多维积分
        self:RefreshThemePoint(info)
        
        XRedPointManager.Check(self.ThemeBtnRad[info.Id], info.Id)
        
        -- 主题开启后才添加到Group里
        if isThemeOpen then
            tabGroup[index] = info.Button
        else
            info.Button.CallBack = function()
                local themeName = XDataCenter.MultiDimManager.GetThemeNameById(info.Id)
                local msg = CSXTextManagerGetText("MultiDimThemeNotOpenTip", themeName)
                XUiManager.TipMsg(msg)
            end
        end
    end
    self.PanelTab:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
    
    if XTool.IsTableEmpty(tabGroup) then
        return
    end
    -- 默认选中上一次挑战过的主题（多人or单人均计算在内）。无记录时，首次打开定位至首个
    local tempThemeId = XDataCenter.MultiDimManager.GetDefaultActivityThemeId()
    local defaultIndex = 1
    if XTool.IsNumberValid(tempThemeId) then
        for index, info in pairs(self.ThemeBtnInfo) do
            if info.Id == tempThemeId then
                defaultIndex = index
            end
        end
    end
    self.PanelTab:SelectIndex(defaultIndex)
end

function XUiMultiDimMain:RefreshThemePoint(info)
    local point = XDataCenter.MultiDimManager.GetFightRecordPoint(info.Id)
    if XTool.IsNumberValid(point) then
        info.Button:SetNameByGroup(2, point)
        info.Button:ActiveTextByGroup(2, true)
        info.Button:ActiveTextByGroup(4, false)
    end
end

function XUiMultiDimMain:RefreshThemeInfo(id)
    self.TxtNumber.text = string.format("%02d", id)
    -- 主题名称
    local themeName = XDataCenter.MultiDimManager.GetThemeNameById(id)
    self.TxtName.text = themeName
    -- 当前排名 默认值是"未挑战"
    self.TxtNone.gameObject:SetActiveEx(true)
    self.TxtRank.gameObject:SetActiveEx(false)
    -- 获取排行信息
    XDataCenter.MultiDimManager.MultiDimOpenRankRequest(XMultiDimConfig.RANK_MODEL.SINGLE_RANK, self.CurrentThemeId, function()
        local isActive, text = XDataCenter.MultiDimManager.GetCurrentRankMsg(XMultiDimConfig.RANK_MODEL.SINGLE_RANK, self.CurrentThemeId)
        self.TxtRank.text = text
        self.TxtNone.gameObject:SetActiveEx(not isActive)
        self.TxtRank.gameObject:SetActiveEx(isActive)
    end)
end

function XUiMultiDimMain:RefreshTeamBtn()
    self:RefreshTeamBtnState()
    -- 组队进度
    local passCount, totalCount = XDataCenter.MultiDimManager.GetMultiDimTeamProgress(self.CurrentThemeId)
    self.BtnTeamFight:SetNameByGroup(1, string.format("%d/%d", passCount, totalCount))
    -- 组队红点
    XRedPointManager.Check(self.TeamFightRad, self.CurrentThemeId)
    
    -- 单人进度
    local singlePassCount = XDataCenter.MultiDimManager.GetMultiSinglePassStageCount(self.CurrentThemeId)
    local totalSingleStageCount = #XMultiDimConfig.GetMultiSingleStageListByThemeId(self.CurrentThemeId)
    local singleProgress = string.format("%d/%d", singlePassCount, totalSingleStageCount)
    self.BtnSingleFight:SetNameByGroup(1, singleProgress)
end

function XUiMultiDimMain:RefreshTeamBtnState()
    local isTeamOpen = XDataCenter.MultiDimManager.CheckTeamIsOpen(false)
    self.BtnTeamFight:ShowTag(isTeamOpen)
    self.BtnTeamFight:SetButtonState(isTeamOpen and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiMultiDimMain:RefreshSingleBtn()

end
--endregion

--region 红点

-- 任务红点
function XUiMultiDimMain:RefreshTaskRedPoint()
    local isShowRed = XDataCenter.MultiDimManager.CheckLimitTaskGroup()
    self.BtnTask:ShowReddot(isShowRed)
end

function XUiMultiDimMain:RefreshThemeRedPoint()
    XRedPointManager.Check(self.ThemeBtnRad[self.CurrentThemeId], self.CurrentThemeId)
    XRedPointManager.Check(self.TeamFightRad, self.CurrentThemeId)
end

function XUiMultiDimMain:TeamFightRedPoint(count)
    if self.BtnTeamFight then
        self.BtnTeamFight:ShowReddot(count >= 0)
    end
end

--endregion

--region 剩余时间

function XUiMultiDimMain:StartTime()
    if self.Timer then
        self:StopTime()
    end

    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiMultiDimMain:UpdateTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTime()
        return
    end

    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if now >= endTime then
        self:StopTime()
        XDataCenter.MultiDimManager.HandleActivityEndTime()
        return
    end

    local timeText = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeText
    
    -- 刷新多人副本开启状态
    self:RefreshTeamBtnState()
end

function XUiMultiDimMain:StopTime()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--endregion

return XUiMultiDimMain