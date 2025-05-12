---@class XUiMainLine2Chapter:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2Chapter = XLuaUiManager.Register(XLuaUi, "UiMainLine2Chapter")

function XUiMainLine2Chapter:OnAwake()
    self.RewardUiObjs = { self.GridReward }
    self.JumpBtns = { self.BtnJump }
    
    self:RegisterUiEvents()
end

function XUiMainLine2Chapter:OnStart(mainId, chapterId, stageId, isOpenStageDetail)
    self.MainId = mainId
    self.CurChapterId = chapterId
    self.SkipStageId = stageId
    self.IsOpenStageDetail = isOpenStageDetail
    self.ChapterIds = self._Control:GetMainChapterIds(mainId)

    -- 进战斗/播剧情后恢复界面
    local resumeData = self._Control:GetMainReleaseData(self.MainId)
    if resumeData then 
        self._Control:CacheMainReleaseData(self.MainId, nil)
        self.CurChapterId = resumeData.ChapterId
        self.SkipStageId = resumeData.StageId
        self.IsOpenStageDetail = false
    end
    
    -- 未播放章节切换效果
    if not self.CurChapterId then
        local mainId = self._Control:GetClientConfigParams("SwitchEffectMainId", 1)
        if mainId and tonumber(mainId) == self.MainId then
            for i = 1, #self.ChapterIds - 1 do
                local cId = self.ChapterIds[i]
                local isPlay = self._Control:GetIsPlaySwitchEnterEffect(cId)
                if not isPlay then
                    self.CurChapterId = cId
                    break
                end
            end
        end
        if self.CurChapterId then
            self.SkipStageId = self._Control:GetChapterLastStageId(self.CurChapterId)
            self.IsOpenStageDetail = false
        end
    end
    
    -- 显示未通关的章节
    if not self.CurChapterId then
        for _, cId in ipairs(self.ChapterIds) do
            local isPass = self._Control:IsChapterPassed(cId)
            if not isPass then
                self.CurChapterId = cId
                break
            end
        end
    end

    -- 默认/全通关打开第一个章节
    if not self.CurChapterId then
        self.CurChapterId = self.ChapterIds[1]
    end

    local isContain, chapterIndex = table.contains(self.ChapterIds, self.CurChapterId)
    self.CurChapterIndex = chapterIndex
    self.IsSelectingDifficulty = false -- 正在选择难度
    self.ChapterPrefabName = nil
    self.UiNodeChapterDic = {}
    self.LastClickStageId = nil -- 最后一次点击的关卡Id

    self:InitDifficultyUi()
    self:InitActivityTimer()
end

function XUiMainLine2Chapter:OnEnable()
    self:Refresh()
    self:CheckPlayEffect()
end

function XUiMainLine2Chapter:OnRelease()
    self:ClearActivityTimer()
    self:ClearCaptureUITimer()
    self:ClearLoadEffectTimer()
    self:ClearSwitchChapterTimer()

    self.CurChapterId = nil
    self.CurChapterIndex = nil
    self.ChapterIds = nil
    self.IsSelectingDifficulty = nil
    self.ChapterPrefabName = nil
    self.ChapterLinkGos = nil
    self.BtnDifficultUiObjs = nil
    self.BtnDifficults = nil
end

function XUiMainLine2Chapter:OnReleaseInst()
    local data = { ChapterId = self.CurChapterId, StageId = self.LastClickStageId }
    self._Control:CacheMainReleaseData(self.MainId, data)
end

function XUiMainLine2Chapter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnCloseDifficult, self.CloseDifficultyList)
    self:RegisterClickEvent(self.BtnAchievement, self.OnBtnAchievementClick)
end

function XUiMainLine2Chapter:OnBtnBackClick()
    self:Close()
end

function XUiMainLine2Chapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMainLine2Chapter:OnBtnDifficultyClick(index)
    if self.IsSelectingDifficulty then
        self:OnSelectDifficulty(index)
    else
        self:OpenDifficultyList()
    end
end

