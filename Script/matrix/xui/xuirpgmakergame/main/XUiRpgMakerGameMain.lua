local XUiRpgMakerGameStages = require("XUi/XUiRpgMakerGame/Main/XUiRpgMakerGameStages")
local XUiRpgMakerGameTabBtn = require("XUi/XUiRpgMakerGame/Main/XUiRpgMakerGameTabBtn")
local XUiPanelTitle = require("XUi/XUiRpgMakerGame/Main/XUiPanelTitle")
local XUiPanelTask = require("XUi/XUiRpgMakerGame/Main/XUiPanelTask")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--功能主界面
local XUiRpgMakerGameMain = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameMain")

function XUiRpgMakerGameMain:OnAwake()
    self.NewStageId = 0    --最近解锁的关卡
    self:InitObj()
    self:UpdateCurChapterGroupId()
    XUiHelper.NewPanelActivityAsset({XDataCenter.ItemManager.ItemId.RpgMakerGameHintCoin}, self.PanelSpecialTool)
    self:AutoAddListener()
    self:InitTabGroup()

    -- 第四期不显示往期玩法按钮
    self.BtnActive.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameMain:OnStart()
    local defaultButtonGroupIndex = self:GetDefaultButtonGroupIndex()
    self:UpdateTabSelect(defaultButtonGroupIndex, self.ChapterIdList)
    self:InitTimes()
end

function XUiRpgMakerGameMain:OnEnable()
    XUiRpgMakerGameMain.Super.OnEnable(self)
    self:UpdateNewStageId()
    self:Refresh()
end


--#region 数据初始化

function XUiRpgMakerGameMain:InitObj()
    self.CurShowBgEffect = nil
    local chapterGroupIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
    local bgEffect
    for i, chapterGroupId in ipairs(chapterGroupIdList) do
        bgEffect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/BgEffect0" .. i)
        self["BgEffect" .. chapterGroupId] = bgEffect
        if bgEffect then
            bgEffect.gameObject:SetActiveEx(false)
        end
    end

    -- 任务
    self.PanelTask = XUiPanelTask.New(self.BtnTask, self)
end

function XUiRpgMakerGameMain:InitTimes()
    -- 设置自动关闭和倒计时
    self:SetAutoCloseInfo(XDataCenter.RpgMakerGameManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.RpgMakerGameManager.CheckActivityIsOpen()
            return
        end
        self:RefreshActivityTime()
        -- self:UpdateActiveRedPoint()
    end, nil, 0)
end

--#endregion



--#region Ui刷新相关

function XUiRpgMakerGameMain:Refresh()
    self:UpdateStagesMap()
    self:UpdateTabBtnTemplates()
    self:UpdateBtnTask()
    self:UpdateBg()
    self:UpdateTitle()

    self:RefreshRedPoint()
end

function XUiRpgMakerGameMain:RefreshActivityTime()
    local id = XRpgMakerGameConfigs.GetDefaultActivityId()
    local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if self.PanelTitle then
        self.PanelTitle:Refresh(XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.RPG_MAKER_GAME_MAIN))
    end

    for _, tabBtn in ipairs(self.TabBtnTemplates) do
        tabBtn:RefreshTimer()
    end
end

function XUiRpgMakerGameMain:UpdateTitle()
    local prefabPath = XRpgMakerGameConfigs.GetChapterGroupTitlePrefab(self.CurChapterGroupId)
    local ui = self.PanelMainlineChapter.gameObject:LoadPrefab(prefabPath)
    self.PanelTitle = XUiPanelTitle.New(ui)
    self:RefreshActivityTime()
end

function XUiRpgMakerGameMain:UpdateBg()
    local bg = XRpgMakerGameConfigs.GetChapterGroupBg(self.CurChapterGroupId)
    -- self.RawImageBg:SetRawImage(bg)
end

function XUiRpgMakerGameMain:UpdateBtnTask()
    local isShowTask = XRpgMakerGameConfigs.GetChapterGroupIsShowTask(self.CurChapterGroupId)
    self.BtnTask.gameObject:SetActiveEx(isShowTask)
    if isShowTask then self.PanelTask:Refresh() end
end

function XUiRpgMakerGameMain:RefreshRedPoint()
    self:UpdateTaskRedPoint()
end

function XUiRpgMakerGameMain:UpdateTaskRedPoint()
    local isShowRedPoint = XDataCenter.RpgMakerGameManager.CheckRedPoint()
    self.BtnTask:ShowReddot(isShowRedPoint)
