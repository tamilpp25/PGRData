--章节选择界面
local XUiBrilliantWalkChapter = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkChapter")
local XUIBrilliantWalkMiniTaskPanel = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkMiniTaskPanel")--任务miniUI


function XUiBrilliantWalkChapter:OnAwake()
    --初始化章节按钮
    self.ChapterList = {}
    local index = 1
    while(self["Chapter"..index]) do
        table.insert(self.ChapterList,self["Chapter"..index])
        index = index+1
    end
    --界面右边普通模块界面
    self.UiTaskPanel = XUIBrilliantWalkMiniTaskPanel.New(self.BtnTask,self)
    
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    --上锁的章节UI按钮
    self.LockChapterBtn = {}
    --定时器
    self._Timer = nil
end
function XUiBrilliantWalkChapter:OnEnable(openUIData)
    if openUIData.OnStart then
        self:PlayAnimationWithMask("AnimEnable1")
    else
        self:PlayAnimationWithMask("QieHuanEnable")
    end
    self:UpdateView()
    self.UiTaskPanel:OnEnable()
    self.ParentUi:SwitchSceneCamera(XBrilliantWalkCameraType.Chapter)
end
function XUiBrilliantWalkChapter:OnDisable()
    self.UiTaskPanel:OnDisable()
    self:StopTimer()
end
--刷新视图
function XUiBrilliantWalkChapter:UpdateView()
    self.LockChapterBtn = {}
    --刷新主线章节选择
    local viewData = XDataCenter.BrilliantWalkManager.GetUiDataChapterSelect()
    for index,btnChapter in pairs(self.ChapterList) do
        btnChapter.gameObject:SetActiveEx(true)
        if viewData.ChapterUnlock[index] == true then --已解锁
            btnChapter:SetDisable(false)
            btnChapter:SetNameByGroup(0, viewData.chapterConfig[index].Name)
            btnChapter.CallBack = function() self:OnChapterClick(viewData.chapterConfig[index].Id) end
        elseif (viewData.ChapterUnlock[index] == false) or (type(viewData.ChapterUnlock[index]) == "number") then --未解锁
            local chapterId = viewData.chapterConfig[index] and viewData.chapterConfig[index].Id
            btnChapter:SetDisable(true)
            btnChapter:SetNameByGroup(0, viewData.chapterConfig[index].Name)
            local lockMsg = ""
            if XDataCenter.BrilliantWalkManager.GetChapterIsOpen(chapterId) then
                local preChapterConfig = XBrilliantWalkConfigs.GetChapterConfig(viewData.ChapterUnlock[index])
                lockMsg = CsXTextManagerGetText("BrilliantWalkChapterUnlock",preChapterConfig.Name)
            else
                table.insert(self.LockChapterBtn,{btn = btnChapter,chapter = chapterId})
                lockMsg = XDataCenter.BrilliantWalkManager.GetChapterOpenTimeMsg(chapterId)
            end
            btnChapter:SetNameByGroup(1, lockMsg)
            btnChapter.CallBack = function() self:OnLockChapterClick(lockMsg,chapterId) end
        else --无关卡
            btnChapter.gameObject:SetActiveEx(false)
        end
    end
    self.BtnTask:SetNameByGroup(1, viewData.TaskRewardProgress)
    self.BtnTask:SetNameByGroup(2, "/" .. viewData.MaxTaskRewardProgress)

    --任务miniUI视图
    self.UiTaskPanel:UpdateView()
    
    --开启章节开放倒计时定时器
    self:StartTimer()
end
--开启章节开放倒计时
function XUiBrilliantWalkChapter:StartTimer()
    if self._Timer then
        self:StopTimer()
    end
    if #self.LockChapterBtn == 0 then return end
    self._Timer = XScheduleManager.ScheduleForever(
        function()
            self:ChapterOpenTick()
        end,
        XScheduleManager.SECOND
    )
end
--关闭章节开放倒计时
function XUiBrilliantWalkChapter:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end
--章节开放倒计时TickFunction
function XUiBrilliantWalkChapter:ChapterOpenTick()
    local newUnlock = false
    for index,btnChapter in pairs(self.LockChapterBtn) do
        local chapterId = btnChapter.chapter
        local btn = btnChapter.btn
        if XDataCenter.BrilliantWalkManager.GetChapterIsOpen(chapterId) then
            newUnlock = true
        else
            local lockMsg = XDataCenter.BrilliantWalkManager.GetChapterOpenTimeMsg(chapterId)
            btn:SetNameByGroup(1, lockMsg)
        end
    end
    if newUnlock then
        UpdateView()
    end 
end

--点击返回按钮
function XUiBrilliantWalkChapter:OnBtnBackClick()
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkChapter:OnBtnHelpClick()
    XUiManager.ShowHelpTip("BrilliantWalk")
end
--点击任务按钮
function XUiBrilliantWalkChapter:OnBtnTaskClick()
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkTask")
end
--点击章节按钮
function XUiBrilliantWalkChapter:OnChapterClick(chpaterId)
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkChapterStage",{
        ChapterID = chpaterId
    })
end
--点击未接诶所章节按钮
function XUiBrilliantWalkChapter:OnLockChapterClick(msg,chapterId)
    if not XDataCenter.BrilliantWalkManager.GetChapterIsOpen(chapterId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BrilliantWalkChapterTimeTip"))
        return 
    end
    XUiManager.TipMsg(msg)
end