local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 这里其实是stage选择界面
local XUiPlanetChapterChoice = XLuaUiManager.Register(XLuaUi, "UiPlanetChapterChoice")

function XUiPlanetChapterChoice:OnAwake()
    self:InitObj()
    self:AddBtnClickListener()
    self.GridPanelStage.gameObject:SetActiveEx(false)
    self.GridStage = {}
    self.GridStageObj = {}
    self._IsFirstEnable = true
    
    self.UnlockAnim = self.Transform:Find("Animation/PanelLockDisable"):GetComponent("PlayableDirector")
    if self.UnlockAnim then -- 音效挂在动画上,避免出声手动关闭
        self.UnlockAnim.gameObject:SetActiveEx(false)
        self.UnlockDuration = self.UnlockAnim.duration * 0.95
    end
end

function XUiPlanetChapterChoice:OnStart(curChapterIdIndex)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XPlanetConfigs.SoundCueId.CamNear)
    self.CurChapterIdIndex = curChapterIdIndex or self.CurChapterIdIndex 
    self.ViewModel = XDataCenter.PlanetManager.GetViewModel()
end

function XUiPlanetChapterChoice:OnEnable()
    if not self._IsFirstEnable then    -- 关卡返航需要黑幕动画
        self:PlayAnimationWithMask("DarkEnable")
    end
    self.ChapterList = XDataCenter.PlanetManager.GetShowChapterList()

    if not XTool.IsNumberValid(self.CurChapterIdIndex) then return end
    local isPlayAnim = self:CheckUnLockAim()
    -- 镜头
    self:RefreshUi()
    self.PlanetMainScene:UpdateCameraInChapterChoice(self.ChapterList[self.CurChapterIdIndex], function()
        self:OpenUi()
        self:PlayAnimationWithMask("QieHuanEnable", function()
            if isPlayAnim then
                self:PlayUnlockAnim()
            end
        end)
    end)
    self._IsFirstEnable = false
end

function XUiPlanetChapterChoice:OnDisable()
    self:StopRefreshLock()
end

--region Data&Obj
function XUiPlanetChapterChoice:InitObj()
    self.PanelFight = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelFight")
    self.RImgChapterIcon = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelFight/RImg", "RawImage")
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.ChapterList = XDataCenter.PlanetManager.GetShowChapterList()
    self.CurChapterIdIndex = 1
end

function XUiPlanetChapterChoice:CheckCurChapterIdIndex()
    if XTool.IsTableEmpty(self.ChapterList) then
        self.CurChapterIdIndex = 0
        return
    end
    if self.CurChapterIdIndex > #self.ChapterList then
        self.CurChapterIdIndex = 1
    end
    if self.CurChapterIdIndex <= 0 then
        self.CurChapterIdIndex = #self.ChapterList
    end
end
--endregion

--region Ui刷新
function XUiPlanetChapterChoice:RefreshCam()
    -- 镜头
    self:RefreshUi()
    self.PlanetMainScene:UpdateCameraInChapterChoice(self.ChapterList[self.CurChapterIdIndex],nil, function()
        self:OpenUi()
        self:PlayAnimationWithMask("QieHuanEnable")
    end)
end

function XUiPlanetChapterChoice:OpenUi()
     self.PanelFight.gameObject:SetActiveEx(true)
     self.BtnBack.gameObject:SetActiveEx(true)
     self.BtnMainUi.gameObject:SetActiveEx(true)
     self.BtnHelp.gameObject:SetActiveEx(true)
end

function XUiPlanetChapterChoice:HideUi()
     self.PanelFight.gameObject:SetActiveEx(false)
     self.BtnBack.gameObject:SetActiveEx(false)
     self.BtnMainUi.gameObject:SetActiveEx(false)
     self.BtnHelp.gameObject:SetActiveEx(false)
end