end

--更新章节组小红点
function XUiRpgMakerGameMain:UpdateActiveRedPoint()
    local isShowRedPoint = XDataCenter.RpgMakerGameManager.CheckAllChapterGroupRedPoint()
    self.BtnActive:ShowReddot(isShowRedPoint)
end

--#endregion



--#region 章节相关

function XUiRpgMakerGameMain:InitTabGroup()
    self.TabBtns = self.TabBtns or {}
    self.TabBtnTemplates = self.TabBtnTemplates or {}
    self.ChapterIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList(self.CurChapterGroupId)
    for i, chapterId in ipairs(self.ChapterIdList) do
        if not self.TabBtns[i] then
            self.TabBtns[i] = i == 1 and self.BtnPlotTab or CSUnityEngineObjectInstantiate(self.BtnPlotTab, self.UiContent)
        end
        if not self.TabBtnTemplates[i] then
            self.TabBtnTemplates[i] = XUiRpgMakerGameTabBtn.New(self.TabBtns[i], i)
        end
        self.TabBtnTemplates[i]:Init(chapterId)
        self.TabBtnTemplates[i].GameObject:SetActiveEx(true)
    end

    for i = #self.ChapterIdList + 1, #self.TabBtnTemplates do
        local tabBtn = self.TabBtnTemplates[i]
        tabBtn.GameObject:SetActiveEx(false)
    end

    self.UiContentButtonGroup = self.UiContent:GetComponent("XUiButtonGroup")
    self.UiContentButtonGroup:Init(self.TabBtns, function(groupIndex) self:TabGroupSkip(groupIndex) end)
end

function XUiRpgMakerGameMain:GetDefaultButtonGroupIndex()
    local defaultGroupIndex = 1
    local groupIndex = XDataCenter.RpgMakerGameManager.GetCurrClearButtonGroupIndex()
    local chapterId
    local isUnLock
    if groupIndex then
        chapterId = self.ChapterIdList[groupIndex]
        isUnLock = XDataCenter.RpgMakerGameManager.IsChapterUnLock(chapterId)
        return isUnLock and groupIndex or defaultGroupIndex
    end

    local allStageIdList = XRpgMakerGameConfigs.GetRpgMakerGameAllStageIdList()
    for _, stageId in ipairs(allStageIdList) do
        if not XDataCenter.RpgMakerGameManager.IsStageUnLock(stageId) then
            chapterId = XRpgMakerGameConfigs.GetRpgMakerGameStageChapterId(stageId)
            isUnLock = XDataCenter.RpgMakerGameManager.IsChapterUnLock(chapterId)
            groupIndex = isUnLock and self:GetTabBtnIndex(chapterId) or defaultGroupIndex
            return groupIndex
        end
    end

    return defaultGroupIndex
end

function XUiRpgMakerGameMain:GetTabBtnIndex(chapterId)
    local tabBtnTemplates = self:GetTabBtnTemplates()
    for _, v in ipairs(tabBtnTemplates) do
        if v:GetChapterId() == chapterId then
            return v:GetTabBtnIndex()
        end
    end
end

function XUiRpgMakerGameMain:TabGroupSkip(groupIndex)
    if self.TabGroupIndex == groupIndex then
        return
    end

    local chapterId = self.ChapterIdList[groupIndex]
    local isUnLock = XDataCenter.RpgMakerGameManager.IsChapterUnLock(chapterId)
    if not isUnLock then
        if not XDataCenter.RpgMakerGameManager.IsChapterInTime(chapterId, true) then
            return
        end
        
        if not XDataCenter.RpgMakerGameManager.IsPassPreChapter(chapterId, true) then
            return
        end

        if self.TabGroupIndex then
            self:UpdateTabSelect(self.TabGroupIndex, self.ChapterIdList)
        end
        return
    end

    self:PlayAnimation("QieHuan")
    self.TabGroupIndex = groupIndex
    XDataCenter.RpgMakerGameManager.SetCurrTabGroupIndexByUiMainTemp(groupIndex)
    XDataCenter.RpgMakerGameManager.SetChapterIdOpen(self.ChapterIdList[self.TabGroupIndex])

    self:UpdateNewStageId()
    self:Refresh()
end

