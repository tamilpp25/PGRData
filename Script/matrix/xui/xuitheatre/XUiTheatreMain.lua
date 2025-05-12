local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--肉鸽玩法主界面
local XUiTheatreMain = XLuaUiManager.Register(XLuaUi, "UiTheatreMain")
local FAVOR_CONDITION_ID = "FavorConditionId"           --好感度解锁条件Key
local DECORATION_CONDITION_ID = "DecorationConditionId" --装修改造解锁条件key
local FAVOR_AUTO_WINDOW_KEY = "TheatreFavorAutoWindow"         --好感度解锁弹窗Key
local DECORATION_AUTO_WINDOW_KEY = "TheatreDecorationAutoWindow"   --装修改造解锁弹窗Key

function XUiTheatreMain:OnAwake()
    self.IsShowPanel = true
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool, self)
    self:InitReward()
    self:InitButtonCallBack()
    self.TaskManager = XDataCenter.TheatreManager.GetTaskManager()
end

function XUiTheatreMain:OnEnable()
    self:Refresh()
    self:CheckUnlockFuncAutoWindows()
    self:CheckRedPoint()
    self:CheckShowPanel()
    XDataCenter.TheatreManager.CheckWeeklyTaskWindows()
end

function XUiTheatreMain:OnReleaseInst()
    return self.IsShowPanel
end

function XUiTheatreMain:OnResume(value)
    self.IsShowPanel = value
end

--主要奖励
function XUiTheatreMain:InitReward()
    local rewardId = XTheatreConfigs.GetTheatreConfig("MainViewShowRewardId").Value
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    for i, reward in ipairs(rewardGoodsList) do
        local grid = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelList)
        local gridCommon = XUiGridCommon.New(self, grid)
        gridCommon:Refresh(reward)
    end
end

function XUiTheatreMain:CheckRedPoint()
    self:CheckTaskRedPoint()
    self:CheckAlbumRedPoint()
    self:CheckDecorationRedPoint()
    self:CheckFavorRedPoint()
    self:CheckAdventureRedPoint()
end

--势力好感红点
function XUiTheatreMain:CheckFavorRedPoint()
    local isShow = XDataCenter.TheatreManager.CheckFavorRedPoint()
    self.BtnFavor:ShowReddot(isShow)
end

--装修红点
function XUiTheatreMain:CheckDecorationRedPoint()
    local isShow = XDataCenter.TheatreManager.CheckDecorationRedPoint()
    self.BtnDecoration:ShowReddot(isShow)
end

--图鉴红点
function XUiTheatreMain:CheckAlbumRedPoint()
    local isShow = XDataCenter.TheatreManager.CheckFieldGuideRedPoint()
    self.BtnAlbum:ShowReddot(isShow)
end

--任务红点
function XUiTheatreMain:CheckTaskRedPoint()
    local isShowRedPoint = XDataCenter.TheatreManager.CheckTaskCanReward() or
        XDataCenter.TheatreManager.CheckTaskStartTimeOpen() or
        XDataCenter.TheatreManager.CheckWeeklyTaskRedPoint()
    self.BtnTask:ShowReddot(isShowRedPoint)
end

function XUiTheatreMain:CheckAdventureRedPoint()
    if self.BtnAdventureRed then
        self.BtnAdventureRed.gameObject:SetActiveEx(XDataCenter.TheatreManager.CheckSPModeRedPoint())
    end
end

--检查功能解锁自动弹窗
function XUiTheatreMain:CheckUnlockFuncAutoWindows()
    local datas = {}
    --好感度首次解锁弹窗
    if XDataCenter.TheatreManager.CheckCondition(FAVOR_CONDITION_ID) and XDataCenter.TheatreManager.CheckIsCookie(FAVOR_AUTO_WINDOW_KEY) then
        local configs = XTheatreConfigs.GetUnlockFavor()
        table.insert(datas, {Name = configs[1], Icon = configs[2]})
    end
    --装修改造首次解锁弹窗
    if XDataCenter.TheatreManager.CheckCondition(DECORATION_CONDITION_ID) and XDataCenter.TheatreManager.CheckIsCookie(DECORATION_AUTO_WINDOW_KEY) then
        local configs = XTheatreConfigs.GetUnlockDecoration()
        table.insert(datas, {Name = configs[1], Icon = configs[2]})
    end
    if not XTool.IsTableEmpty(datas) then
        XLuaUiManager.Open("UiTheatreUnlockTips", {ShowTipsPanel = XTheatreConfigs.UplockTipsPanel.Prerogative, Datas = datas, CloseCb = handler(self, self.CheckNewDecorationAutoWindoes)})
    else
        self:CheckNewDecorationAutoWindoes()
    end