-- 选中一个难度
function XUiMainLine2Chapter:OnSelectDifficulty(index)
    local chapterId = self.ChapterIds[index]
    local isUnlock, tips = self._Control:IsChapterUnlock(chapterId)
    if not isUnlock then
        XUiManager.TipMsg(tips)
        return
    end

    if self.CurChapterIndex ~= index then
        self:SwitchChapter(index)
    else
        self:CloseDifficultyList()
    end
end

-- 打开难度列表
function XUiMainLine2Chapter:OpenDifficultyList()
    self.IsSelectingDifficulty = true
    self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    for i, chapterId in ipairs(self.ChapterIds) do
        local btn = self.BtnDifficults[i]
        btn.gameObject:SetActiveEx(true)
        if self.CurChapterIndex == i then
            btn.transform:SetAsFirstSibling()
            btn:ShowReddot(false)
        else
            btn.transform:SetAsLastSibling()
            local isRed = self._Control:IsChapterRed(chapterId)
            btn:ShowReddot(isRed)
        end
    end
end

-- 关闭难度列表
function XUiMainLine2Chapter:CloseDifficultyList()
    self.IsSelectingDifficulty = false
    self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    for _, btnDifficult in ipairs(self.BtnDifficults) do
        btnDifficult.gameObject:SetActiveEx(false)
    end

    local isRed = false
    for _, chapterId in ipairs(self.ChapterIds) do
        if self.CurChapterId ~= chapterId then
            isRed = isRed or self._Control:IsChapterRed(chapterId)
        end
    end

    local btn = self.BtnDifficults[self.CurChapterIndex]
    btn.gameObject:SetActiveEx(true)
    btn:ShowReddot(isRed)
end

function XUiMainLine2Chapter:OnBtnAchievementClick()
    local isGet = self._Control:IsAchievementGet(self.MainId)
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local curCnt, maxCnt = agency:GetMainAchievementProgress(self.MainId)
    if not isGet and curCnt >= maxCnt then
        XMVCA:GetAgency(ModuleId.XMainLine2):RequestReceiveAchievement(self.MainId, function()
            self:RefreshAchievements()
        end)
    else
        local achievementId = self._Control:GetMainAchievementId(self.MainId)
        local rewardId = self._Control:GetAchievementClearRewardId(achievementId)
        local rewardList = XRewardManager.GetRewardList(rewardId)
        local itemTemplateId = rewardList[1].TemplateId
        local data = XDataCenter.MedalManager.GetScoreTitleById(itemTemplateId)
        XLuaUiManager.Open("UiCollectionTip", data, XDataCenter.MedalManager.InType.Normal)
    end
end

function XUiMainLine2Chapter:OnBtnJumpClick(skipId)
    XFunctionManager.SkipInterface(skipId)
end

-- 初始化难度UI显示
function XUiMainLine2Chapter:InitDifficultyUi()
    self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    self.ChapterLinkGos = {}
    self.BtnDifficultUiObjs = {}
    self.BtnDifficults = {}
    
    -- 刷新切换按钮描述
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local CSColorUtility = CS.UnityEngine.ColorUtility
    for i, chapterId in ipairs(self.ChapterIds) do
        local parentGo = i == 1 and self.Chapter or CSInstantiate(self.Chapter.gameObject, self.Chapter.transform.parent)
        self.ChapterLinkGos[i] = parentGo
        
        local btn = i == 1 and self.BtnDifficult or CSInstantiate(self.BtnDifficult, self.PanelTopDifficult)
        local uiObj = btn:GetComponent("UiObject")
        self.BtnDifficults[i] = btn
        self.BtnDifficultUiObjs[i] = uiObj
        
        local name = self._Control:GetChapterDifficultName(chapterId)
        local enName = self._Control:GetChapterDifficultEnName(chapterId)
        local colorString = self._Control:GetChapterDifficultColor(chapterId)
        local isSuccess, color = CSColorUtility.TryParseHtmlString(colorString)
        uiObj:GetObject("TextName").text = name
        uiObj:GetObject("TextEn").text = enName
        if isSuccess then
            btn:SetColor(color)
        end

        -- 点击回调
        local index = i
        btn.CallBack = function() 
            self:OnBtnDifficultyClick(index)
        end

        -- 显示当前模式按钮
        btn.gameObject:SetActiveEx(self.CurChapterIndex == i)
    end