function XUiPlanetChapterChoice:RefreshUi()
    self:OpenUi()
    local curChapterId = self.ChapterList[self.CurChapterIdIndex]
    local titleIcon = XPlanetStageConfigs.GetChapterTitleIconUrl(curChapterId)
    local stageIdList = XPlanetStageConfigs.GetStageListByChapterId(self.ChapterList[self.CurChapterIdIndex])
    
    -- 标题图标
    self.RImgChapterIcon.gameObject:SetActiveEx(self:IsChapterUnLock(curChapterId))
    if not string.IsNilOrEmpty(titleIcon) then
        self.RImgChapterIcon:SetRawImage(titleIcon)
    end
    -- 箭头按钮
    self:RefreshBtnJiantou()
    -- 解锁状态
    self:RefreshLock()
    self:HideStage()
    
    if not self:IsChapterUnLock(curChapterId) then
        return
    end
    
    if XTool.IsTableEmpty(stageIdList) then
        XLog.Error("章节" .. self.ChapterList[self.CurChapterIdIndex] .. "未配置关卡")
        return
    end
    
    local stageUiRoot = #stageIdList == 4 and self.Double or self.Single

    for k, stageId in pairs(stageIdList) do
        local uiParent = stageUiRoot:Find("Stage"..k)
        local stageObj = self.GridStageObj[k]
        local gridStage = self.GridStage[k]
        if XTool.UObjIsNil(stageObj) then
            self.GridStageObj[k] =  CS.UnityEngine.Object.Instantiate(self.GridPanelStage, uiParent)
            stageObj = self.GridStageObj[k]
            stageObj.transform.localPosition = Vector3(0, 0, 0)
        end
        if stageObj.transform.parent ~= uiParent then
            stageObj.transform:SetParent(uiParent)
            stageObj.transform.localPosition = Vector3(0, 0, 0)
        end
        stageObj.gameObject:SetActiveEx(true)
        if not gridStage then
            gridStage = {}
            XTool.InitUiObjectByUi(gridStage, stageObj) -- 注册引用
            gridStage.GridRewardsDic = {}
            self.GridStage[k] = gridStage
        end
        self:RefreshStageGrid(stageId, k, gridStage)
    end
end

function XUiPlanetChapterChoice:RefreshLock()
    if not self.PanelLock then
        self:StopRefreshLock()
        return
    end
    local curChapterId = self.ChapterList[self.CurChapterIdIndex]
    local isUnLock = self:IsChapterUnLock(curChapterId)
    local isOpen = self.ViewModel:CheckChapterIsInTime(curChapterId)
    local isPassPreStage = self.ViewModel:CheckChapterPreStageIsPass(curChapterId)
    self.PanelLock.gameObject:SetActiveEx(not isUnLock)
    
    if not isUnLock then
        self.RImgLock.gameObject:SetActiveEx(isOpen and not isPassPreStage)
        self.RImgTime.gameObject:SetActiveEx(not isOpen)
        if not self.LockTimer and not isOpen then
            self:StartRefreshLock()
        end
        if not isOpen then
            local startTime = XPlanetStageConfigs.GetChapterOpenTime(curChapterId)
            local nowTime = XTime.GetServerNowTimestamp()
            self.TxtTime.text = XUiHelper.GetText("PivotCombatLockTimeTxt", XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY))
        end
    else
        self:StopRefreshLock()
    end
end

function XUiPlanetChapterChoice:StartRefreshLock()
    self.LockTimer = XScheduleManager.ScheduleForever(handler(self, self.RefreshLock), XScheduleManager.SECOND, 0)
end

function XUiPlanetChapterChoice:StopRefreshLock()
    if self.LockTimer then
        XScheduleManager.UnSchedule(self.LockTimer)
    end
    self.LockTimer = nil
end