end

--新的装修项解锁弹窗
function XUiTheatreMain:CheckNewDecorationAutoWindoes()
    if not XDataCenter.TheatreManager.CheckCondition(DECORATION_CONDITION_ID) then
        return
    end

    local theatreDecorationIdList = {}
    local cookieKey = "TheatreNewDecoration_"
    local idList = XTheatreConfigs.GetCheckWindowDecorationIdList()
    local conditionId
    local isUnLock, desc
    for _, theatreDecorationId in ipairs(idList) do
        conditionId = XTheatreConfigs.GetDecorationConditionId(theatreDecorationId)
        isUnLock = not XTool.IsNumberValid(conditionId) and true or XConditionManager.CheckCondition(conditionId)
        if isUnLock and XDataCenter.TheatreManager.CheckIsCookie(cookieKey .. theatreDecorationId) then
            table.insert(theatreDecorationIdList, theatreDecorationId)
        end
    end

    if not XTool.IsTableEmpty(theatreDecorationIdList) then
        XLuaUiManager.Open("UiTheatreUnlockTips", {ShowTipsPanel = XTheatreConfigs.UplockTipsPanel.NewTalent, TheatreDecorationIdList = theatreDecorationIdList})
    end
end

function XUiTheatreMain:Refresh()
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local chapter = adventureManager and adventureManager:GetCurrentChapter()
    local chapterId = chapter and chapter:GetCurrentChapterId()

    --开始冒险按钮的文本
    local curStateIsBegin = not XDataCenter.TheatreManager.CheckHasAdventure()
    local txtPath = curStateIsBegin and XTheatreConfigs.TheatreTxtStartPath or XTheatreConfigs.TheatreTxtContinuePath
    self.BtnFight:SetSprite(txtPath)

    --继续冒险的进度
    self.TxtOngoingNormal.gameObject:SetActiveEx(not curStateIsBegin)
    self.TxtOngoingPress.gameObject:SetActiveEx(not curStateIsBegin)
    if not curStateIsBegin then
        local title = XTheatreConfigs.GetChapterTitle(chapterId)
        self.BtnFight:SetName(XUiHelper.GetText("TheatreTxtOngoing", title))
    end
    
    --装修改造
    local isUnLock = XDataCenter.TheatreManager.CheckCondition(DECORATION_CONDITION_ID)
    self.BtnDecoration:SetDisable(not isUnLock)

    --好感度
    isUnLock = XDataCenter.TheatreManager.CheckCondition(FAVOR_CONDITION_ID)
    self.BtnFavor:SetDisable(not isUnLock)

    --背景图片
    if self.RImgBgA then
        local bgA = XTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end

    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopActive)
    self.BtnShop:SetDisable(not isOpen)
    
    -- 冒险模式
    if self.BtnAdventure then
        local isShowAdventure = XDataCenter.TheatreManager.CheckSPModeIsOpen() and not XDataCenter.TheatreManager.CheckHasAdventure()
        self.BtnAdventure.gameObject:SetActiveEx(isShowAdventure)
        self.BtnAdventure.isOn = XDataCenter.TheatreManager.GetSPMode()
    end

    self:UpdateTask()
    self:UpdateSceneUrl()
end

function XUiTheatreMain:UpdateSceneUrl()
    XDataCenter.TheatreManager.UpdateSceneUrl(self)
    XDataCenter.TheatreManager.ShowRoleModelCamera(self, "FarCameraMain", "NearCameraMain")
    self:CheckPlayCameraAnima()