end

-- 初始化活动时间定时器
function XUiMainLine2Chapter:InitActivityTimer()
    local mainCfg = self._Control:GetConfigMain(self.MainId)
    local characterId = mainCfg.ChapterIds[1]

    -- 未配置
    local timerId = self._Control:GetChapterActivityTimeId(characterId)
    if timerId == 0 then
        self.PanelActivityTime.gameObject:SetActiveEx(false)
        return
    end

    -- 超过限时开放时间
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(timerId)
    local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
    if leftTime < 0 then
        self.PanelActivityTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self:ClearActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        leftTime = self.EndTime - XTime.GetServerNowTimestamp()
        if leftTime < 0 then
            local isUnLock = self._Control:IsChapterUnlock(characterId)
            if isUnLock then
                self:ClearActivityTimer()
                self.PanelActivityTime.gameObject:SetActiveEx(false)
            else
                XDataCenter.FubenMainLineManager.OnActivityEnd()
            end
        else
            self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        end
    end, XScheduleManager.SECOND)
end

function XUiMainLine2Chapter:ClearActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiMainLine2Chapter:SwitchChapter(index)
    self.CurChapterIndex = index
    self.CurChapterId = self.ChapterIds[index]
    self:CloseDifficultyList()
    self:Refresh()
end

-- 刷新界面
function XUiMainLine2Chapter:Refresh()
    self:RefreshTitle()
    self:RefreshDifficultyProgress()
    self:LoadChapterPrefab()
    self:RefreshAchievements()
    self:RefreshRewards()
    self:RefreshJumpBtnList()
end

-- 刷新标题
function XUiMainLine2Chapter:RefreshTitle()
    local mainCfg = self._Control:GetConfigMain(self.MainId)
    self.TxtChapter.text = mainCfg.Title
    self.TxtChapterName.text = mainCfg.Name

    local desc = self._Control:GetChapterDesc(self.CurChapterId)
    local isShowDesc = desc and desc ~= ""
    self.TextChapterDesc.gameObject:SetActiveEx(isShowDesc)
    if isShowDesc then 
        self.TextChapterDesc.text = desc
    end
end

-- 更新难度进度
function XUiMainLine2Chapter:RefreshDifficultyProgress()
    -- 只有1个章节不显示
    if #self.ChapterIds <= 1 then
        self.PanelTopDifficult.gameObject:SetActiveEx(false)
        return
    end
    
    -- 配置隐藏时，需要全通关才显示
    local isShow = not self._Control:GetMainHideChapterOption(self.MainId) or self._Control:IsMainPassed(self.MainId)
    self.PanelTopDifficult.gameObject:SetActiveEx(isShow)
    if isShow then
        for i, chapterId in ipairs(self.ChapterIds) do
            local uiObj = self.BtnDifficultUiObjs[i]
            local btn = self.BtnDifficults[i]
            local passCnt, maxCnt = self._Control:GetChapterProgress(chapterId)
            local progress = math.floor(passCnt * 100 / maxCnt)
            local isUnlock, tips = self._Control:IsChapterUnlock(chapterId)
            btn:SetDisable(not isUnlock)
            uiObj:GetObject("TextProgress").text = progress
        end
    end
end