function XUiPlanetChapterChoice:RefreshStageGrid(stageId, gridIndex, gridStage)
    -- 标题
    gridStage.TxtName.text = XPlanetStageConfigs.GetChapterName(self.ChapterList[self.CurChapterIdIndex])
    gridStage.Text.text = XPlanetStageConfigs.GetStageName(stageId)
    -- 状态
    gridStage.ImgSelect.gameObject:SetActiveEx(self.ViewModel:CheckStageUnlock(stageId) and not self.ViewModel:CheckStageIsPass(stageId))
    gridStage.BtnClear.gameObject:SetActiveEx(self.ViewModel:CheckStageIsPass(stageId))
    gridStage.BtnGo.gameObject:SetActiveEx(self.ViewModel:CheckStageUnlock(stageId) and not self.ViewModel:CheckStageIsPass(stageId))
    gridStage.BgLock.gameObject:SetActiveEx(not self.ViewModel:CheckStageUnlock(stageId))

    -- 刷新前先隐藏所有奖励
    local childCount = gridStage.PanelReward.childCount
    for j = 0, childCount - 1 do
        gridStage.PanelReward:GetChild(j).gameObject:SetActiveEx(false)
    end
    -- 奖励
    local rewards = {}
    local rewardId = XPlanetStageConfigs.GetStageRewardId(stageId)
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) 
    end
    for i, item in pairs(rewards) do
        local index = gridIndex * 100 + i
        local grid = gridStage.GridRewardsDic[index]
        -- 再生成/刷新奖励
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(gridStage.GridReward, gridStage.GridReward.parent)
            grid = XUiGridCommon.New(self, ui)
            gridStage.GridRewardsDic[index] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
    end
    gridStage.GridReward.gameObject:SetActiveEx(false)
    -- 点击stage
    XUiHelper.RegisterClickEvent(self, gridStage.BtnGo, function ()
        self:OnStageClick(stageId)
    end)

    XUiHelper.RegisterClickEvent(self, gridStage.BtnClear, function ()
        self:OnStageClick(stageId)
    end)
    
    -- 未解锁状态时点击提示
    XUiHelper.RegisterClickEvent(self, gridStage.Bg, function ()
        self:OnStageClick(stageId)
    end)
end

function XUiPlanetChapterChoice:HideStage()
    for _, obj in pairs(self.GridStageObj) do
        obj.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetChapterChoice:RefreshBtnJiantou()
    local isShowL = self.CurChapterIdIndex ~= 1
    local isShowR = self.CurChapterIdIndex ~= #self.ChapterList
    self.BtnJiantouL.gameObject:SetActiveEx(isShowL)
    self.BtnJiantouR.gameObject:SetActiveEx(isShowR)
end
--endregion

--region LockEffect
function XUiPlanetChapterChoice:IsChapterUnLock(chapterId)
    return self.ViewModel:CheckChapterIsUnlock(chapterId) and not self:CheckIsBePlayUnLock(chapterId)
end

function XUiPlanetChapterChoice:CheckUnLockAim()
    local isAnim, lockChapterList = XDataCenter.PlanetManager.CheckChapterUnlockRedPoint()
    if XTool.IsTableEmpty(lockChapterList) then
        self.BePlayChapterUnlockAnimList = false
    else
        self.BePlayChapterUnlockAnimList = lockChapterList
    end
    return isAnim
end

function XUiPlanetChapterChoice:CheckIsBePlayUnLock(chapterId)
    if not self.BePlayChapterUnlockAnimList then
        return false
    end
    return self.BePlayChapterUnlockAnimList[chapterId]
end

function XUiPlanetChapterChoice:PlayUnlockAnim()
    local curChapterId = self.ChapterList[self.CurChapterIdIndex]
    if not self:CheckIsBePlayUnLock(curChapterId) then
        local tempCurIndex = self.CurChapterIdIndex
        local unlockChapterId, _ = next(self.BePlayChapterUnlockAnimList)
        self.CurChapterIdIndex = table.indexof(self.ChapterList, unlockChapterId)
        self:CheckCurChapterIdIndex()
        self:PlayAnimationWithMask("QieHuanDisable", function ()
            self:RefreshUi()
            self.PlanetMainScene:UpdateCameraInChapterChoice(unlockChapterId, nil, function()
                self:OpenUi()
                self:PlayAnimationWithMask("QieHuanEnable", function()
                    self:_MoveUnlockAnim(tempCurIndex)
                end)
            end)
        end)
    else
        self:_UnlockAnim()
    end