--更新当前选择的第几期章节
function XUiRpgMakerGameMain:UpdateCurChapterGroupId(chapterGroupId)
    self.CurChapterGroupId = chapterGroupId or XDataCenter.RpgMakerGameManager.GetDefaultChapterGroupId()
    XDataCenter.RpgMakerGameManager.SetCurChapterGroupId(self.CurChapterGroupId)

    if not self.CurChapterGroupId then
        return
    end

    local bgEffect = self["BgEffect" .. self.CurChapterGroupId]
    if bgEffect then
        bgEffect.gameObject:SetActiveEx(true)
        if self.CurShowBgEffect then
            self.CurShowBgEffect.gameObject:SetActiveEx(false)
        end
        self.CurShowBgEffect = bgEffect
    else
        XLog.Error("切换背景特效错误，chapterGroupId：", self.CurChapterGroupId)
    end
end

function XUiRpgMakerGameMain:UpdateTabIndex()
    if not self.TabGroupIndex then
        return
    end
    local chapterIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList(self.CurChapterGroupId)
    if self.TabGroupIndex >= #chapterIdList then
        local tabIndex = #chapterIdList
        self.TabGroupIndex = tabIndex
        XDataCenter.RpgMakerGameManager.SetCurrTabGroupIndexByUiMainTemp(tabIndex)
    end
    self:UpdateTabSelect(self.TabGroupIndex, chapterIdList)
end

function XUiRpgMakerGameMain:UpdateTabSelect(tabGroupIndex, ChapterIdList)
    self.UiContentButtonGroup:SelectIndex(tabGroupIndex)
    -- 章节小红点
    XDataCenter.RpgMakerGameManager.SetChapterIdOpen(ChapterIdList[tabGroupIndex])
end

function XUiRpgMakerGameMain:UpdateTabBtnTemplates()
    for _, tabBtn in ipairs(self.TabBtnTemplates) do
        tabBtn:Refresh()
    end
end

function XUiRpgMakerGameMain:GetTabBtnTemplates()
    return self.TabBtnTemplates
end

--#endregion



--#region 关卡相关

function XUiRpgMakerGameMain:UpdateNewStageId()
    local chapterIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList(XDataCenter.RpgMakerGameManager.GetCurChapterGroupId())
    local chapterId = chapterIdList[self.TabGroupIndex]
    local allStageIdList = XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
    
    for _, stageId in ipairs(allStageIdList) do
        if not XDataCenter.RpgMakerGameManager.IsStageClear(stageId) then
            self.NewStageId = stageId
            return
        end
    end
    self.NewStageId = 0
end

function XUiRpgMakerGameMain:UpdateStagesMap()
    if not self.TabGroupIndex then
        return
    end

    local chapterId = self.ChapterIdList[self.TabGroupIndex]
    if not chapterId then
        XLog.Error(string.format("不存在的章节Id，TabGroupIndex：%", self.TabGroupIndex), self.ChapterIdList)
        return
    end
    if chapterId ~= self.ChapterId then
        local prefabName = XRpgMakerGameConfigs.GetRpgMakerGameChapterPrefab(chapterId)
        local prefab = self.PanelChapter:LoadPrefab(prefabName)
        if prefab == nil or not prefab:Exist() then
            return
        end
        self.ChapterId = chapterId
        self.CurStages = XUiRpgMakerGameStages.New(prefab, chapterId, function(stageId) self:OpenEnterDialog(stageId) end)
    end

    local newStageId = self:GetNewStageId()
    self.CurStages:Refresh(newStageId)
end

function XUiRpgMakerGameMain:GetNewStageId()
    return self.NewStageId
end

--#endregion



--#region 按钮交互相关

function XUiRpgMakerGameMain:AutoAddListener()
    self:RegisterClickEvent(self.SceneBtnBack, self.Close)
    self:RegisterClickEvent(self.SceneBtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnActive, self.OnBtnActiveClick)
    self:UpdateHelpBtn()
end

function XUiRpgMakerGameMain:UpdateHelpBtn()
    self:BindHelpBtn(self.BtnActDesc, XRpgMakerGameConfigs.GetChapterGroupHelpKey(self.CurChapterGroupId))
end

---往期玩法按钮
function XUiRpgMakerGameMain:OnBtnActiveClick()
    local closeCb = function(chapterGroupId)
        self:UpdateCurChapterGroupId(chapterGroupId)
        self:UpdateHelpBtn()
        self:InitTabGroup()
        self:UpdateTabIndex()
        self:UpdateNewStageId()
        self:Refresh()
    end
    XLuaUiManager.Open("UiFubenRpgMakerGameTanChuang", closeCb, self.CurChapterGroupId)
end

function XUiRpgMakerGameMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRpgMakerGameMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiRpgMakerGamePlayTask")
end

--#endregion