-- 加载章节预制体
function XUiMainLine2Chapter:LoadChapterPrefab()
    self._Control:CacheChapterMainId(self.CurChapterId, self.MainId)
    self.ChapterPrefabName = self._Control:GetChapterPrefabName(self.CurChapterId)

    -- 隐藏其他章节
    for i, go in pairs(self.ChapterLinkGos) do
        local node = self.UiNodeChapterDic[i]
        if node then
            node:Close()
        end
    end

    -- 显示当前章节
    local uiNode = self.UiNodeChapterDic[self.CurChapterIndex]
    if not uiNode  then
        local parentGo = self.ChapterLinkGos[self.CurChapterIndex]
        local prefab = parentGo:LoadPrefab(self.ChapterPrefabName)
        local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")
        uiNode = XUiMainLine2PanelEntranceList.New(prefab, self, self.CurChapterId, self.MainId, self.SkipStageId, self.IsOpenStageDetail)
        self.UiNodeChapterDic[self.CurChapterIndex] = uiNode

        self.SkipStageId = nil
        self.IsOpenStageDetail = nil
    end
    uiNode:Open()
end

-- 刷新章节成就
function XUiMainLine2Chapter:RefreshAchievements()
    local achievementId = self._Control:GetMainAchievementId(self.MainId)
    local isShow = achievementId ~= 0
    self.BtnAchievement.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local curCnt, maxCnt = agency:GetMainAchievementProgress(self.MainId)
    local progressFormat = self._Control:GetClientConfigParams("AchievementProgress", 1)
    self.TxtAchievementProgress.text = string.format(progressFormat, curCnt, maxCnt)
    
    local isUnlock = curCnt >= maxCnt
    local isGet = self._Control:IsAchievementGet(self.MainId)
    local isRed = isUnlock and not isGet
    self.BtnAchievement:ShowReddot(isRed)
    self.ImgAchievementComplete.gameObject:SetActiveEx(isGet)

    local icon = self._Control:GetAchievementIcon(achievementId)
    local iconLock = self._Control:GetAchievementIconLock(achievementId)
    self.RImgAchievement.gameObject:SetActiveEx(not isUnlock)
    self.RImgAchievementUnlock.gameObject:SetActiveEx(isUnlock)
    self.RImgAchievement:SetRawImage(iconLock)
    self.RImgAchievementUnlock:SetRawImage(icon)
end

-- 刷新奖励
function XUiMainLine2Chapter:RefreshRewards()
    local mainCfg = self._Control:GetConfigMain(self.MainId)
    self.IsShowMainReward = mainCfg.TreasureId ~= 0 -- true为显示主章节奖励，false为显示单个章节奖励
    if self.IsShowMainReward then
        self:RefreshMainRewards()
    else
        self:RefreshChapterRewards()
    end
end

-- 刷新主章节奖励
function XUiMainLine2Chapter:RefreshMainRewards()
    self.PanelReward.gameObject:SetActiveEx(false)

    -- 无配置进度奖励，不显示
    local mainCfg = self._Control:GetConfigMain(self.MainId)
    local treasureId = mainCfg.TreasureId
    if treasureId == 0 then
        return
    end

    -- 奖励全部领取完，不显示
    local isTreasureFinish = self._Control:IsMainTreasureFinish(self.MainId)
    if isTreasureFinish then
        return
    end
    
    -- 通关进度
    self.PanelReward.gameObject:SetActiveEx(true)
    local passCnt, maxCnt = self._Control:GetMainProgress(self.MainId)
    self.TxtClearNum.text = tostring(passCnt)
    self.TxtAllNum.text = "/" .. tostring(maxCnt)

    -- 隐藏奖励item
    for _, uiObj in ipairs(self.RewardUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    -- 刷新奖励item
    local treasureCfg = self._Control:GetConfigTreasure(treasureId)
    local count = #treasureCfg.StageCounts
    local reachCnt = 0
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i = 1, count do
        local stageCount = treasureCfg.StageCounts[i]
        local highlightRewardId = treasureCfg.HighlightRewardIds[i]
        local rewardId = treasureCfg.RewardIds[i]

        local uiObj = self.RewardUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridReward.gameObject, self.PanelRewardList.transform)
            uiObj = go:GetComponent("UiObject")
            self.RewardUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)

        local isGet = self._Control:IsMainTreasureGet(self.MainId, i-1)
        local isReach = passCnt >= stageCount
        uiObj:GetObject("TxtValue").text = tostring(stageCount)

        -- 高亮奖励
        local rewardList1 = XRewardManager.GetRewardList(highlightRewardId)
        local itemObj1 = uiObj:GetObject("GridItem1")
        itemObj1:GetObject("GetTag").gameObject:SetActiveEx(isGet)
        itemObj1:GetObject("PanelEffect").gameObject:SetActiveEx(not isGet and isReach)
        local icon = XItemConfigs.GetItemIconById(rewardList1[1].TemplateId)
        itemObj1:GetObject("ImgIcon"):SetSprite(icon)
        itemObj1:GetObject("TxtNum").text = tostring(rewardList1[1].Count)
        itemObj1:GetObject("BtnClick").CallBack = function()
            self:OnBtnMainRewardClick(isGet, isReach, highlightRewardId)
        end

        -- 普通奖励
        local itemObj2 = uiObj:GetObject("GridItem2")
        itemObj2:GetObject("GetTag").gameObject:SetActiveEx(isGet)
        itemObj2:GetObject("PanelEffect").gameObject:SetActiveEx(not isGet and isReach)
        itemObj2:GetObject("TxtNum").gameObject:SetActiveEx(false)
        itemObj2:GetObject("BtnClick").CallBack = function()
            self:OnBtnMainRewardClick(isGet, isReach, rewardId)
        end

        local lastStageCount = i == 1 and 0 or treasureCfg.StageCounts[i-1]
        if passCnt >= stageCount then
            reachCnt = reachCnt + 1
        elseif passCnt > lastStageCount then
            reachCnt = reachCnt + (passCnt - lastStageCount)/(stageCount - lastStageCount)
        end
    end

    self.ImgProgress.fillAmount = reachCnt / count
