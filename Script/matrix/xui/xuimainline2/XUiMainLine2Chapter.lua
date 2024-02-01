---@class XUiMainLine2Chapter:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2Chapter = XLuaUiManager.Register(XLuaUi, "UiMainLine2Chapter")

function XUiMainLine2Chapter:OnAwake()
    self:InitUiObj()
    self:RegisterUiEvents()
end

function XUiMainLine2Chapter:OnStart(mainId, chapterId, stageId, isOpenStageDetail)
    self.MainId = mainId
    self.CurChapterId = chapterId
    self.SkipStageId = stageId
    self.IsOpenStageDetail = isOpenStageDetail

    local mainCfg = self._Control:GetConfigMain(mainId)
    self.CurDifficulty = self._Control:GetChapterDifficult(self.CurChapterId)
    self.ChapterIds = mainCfg.ChapterIds
    self.IsSelectingDifficulty = false -- 正在选择难度
    self.ChapterPrefabName = nil
    self.UiNodeChapterDic = {}

    self:InitDifficultyUi()
    self:InitActivityTimer()
end

function XUiMainLine2Chapter:OnEnable()
    self:Refresh()
end

function XUiMainLine2Chapter:OnRelease()
    self:ClearActivityTimer()

    self.CurChapterId = nil
    self.CurDifficulty = nil
    self.ChapterIds = nil
    self.IsSelectingDifficulty = false
    self.ChapterPrefabName = nil
end

function XUiMainLine2Chapter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnCloseDifficult, self.CloseDifficultyList)
    self:RegisterClickEvent(self.BtnNormal, self.OnBtnNormalClick)
    self:RegisterClickEvent(self.BtnHard, self.OnBtnHardClick)
    self:RegisterClickEvent(self.BtnVt, self.OnBtnVtClick)
    self:RegisterClickEvent(self.BtnAchievement, self.OnBtnAchievementClick)
end

function XUiMainLine2Chapter:OnBtnBackClick()
    self:Close()
end

function XUiMainLine2Chapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMainLine2Chapter:OnBtnDifficultyClick(difficulty)
    if self.IsSelectingDifficulty then
        self:OnSelectDifficulty(difficulty)
    else
        self:OpenDifficultyList()
    end
end

-- 选中一个难度
function XUiMainLine2Chapter:OnSelectDifficulty(difficulty)
    local chapterId
    for _, cId in ipairs(self.ChapterIds) do
        local chapterCfg = self._Control:GetConfigChapter(cId)
        if chapterCfg.Difficult == difficulty then
            chapterId = chapterCfg.ChapterId
        end
    end

    local isUnlock, tips = self._Control:IsChapterUnlock(chapterId)
    if not isUnlock then
        XUiManager.TipMsg(tips)
        return
    end

    self.CurChapterId = chapterId
    self.CurDifficulty = difficulty
    self:CloseDifficultyList()
    self:Refresh()
end

-- 打开难度列表
function XUiMainLine2Chapter:OpenDifficultyList()
    self.IsSelectingDifficulty = true
    self.BtnCloseDifficult.gameObject:SetActiveEx(true)
    for _, chapterId in ipairs(self.ChapterIds) do
        local difficult = self._Control:GetChapterDifficult(chapterId)
        local uiObj = self.DifficultyUiObj[difficult]
        uiObj.Button.gameObject:SetActiveEx(true)
        if self.CurDifficulty == difficult then
            uiObj.Button.transform:SetAsFirstSibling()
            uiObj.Button:ShowReddot(false)
        else
            uiObj.Button.transform:SetAsLastSibling()
            local isRed = self._Control:IsChapterRed(chapterId)
            uiObj.Button:ShowReddot(isRed)
        end
    end
end

-- 关闭难度列表
function XUiMainLine2Chapter:CloseDifficultyList()
    self.IsSelectingDifficulty = false
    self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    for _, uiObj in pairs(self.DifficultyUiObj) do
        uiObj.Button.gameObject:SetActiveEx(false)
    end

    local isRed = false
    for _, chapterId in ipairs(self.ChapterIds) do
        if self.CurChapterId ~= chapterId then
            isRed = isRed or self._Control:IsChapterRed(chapterId)
        end
    end

    local uiObj = self.DifficultyUiObj[self.CurDifficulty]
    uiObj.Button.gameObject:SetActiveEx(true)
    uiObj.Button:ShowReddot(isRed)
end

function XUiMainLine2Chapter:OnBtnNormalClick()
    self:OnBtnDifficultyClick(XEnumConst.MAINLINE2.DIFFICULTY_TYPE.NORMAL)
end

function XUiMainLine2Chapter:OnBtnHardClick()
    self:OnBtnDifficultyClick(XEnumConst.MAINLINE2.DIFFICULTY_TYPE.HARD)
end

function XUiMainLine2Chapter:OnBtnVtClick()
    self:OnBtnDifficultyClick(XEnumConst.MAINLINE2.DIFFICULTY_TYPE.VARIATIONS)
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

function XUiMainLine2Chapter:InitUiObj()
    self.DifficultyUiObj = {
        [XEnumConst.MAINLINE2.DIFFICULTY_TYPE.NORMAL] = {
            Button = self.BtnNormal,
            PanelChapter = self.ChapterNormal,
        },
        [XEnumConst.MAINLINE2.DIFFICULTY_TYPE.HARD] = {
            Button = self.BtnHard,
            PanelChapter = self.ChapterHard,
        },
        [XEnumConst.MAINLINE2.DIFFICULTY_TYPE.VARIATIONS] = {
            Button = self.BtnVt,
            PanelChapter = self.ChapterVt,
        },
    }

    self.RewardUiObjs = { self.GridReward }
    self.JumpBtns = { self.BtnJump }