end

--播放场景预设上的Timeline
function XUiTheatreMain:CheckPlayCameraAnima()
    if self.IsPlayingCameraAnima then
        return
    end

    self.IsPlayingCameraAnima = true
    local uiModelGo = XDataCenter.TheatreManager.GetUiModelGo()
    if XTool.UObjIsNil(uiModelGo) then
        return
    end

    local uiModelGoTransform = uiModelGo.transform
    if XTool.UObjIsNil(uiModelGoTransform) then
        return
    end

    local cameraMainEnable = uiModelGoTransform:FindTransform("CameraMainEnable")
    if cameraMainEnable then
        cameraMainEnable:PlayTimelineAnimation()
    end
end

function XUiTheatreMain:UpdateTask()
    local taskId = self.TaskManager:GetMainShowTaskId()
    if not XTool.IsNumberValid(taskId) then
        self.BtnTask.gameObject:SetActiveEx(false)
        return
    end

    local config = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    --任务名称
    self.BtnTask:SetNameByGroup(0, config.Title)
    --任务描述
    self.BtnTask:SetNameByGroup(1, config.Desc)
    --任务完成状态
    local isComplete = XDataCenter.TaskManager.IsTaskFinished(taskId)
    self.BtnTask:SetDisable(isComplete or false)
    self.BtnTask.gameObject:SetActiveEx(true)
end

function XUiTheatreMain:CheckShowPanel()
    local isShowPanel = self.IsShowPanel or false
    self.PanelSpecialTool.gameObject:SetActiveEx(isShowPanel)
    self.BtnFight.gameObject:SetActiveEx(isShowPanel)
end

function XUiTheatreMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:UpdateTask()
    end
end

function XUiTheatreMain:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end

function XUiTheatreMain:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "Theatre")
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)        --开始冒险
    self:RegisterClickEvent(self.BtnAlbum, self.OnBtnAlbumClick)        --图鉴
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)          --商店
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)          --任务
    self:RegisterClickEvent(self.BtnDecoration, self.OnBtnDecorationClick)  --装修改造
    self:RegisterClickEvent(self.BtnFavor, self.OnBtnFavorClick)        --好感度
    if self.BtnAdventure then
        self:RegisterClickEvent(self.BtnAdventure, self.OnBtnAdventureClick)    -- 冒险模式
    end
end

function XUiTheatreMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiTheatreTask")
end

function XUiTheatreMain:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XLuaUiManager.Open("UiTheatreShop")
    end
end

function XUiTheatreMain:OnBtnAlbumClick()
    XLuaUiManager.Open("UiTheatreFieldGuide", {XTheatreConfigs.FieldGuideIds.AllSkill, XTheatreConfigs.FieldGuideIds.Item})
end

function XUiTheatreMain:OnBtnFightClick()
    if XDataCenter.TheatreManager.CheckHasAdventure() then
        -- 继续冒险
        XLuaUiManager.Open("UiTheatreContinue", nil, function()
            self.IsShowPanel = true
            self:CheckShowPanel()
        end)
        self.IsShowPanel = false
        self:CheckShowPanel()
    else
        -- 开始冒险
        XLuaUiManager.Open("UiTheatreChoose")
    end
end

function XUiTheatreMain:OnBtnDecorationClick()
    if not XDataCenter.TheatreManager.CheckCondition(DECORATION_CONDITION_ID, true) then
        return
    end
    XLuaUiManager.Open("UiTheatreDecoration")
end

function XUiTheatreMain:OnBtnFavorClick()
    if not XDataCenter.TheatreManager.CheckCondition(FAVOR_CONDITION_ID, true) then
        return
    end
    XLuaUiManager.Open("UiTheatreFavorability")
end

function XUiTheatreMain:OnBtnAdventureClick()
    local isOn = self.BtnAdventure.isOn
    XDataCenter.TheatreManager.SetSPMode(isOn, true)
    XDataCenter.TheatreManager.SetSPModeRedPoint()
    self:CheckAdventureRedPoint()
end 