end

-- 刷新章节奖励
function XUiMainLine2Chapter:RefreshChapterRewards()
    self.PanelReward.gameObject:SetActiveEx(false)

    -- 无配置进度奖励，不显示
    local chapterCfg = self._Control:GetConfigChapter(self.CurChapterId)
    local treasureId = chapterCfg.TreasureId
    if treasureId == 0 then
        return
    end

    -- 奖励全部领取完，不显示
    local isTreasureFinish = self._Control:IsChapterTreasureFinish(self.CurChapterId)
    if isTreasureFinish then
        return
    end

    -- 通关进度
    self.PanelReward.gameObject:SetActiveEx(true)
    local passCnt, maxCnt = self._Control:GetChapterProgress(self.CurChapterId)
    self.TxtClearNum.text = tostring(passCnt)
    self.TxtAllNum.text = "/" .. tostring(maxCnt)

    -- 隐藏奖励item
    for _, uiObj in ipairs(self.RewardUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    -- 刷新奖励item
    local treasureCfg = self._Control:GetConfigTreasure(treasureId)
    local count = #treasureCfg.StageCounts
    local reachCnt = 0
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i = 1, count do
        local stageCount = treasureCfg.StageCounts[i]
        local highlightRewardId = treasureCfg.HighlightRewardIds[i]
        local rewardId = treasureCfg.RewardIds[i]

        local uiObj = self.RewardUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridReward.gameObject, self.PanelRewardList.transform)
            uiObj = go:GetComponent("UiObject")
            self.RewardUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)

        local isGet = self._Control:IsTreasureGet(self.CurChapterId, i-1)
        local isReach = passCnt >= stageCount
        uiObj:GetObject("TxtValue").text = tostring(stageCount)

        -- 高亮奖励
        local rewardList1 = XRewardManager.GetRewardList(highlightRewardId)
        local itemObj1 = uiObj:GetObject("GridItem1")
        itemObj1:GetObject("GetTag").gameObject:SetActiveEx(isGet)
        itemObj1:GetObject("PanelEffect").gameObject:SetActiveEx(not isGet and isReach)
        local icon = XItemConfigs.GetItemIconById(rewardList1[1].TemplateId)
        itemObj1:GetObject("ImgIcon"):SetSprite(icon)
        itemObj1:GetObject("TxtNum").text = tostring(rewardList1[1].Count)
        itemObj1:GetObject("BtnClick").CallBack = function()
            self:OnBtnChapterRewardClick(isGet, isReach, highlightRewardId)
        end

        -- 普通奖励
        local itemObj2 = uiObj:GetObject("GridItem2")
        itemObj2:GetObject("GetTag").gameObject:SetActiveEx(isGet)
        itemObj2:GetObject("PanelEffect").gameObject:SetActiveEx(not isGet and isReach)
        itemObj2:GetObject("TxtNum").gameObject:SetActiveEx(false)
        itemObj2:GetObject("BtnClick").CallBack = function()
            self:OnBtnChapterRewardClick(isGet, isReach, rewardId)
        end

        local lastStageCount = i == 1 and 0 or treasureCfg.StageCounts[i-1]
        if passCnt >= stageCount then 
            reachCnt = reachCnt + 1
        elseif passCnt > lastStageCount then  
            reachCnt = reachCnt + (passCnt - lastStageCount)/(stageCount - lastStageCount)
        end
    end

    self.ImgProgress.fillAmount = reachCnt / count