end

-- 初始化难度UI显示
function XUiMainLine2Chapter:InitDifficultyUi()
    self.BtnCloseDifficult.gameObject:SetActiveEx(false)
    local mainCfg = self._Control:GetConfigMain(self.MainId)
    local isShow = #self.ChapterIds > 1
    self.PanelTopDifficult.gameObject:SetActiveEx(isShow)
    if isShow then
        for difficulty, uiObj in pairs(self.DifficultyUiObj) do
            uiObj.Button.gameObject:SetActiveEx(self.CurDifficulty == difficulty)
        end
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
end

-- 更新难度进度
function XUiMainLine2Chapter:RefreshDifficultyProgress()
    local isShow = #self.ChapterIds > 1
    if isShow then
        for _, chapterId in ipairs(self.ChapterIds) do
            local difficult = self._Control:GetChapterDifficult(chapterId)
            local btn = self.DifficultyUiObj[difficult].Button
            local passCnt, maxCnt = self._Control:GetChapterProgress(chapterId)
            local progress = math.floor(passCnt * 100 / maxCnt)
            local isUnlock, tips = self._Control:IsChapterUnlock(chapterId)
            btn:SetDisable(not isUnlock)
            btn:SetName(progress)
        end
    end
end

-- 加载章节预制体
function XUiMainLine2Chapter:LoadChapterPrefab()
    self._Control:CacheChapterMainId(self.CurChapterId, self.MainId)
    self.ChapterPrefabName = self._Control:GetChapterPrefabName(self.CurChapterId)

    -- 隐藏其他章节
    for _, difficulty in pairs(XEnumConst.MAINLINE2.DIFFICULTY_TYPE) do
        local node = self.UiNodeChapterDic[difficulty]
        if node then
            node:Close()
        end
    end

    -- 显示当前章节
    local uiNode = self.UiNodeChapterDic[self.CurDifficulty]
    if not uiNode  then
        local parentGo = self.DifficultyUiObj[self.CurDifficulty].PanelChapter
        local prefab = parentGo:LoadPrefab(self.ChapterPrefabName)
        local XUiMainLine2PanelEntranceList = require("XUi/XUiMainLine2/XUiMainLine2PanelEntranceList")
        uiNode = XUiMainLine2PanelEntranceList.New(prefab, self, self.CurChapterId, self.MainId, self.SkipStageId, self.IsOpenStageDetail)
        self.UiNodeChapterDic[self.CurDifficulty] = uiNode

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

    local icon = self._Control:GetAchievementIcon(achievementId)
    self.RImgAchievement:SetRawImage(icon)

    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local curCnt, maxCnt = agency:GetMainAchievementProgress(self.MainId)
    local progressFormat = self._Control:GetClientConfigParams("AchievementProgress", 1)
    self.TxtAchievementProgress.text = string.format(progressFormat, curCnt, maxCnt)
    
    local isGet = self._Control:IsAchievementGet(self.MainId)
    local isRed = curCnt >= maxCnt and not isGet
    self.BtnAchievement:ShowReddot(isRed)
    self.ImgAchievementComplete.gameObject:SetActiveEx(isGet)
end

-- 刷新奖励
function XUiMainLine2Chapter:RefreshRewards()
    self.PanelReward.gameObject:SetActiveEx(false)

    -- 无配置进度奖励，不显示
    local config = self._Control:GetConfigChapter(self.CurChapterId)
    if config.TreasureId == 0 then
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
    local treasureCfg = self._Control:GetConfigTreasure(config.TreasureId)
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
            self:OnBtnRewardClick(i, isGet, isReach, highlightRewardId)
        end

        -- 普通奖励
        local rewardList2 = XRewardManager.GetRewardList(rewardId)
        local itemObj2 = uiObj:GetObject("GridItem2")
        itemObj2:GetObject("GetTag").gameObject:SetActiveEx(isGet)
        itemObj2:GetObject("PanelEffect").gameObject:SetActiveEx(not isGet and isReach)
        itemObj2:GetObject("TxtNum").gameObject:SetActiveEx(false)
        itemObj2:GetObject("BtnClick").CallBack = function()
            self:OnBtnRewardClick(i, isGet, isReach, rewardId)
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
function XUiMainLine2Chapter:OnBtnRewardClick(index, isGet, isReach, rewardId)
    if isReach and not isGet then
        XMVCA:GetAgency(ModuleId.XMainLine2):RequestReceiveTreasure(self.CurChapterId, function()
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

        local btn = self.JumpBtns[i]
        if not btn then
            local go = CS.UnityEngine.Object.Instantiate(self.BtnJump.gameObject, self.JumpBtnList.transform)
            btn = go:GetComponent("XUiButton")
            self.JumpBtns[i] = btn
        end

        local uiObj = btn:GetComponent("UiObject")
        uiObj:GetObject("RawImageNormal"):SetRawImage(icon)
        uiObj:GetObject("RawImagePress"):SetRawImage(icon)

        local isReach, desc = XConditionManager.CheckCondition(condition)
        btn.gameObject:SetActiveEx(isReach)
        btn:SetNameByGroup(0, name)
        btn.CallBack = function()
            self:OnBtnJumpClick(skipId)
        end
    end
end

return XUiMainLine2Chapter