end

function XUiPlanetChapterChoice:_MoveUnlockAnim(index)
    if self.UnlockAnim then -- 音效挂在动画上,手动打开
        self.UnlockAnim.gameObject:SetActiveEx(true)
    end
    self:PlayAnimationWithMask("PanelLockDisable", function ()
        self.BePlayChapterUnlockAnimList = false
        XDataCenter.PlanetManager.ClearChapterUnlockRedPoint()
        self:RefreshUi()
        self:PlayAnimationWithMask("QieHuanEnable", function()
            self:PlayAnimationWithMask("QieHuanDisable", function()
                self.CurChapterIdIndex = index
                self:RefreshUi()
                self.PlanetMainScene:UpdateCameraInChapterChoice(self.ChapterList[self.CurChapterIdIndex], nil, function()
                    self:OpenUi()
                    self:PlayAnimationWithMask("QieHuanEnable")
                end)
            end)
        end)
    end)
    self:_PlanetUnlockAnim()
end

function XUiPlanetChapterChoice:_UnlockAnim()
    if self.UnlockAnim then -- 音效挂在动画上,手动打开
        self.UnlockAnim.gameObject:SetActiveEx(true)
    end
    self:PlayAnimationWithMask("PanelLockDisable", function()
        self.BePlayChapterUnlockAnimList = false
        XDataCenter.PlanetManager.ClearChapterUnlockRedPoint()
        self:RefreshUi()
        self:PlayAnimationWithMask("QieHuanEnable")
    end)
    self:_PlanetUnlockAnim()
end

function XUiPlanetChapterChoice:_PlanetUnlockAnim()
    XUiHelper.Tween(self.UnlockDuration or 0.5, function(t)
        self.PlanetMainScene:PlayChapterPlanetUnlock(true, t)
    end, function()
        self.PlanetMainScene:PlayChapterPlanetUnlock(false, 1)
    end)
end
--endregion

--region 按钮绑定
function XUiPlanetChapterChoice:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XPlanetConfigs.GetHelpKey())

    XUiHelper.RegisterClickEvent(self, self.BtnJiantouR, self.OnBtnJiantouRClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJiantouL, self.OnBtnJiantouLClick)
end

function XUiPlanetChapterChoice:OnBtnCloseClick()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XPlanetConfigs.SoundCueId.CamFar)
    self:Close()
end

-- 点击stage上的前往按钮
function XUiPlanetChapterChoice:OnStageClick(stageId)
    if not self.ViewModel:CheckStageUnlock(stageId) then
        local preStageId = XPlanetStageConfigs.GetStagePreStageId(stageId)
        local stageName = XPlanetStageConfigs.GetStageFullName(preStageId)
        XUiManager.TipError(XUiHelper.GetText("PlanetRunningTalentCardLock", stageName))
        return
    end
    XLuaUiManager.Open("UiPlanetExplore", stageId)
end

function XUiPlanetChapterChoice:OnBtnJiantouRClick()
    self.CurChapterIdIndex = self.CurChapterIdIndex + 1
    self:CheckCurChapterIdIndex()
    self:PlayAnimationWithMask("QieHuanDisable", function ()
        self:HideUi()
        self:RefreshCam()
    end)
end

function XUiPlanetChapterChoice:OnBtnJiantouLClick()
    self.CurChapterIdIndex = self.CurChapterIdIndex - 1
    self:CheckCurChapterIdIndex()
    self:PlayAnimationWithMask("QieHuanDisable", function ()
        self:HideUi()
        self:RefreshCam()
    end)
end
--endregion