end

-- 点击奖励
function XUiMainLine2Chapter:OnBtnChapterRewardClick(isGet, isReach, rewardId)
    if isReach and not isGet then
        XMVCA.XMainLine2:RequestReceiveTreasure(self.CurChapterId, function()
            self:RefreshRewards()
            self:RefreshJumpBtnList()
        end)
    else
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if #rewardList == 1 then
            XLuaUiManager.Open("UiTip", {Id = rewardList[1].TemplateId})
        else
            XUiManager.OpenUiTipRewardByRewardId(rewardId)
        end
    end
end

function XUiMainLine2Chapter:OnBtnMainRewardClick(isGet, isReach, rewardId)
    if isReach and not isGet then
        XMVCA.XMainLine2:ReceiveMainTreasureRequest(self.MainId, function()
            self:RefreshRewards()
            self:RefreshJumpBtnList()
        end)
    else
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if #rewardList == 1 then
            XLuaUiManager.Open("UiTip", {Id = rewardList[1].TemplateId})
        else
            XUiManager.OpenUiTipRewardByRewardId(rewardId)
        end
    end
end

-- 刷新章节对应Ui颜色
function XUiMainLine2Chapter:RefreshChapterUiColor(index)
    local chapterCfg = self._Control:GetConfigChapter(self.CurChapterId)
    local CSColorUtility = CS.UnityEngine.ColorUtility

    -- 标题
    if #chapterCfg.TitleTextColors > 0 then
        local colorString = chapterCfg.TitleTextColors[index]
        local isSuccess, color = CSColorUtility.TryParseHtmlString(colorString)
        if isSuccess then
            self.TxtChapter.color = color
            self.TxtChapterName.color = color
            self.BtnBack:SetColor(color)
            self.BtnMainUi:SetColor(color)
        end
    end

    -- 倒计时
    if #chapterCfg.LeftTimeTextColors > 0 then
        local colorString = chapterCfg.LeftTimeTextColors[index]
        local isSuccess, color = CSColorUtility.TryParseHtmlString(colorString)
        if isSuccess then
            self.TxtLeftTime.color = color
        end
    end

    -- 通关进度
    if #chapterCfg.ProgressTextColors > 0 then
        local colorString = chapterCfg.ProgressTextColors[index]
        local isSuccess, color = CSColorUtility.TryParseHtmlString(colorString)
        if isSuccess then
            for _, uiObj in ipairs(self.RewardUiObjs) do
                uiObj:GetObject("TxtValue").color = color
            end
        end
    end
end

-- 刷新跳转列表
function XUiMainLine2Chapter:RefreshJumpBtnList()
    for _, btn in ipairs(self.JumpBtns) do
        btn.gameObject:SetActiveEx(false)
    end

    -- 未全部通关不显示
    local isPass = self._Control:IsChapterPassed(self.CurChapterId)
    if not isPass then
        return
    end

    -- 奖励未领取完不显示
    local isMainTreasureFinish = self._Control:IsMainTreasureFinish(self.MainId)
    if not isMainTreasureFinish then 
        return 
    end
    local isTreasureFinish = self._Control:IsChapterTreasureFinish(self.CurChapterId)
    if not isTreasureFinish then
        return
    end

    local chapterCfg = self._Control:GetConfigChapter(self.CurChapterId)
    for i = 1, #chapterCfg.SkipIds do
        local condition = chapterCfg.SkipConditions[i]
        local icon = chapterCfg.SkipIcons[i]
        local name = chapterCfg.SkipNames[i]
        local skipId = chapterCfg.SkipIds[i]
        local chapterName = chapterCfg.SkipChapterNames[i] or ""

        ---@type XUiComponent.XUiButton
        local btn = self.JumpBtns[i]
        if not btn then
            local go = CS.UnityEngine.Object.Instantiate(self.BtnJump.gameObject, self.JumpBtnList.transform)
            btn = go:GetComponent("XUiButton")
            self.JumpBtns[i] = btn
        end

        local isReach, desc = XConditionManager.CheckCondition(condition)
        btn.gameObject:SetActiveEx(isReach)
        btn:SetNameByGroup(0, name)
        btn:SetNameByGroup(1, chapterName)
        btn:SetRawImageEx(icon)
        btn.CallBack = function()
            self:OnBtnJumpClick(skipId)
        end
    end
end

-- 检测是否播放特效
function XUiMainLine2Chapter:CheckPlayEffect()
    local isFirst = self:CheckFirstEnterEffect()
    if isFirst then return end

    -- 自动切换章节特效
    self:CheckAutoSwitchChapter()
end

-- 检查是否播第一次进入特效
function XUiMainLine2Chapter:CheckFirstEnterEffect()
    -- 不是指定主章节，不自动切
    local mainId = self._Control:GetClientConfigParams("FirstEnterEffectMainId", 1)
    if mainId and tonumber(mainId) ~= self.MainId then return end

    -- 第一关已经通过，不自动切
    if self.ChapterIds[1] ~= self.CurChapterId then return end
    local passCnt, maxCnt = self._Control:GetChapterProgress(self.CurChapterId)
    if passCnt > 0 then return end
    
    -- 记录播放过，不自动切
    local isPlay = self._Control:GetIsPlayFirstEnterEffect(self.MainId)
    if isPlay then return end
    
    -- 加载假章节
    local prefabPath = self._Control:GetClientConfigParams("FirstEnterPrefab", 1)
    self.ChapterTemp:LoadPrefab(prefabPath)
    self.ChapterTemp:SetAsLastSibling()

    -- 隐藏部分UI
    self.TextChapterDesc.gameObject:SetActiveEx(false)
    self.PanelTopDifficult.gameObject:SetActiveEx(false)

    XLuaUiManager.SetMask(true)
    local UI_ENABLE_TIME = 500 -- 界面enable动画时长
    local DELAY_CAPTURE_UI_TIME = UI_ENABLE_TIME + 300 -- 延迟截图的时间
    local DELAY_LOAD_EFFECT_TIME = DELAY_CAPTURE_UI_TIME + 200 -- 延迟加载特效时间
    local DELAY_SWITCH_TIME = DELAY_LOAD_EFFECT_TIME + 1500 -- 延迟切换章节时间

    -- 截图屏幕
    self:ClearCaptureUITimer()
    self.CaptureUITimer = XScheduleManager.ScheduleOnce(function()
        local component = self.Effect.gameObject:AddComponent(typeof(CS.XACaptureUIScreenTrigger))
        component.enabled = false
        component.enabled = true
    end, DELAY_CAPTURE_UI_TIME)

    -- 加载特效
    self:ClearLoadEffectTimer()
    self.LoadEffectTimer = XScheduleManager.ScheduleOnce(function()
        local effectPath = self._Control:GetClientConfigParams("SwitchChapterEffect", 1)
        self.Effect:LoadPrefab(effectPath)
    end, DELAY_LOAD_EFFECT_TIME)

    -- 隐藏假章节，显示正确章节
    self:ClearSwitchChapterTimer()
    self.SwitchChapterTimer = XScheduleManager.ScheduleOnce(function()
        -- 记录已播放
        self._Control:SetIsPlayFirstEnterEffect(self.MainId)
        self.ChapterTemp.gameObject:SetActiveEx(false)
        XLuaUiManager.SetMask(false)

        -- 恢复隐藏的UI
        self:RefreshTitle()
        self:RefreshDifficultyProgress()
    end, DELAY_SWITCH_TIME)
end

-- 检查是否自动切换章节
function XUiMainLine2Chapter:CheckAutoSwitchChapter()
    -- 不是指定主章节，不自动切
    local mainId = self._Control:GetClientConfigParams("SwitchEffectMainId", 1)
    if mainId and tonumber(mainId) ~= self.MainId then return end
    
    -- 没有下一个章节，不自动切
    if self.CurChapterIndex >= #self.ChapterIds then return end
    
    -- 所有章节全通，不自动切
    local isMainPassed = self._Control:IsMainPassed(self.MainId)
    if isMainPassed then return end
    
    -- 当前章节未全通，不自动切
    local isChapterPassed = self._Control:IsChapterPassed(self.CurChapterId)
    if not isChapterPassed then return end

    -- 播放过，不自动切
    local isPlay = self._Control:GetIsPlaySwitchEnterEffect(self.CurChapterId)
    if isPlay then return end

    XLuaUiManager.SetMask(true)
    local UI_ENABLE_TIME = 500 -- 界面enable动画时长
    local DELAY_CAPTURE_UI_TIME = UI_ENABLE_TIME + 300 -- 延迟截图的时间
    local DELAY_LOAD_EFFECT_TIME = DELAY_CAPTURE_UI_TIME + 200 -- 延迟加载特效时间
    local DELAY_SWITCH_TIME = DELAY_LOAD_EFFECT_TIME + 1500 -- 延迟切换章节时间

    -- 截图屏幕
    self:ClearCaptureUITimer()
    self.CaptureUITimer = XScheduleManager.ScheduleOnce(function()
        local component = self.Effect.gameObject:AddComponent(typeof(CS.XACaptureUIScreenTrigger))
        component.enabled = false
        component.enabled = true
    end, DELAY_CAPTURE_UI_TIME)

    -- 加载特效
    self:ClearLoadEffectTimer()
    self.LoadEffectTimer = XScheduleManager.ScheduleOnce(function()
        local effectPath = self._Control:GetClientConfigParams("SwitchChapterEffect", 1)
        self.Effect:LoadPrefab(effectPath)
    end, DELAY_LOAD_EFFECT_TIME)
    
    -- 切换下一章节
    self:ClearSwitchChapterTimer()
    self.SwitchChapterTimer = XScheduleManager.ScheduleOnce(function()
        -- 记录已播放
        self._Control:SetIsPlaySwitchEnterEffect(self.CurChapterId)
        -- 切换
        self:SwitchChapter(self.CurChapterIndex + 1)
        XLuaUiManager.SetMask(false)
    end, DELAY_SWITCH_TIME)
end

-- 清除延迟截图屏幕定时器
function XUiMainLine2Chapter:ClearCaptureUITimer()
    if self.CaptureUITimer then
        XScheduleManager.UnSchedule(self.CaptureUITimer)
        self.CaptureUITimer = nil
    end
end

-- 清除延迟播特效定时器
function XUiMainLine2Chapter:ClearLoadEffectTimer()
    if self.LoadEffectTimer then
        XScheduleManager.UnSchedule(self.LoadEffectTimer)
        self.LoadEffectTimer = nil
    end
end

-- 清除切换章节定时器
function XUiMainLine2Chapter:ClearSwitchChapterTimer()
    if self.SwitchChapterTimer then
        XScheduleManager.UnSchedule(self.SwitchChapterTimer)
        self.SwitchChapterTimer = nil
    end
end

function XUiMainLine2Chapter:SetLastClickStageId(stageId)
    self.LastClickStageId = stageId
end

return XUiMainLine2Chapter