-- 异构阵线2.0章节界面
local XUiMaverick2Explore = XLuaUiManager.Register(XLuaUi, "UiMaverick2Explore")
local XUiDoomsdayDragZoomProxy = require("XUi/XUiDoomsday/XUiDoomsdayDragZoomProxy")

local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local StagePrefabName = 
{
    "GridMaverick2Stage", -- 主线M
    "GridMaverick2StageCamp", -- 主线Boss
    "GridMaverick2Stage", -- 角色
    "GridMaverick2Stage", -- 挑战
    "GridMaverick2Stage", -- 每日关卡
    "GridMaverick2Stage", -- 积分关卡
}

local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3
local ANIM_TIME = 0.5 --镜头移动动画时间
local SELECT_STAGE_WIDTH_OFFSET = 0.382 -- 选中关卡时，聚焦关卡的宽度偏移值
local GUIDE_DAILY_CHAPTER_ID = 2 -- 指引每日关卡的章节id

function XUiMaverick2Explore:OnAwake()
    -- 章节页签
    self.BtnList = {} -- 当前显示页签按钮列表
    self.ChapterCfgs = {} --页签对应章节配置表列表
    self.SelectTabIndex = nil -- 当前选中页签下标
    self.IsDifficult = nil -- 获取当前是否困难模式
    self.UnOpenTabList = {} -- 未开放的页签列表

    -- 章节地图
    self.MapDic = {} -- 地图对象，有根节点预制体、关卡预制体列表
    self.StageLoadDic = {} -- 记录地图节点加载完的关卡预置，包括普通难度和困难难度
    self.StageIdToUiObj = {} -- 记录关卡id对应的关卡预置的UiObject
    self.SelectStageId = nil -- 当前选中的关卡id

    self:SetButtonCallBack()
    self:InitTimes()
    self:InitMap()
    self:InitAssetPanel()
    self:PlayChapterEndMovie()
    self.DragProxy = XUiDoomsdayDragZoomProxy.New(self.PanelDrag)
    self.Stage.gameObject:SetActiveEx(false)
    self.StageDifficult.gameObject:SetActiveEx(false)
end

function XUiMaverick2Explore:OnStart()

end

function XUiMaverick2Explore:OnEnable()
    self.Super.OnEnable(self)
    self:InitLastSelect()
    self:Refresh()

    -- 战斗胜利回到关卡界面
    XDataCenter.Maverick2Manager.PlayBGM()
end

function XUiMaverick2Explore:OnDisable()

end

function XUiMaverick2Explore:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBtnClose)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnMember, function() XLuaUiManager.Open("UiMaverick2Character") end)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, function() XDataCenter.Maverick2Manager.OpenUiRank() end)
    XUiHelper.RegisterClickEvent(self, self.BtnMental, function() XLuaUiManager.Open("UiMaverick2Talent") end)
    XUiHelper.RegisterClickEvent(self, self.BtnNightmareStage, function() self:OnChangeDifficult(true) end)
    XUiHelper.RegisterClickEvent(self, self.BtnNormalStage, function() self:OnChangeDifficult(false) end)
    self:BindHelpBtn(self.BtnHelp, XMaverick2Configs.GetHelpKey())
end

function XUiMaverick2Explore:OnClickBtnClose()
    self:Close()
end

function XUiMaverick2Explore:OnChangeDifficult(isDifficult)
    self.IsDifficult = isDifficult
    self.SelectTabIndex = nil

    -- 获取章节列表
    self.ChapterCfgs = self:GetShowChapterCfgs()

    -- 确定当前选中页签下标
    local tabIndex = 1
    local chapterId = XDataCenter.Maverick2Manager.GetLastSelChapterId()
    for index, chapterCfg in ipairs(self.ChapterCfgs) do
        if chapterCfg.ChapterId == chapterId then
            tabIndex = index
        end
    end

    self:PlayAnimation("QieHuan")
    self:RefreshTabList(tabIndex)
end

function XUiMaverick2Explore:Refresh()
    -- 主线指引提示
    self:RefreshMainLineTips()

    -- 心智等级
    self:RefreshMentalLevel()
    XDataCenter.Maverick2Manager.CheckMentalLvUp(function()
        self:RefreshMentalLevel()
    end)

    -- 新角色解锁/支援技能解锁弹窗tips
    self:ShowUnlockTips()

    self:UpdateAssetPanel()
end

function XUiMaverick2Explore:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTabListOpenTime()
            self:RefreshDailyListTime()
        end
    end)
end

function XUiMaverick2Explore:OnGetEvents()
    return { XEventId.EVENT_MAVERICK2_UPDATE_DAILY }
end

function XUiMaverick2Explore:OnNotify(evt)
    if evt == XEventId.EVENT_MAVERICK2_UPDATE_DAILY then
        self:RefreshMap()
    end
end

---------------------------------------- 章节页签 begin ----------------------------------------

-- 初始化上次的选中
function XUiMaverick2Explore:InitLastSelect()
    local chapterId = XDataCenter.Maverick2Manager.GetLastSelChapterId()
    local config = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)
    local isDifficult = config.IfFlag == 1 and XDataCenter.Maverick2Manager.IsChapterUnlock(chapterId)
    self:OnChangeDifficult(isDifficult)
end

-- 获取当前显示的章节配置表列表
function XUiMaverick2Explore:GetShowChapterCfgs()
    local showCfgs = {}
    local cfgs = XMaverick2Configs.GetMaverick2Chapter()
    for _, cfg in ipairs(cfgs) do
        local isDifficult = cfg.IfFlag == 1
        if isDifficult == self.IsDifficult and XDataCenter.Maverick2Manager.IsChapterUnlock(cfg.ChapterId) then
            table.insert(showCfgs, cfg)
        end
    end
    return showCfgs
end

-- 刷新章节页签列表
function XUiMaverick2Explore:RefreshTabList(selectIndex)
    -- 刷新页签ui
    self.BtnList = {}
    self.UnOpenTabList = {}
    XUiHelper.RefreshCustomizedList(self.BtnContent.transform, self.BtnTab.gameObject, #self.ChapterCfgs, function(index, go)
        local chapterCfg = self.ChapterCfgs[index]
        local btn = go:GetComponent("XUiButton") 
        table.insert(self.BtnList, btn)
        btn:SetNameByGroup(0, chapterCfg.Name)
        local passStageCnt, allStageCnt = XDataCenter.Maverick2Manager.GetChapterProgress(chapterCfg.ChapterId)
        local isPass = passStageCnt >= allStageCnt
        local txtProgress = isPass and "" or XUiHelper.GetText("Maverick2ChapterCompleteProgress", math.floor(passStageCnt * 100 / allStageCnt)) 
        btn:SetNameByGroup(1, txtProgress)
        btn:ShowTag(isPass)
        btn:SetButtonState(Normal)
        local isRed = XDataCenter.Maverick2Manager.IsChapterShowRed(chapterCfg.ChapterId)
        btn:ShowReddot(isRed)

        -- 开启时间
        local uiObj = go:GetComponent("UiObject")
        local txtProgress = uiObj:GetObject("TxtProgress")
        local txtOpenTime = uiObj:GetObject("TxtOpenTime")
        self:RefreshTabOpenTime(chapterCfg.ChapterId, txtProgress, txtOpenTime)
        local isOpen = XDataCenter.Maverick2Manager.IsChapterOpenTime(chapterCfg.ChapterId)
        if not isOpen then
            table.insert(self.UnOpenTabList, { ChapterId = chapterCfg.ChapterId, TxtProgress = txtProgress, TxtOpenTime = txtOpenTime })
        end

        -- 章节解锁动画
        if isRed then
            uiObj:GetObject("BtnTabEnable").transform:PlayTimelineAnimation()
        end

        local tempIndex = index
        XUiHelper.RegisterClickEvent(self, btn, function()
            self:OnBtnTabClick(tempIndex)
        end)
    end)

    -- 刷新切换章节组按钮
    self:RefreshSwitchChapterListBtn()
    
    -- 刷新ButtonGroup组件
    self.BtnContent:Init(self.BtnList,function(index)
        self:OnBtnTabClick(index)
    end)
    self.BtnContent:SelectIndex(selectIndex)
end

-- 刷新章节页签列表的开启时间
function XUiMaverick2Explore:RefreshTabListOpenTime()
    if #self.UnOpenTabList > 0 then
        local cnt = #self.UnOpenTabList
        for i = cnt, 1, -1 do
            local tabInfo = self.UnOpenTabList[i]
            self:RefreshTabOpenTime(tabInfo.ChapterId, tabInfo.TxtProgress, tabInfo.TxtOpenTime)
            local isOpen = XDataCenter.Maverick2Manager.IsChapterOpenTime(tabInfo.ChapterId)
            if isOpen then
                table.remove(self.UnOpenTabList, i)
            end
        end
    end
end

-- 刷新每日关卡的倒计时时间
function XUiMaverick2Explore:RefreshDailyListTime()
    local dailyStageDic = XDataCenter.Maverick2Manager.GetDailyStage()
    for stageId, isExit in pairs(dailyStageDic) do
        if stageId and isExit and self.StageIdToUiObj[stageId] then
            local refreshTime = XTime.GetSeverNextRefreshTime()
            local nowTime = XTime.GetServerNowTimestamp()
            local showTime = XUiHelper.GetTime(refreshTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
            local textTime = self.StageIdToUiObj[stageId]:GetObject("TxtTime")
            textTime.text = XUiHelper.GetText("DrawFreeTicketCoolDown", showTime)  
        end
    end 
end

-- 刷新章节页签的开启时间
function XUiMaverick2Explore:RefreshTabOpenTime(chapterId, txtProgress, txtOpenTime)
    local isOpen = XDataCenter.Maverick2Manager.IsChapterOpenTime(chapterId)
    txtProgress.gameObject:SetActiveEx(isOpen)
    txtOpenTime.gameObject:SetActiveEx(not isOpen)
    if not isOpen then
        local openTime = XDataCenter.Maverick2Manager.GetChapterOpenTime(chapterId)
        txtOpenTime.text =  XUiHelper.GetTime(openTime, XUiHelper.TimeFormatType.DAY_HOUR)
    end
end

function XUiMaverick2Explore:OnBtnTabClick(index)
    if self.SelectTabIndex == index then
        return
    end

    -- 检测页签是否到开放时间
    local chapterId = self.ChapterCfgs[index].ChapterId
    for _, info in ipairs(self.UnOpenTabList) do
        if info.ChapterId == chapterId then
            XUiManager.TipText("RiftChapterTimeLimit")
            self.BtnContent:SelectIndex(self.SelectTabIndex)
            return
        end
    end

    -- 切换按钮状态
    self.SelectTabIndex = index
    for index, btn in ipairs(self.BtnList) do
        local state = index == self.SelectTabIndex and Select or Normal
        btn:SetButtonState(state)
    end

    -- 刷新列表
    self:RefreshMap()

    -- 保存最后选中章节记录
    XDataCenter.Maverick2Manager.SaveLastSelChapterId(chapterId)

    -- 移除红点
    self.BtnList[index]:ShowReddot(false)
    local characterId = self:GetCurChapterId()
    XDataCenter.Maverick2Manager.RemveChapterRed(characterId)

    -- 播放剧情
    self:PlayChapterStartMovie()
end

function XUiMaverick2Explore:GetCurChapterId()
    local chapterId = self.ChapterCfgs[self.SelectTabIndex].ChapterId
    return chapterId
end


---------------------------------------- 章节页签 end ----------------------------------------


---------------------------------------- 章节地图 begin ----------------------------------------
-- 播放第一次打开章节的开幕剧情
function XUiMaverick2Explore:PlayChapterStartMovie()
    local curChapterId = self:GetCurChapterId()
    XDataCenter.Maverick2Manager.PlayChapterMovie(curChapterId, function()
        -- 剧情播放结束，重新播音效
        XDataCenter.Maverick2Manager.PlayBGM()
    end)
end

-- 初始化预制体上的地图
function XUiMaverick2Explore:InitMap()
    self.MapDic = {}

    local index = 1
    while(self["Map" .. index])
    do
        local map = {}
        self.MapDic[index] = map

        local mapGo = self["Map" .. index]
        map.gameObject = mapGo.gameObject
        map.StageGos = {}
        local maxCnt = mapGo.transform.childCount
        for i = 1, maxCnt do
            local stageGo = mapGo:GetObject("Stage"..i)
            if stageGo then
                table.insert(map.StageGos, stageGo)
            end
        end
        index = index + 1
    end
end

-- 刷新地图
function XUiMaverick2Explore:RefreshMap()
    local chapterId = self:GetCurChapterId()
    local config = XMaverick2Configs.GetMaverick2Chapter(chapterId, true)

    -- 显示当前章节的地图
    for _, map in pairs(self.MapDic) do
        map.gameObject:SetActiveEx(false)
    end

    -- 刷新背景图
    self.RImgMapBg:SetRawImage(config.MapBg)
    -- 刷新特效
    local showEffect = config.MapEffect and config.MapEffect ~= ""
    self.Effect.gameObject:SetActiveEx(showEffect)
    if showEffect then
        self.Effect:LoadUiEffect(config.MapEffect)
    end

    -- 刷新当前地图关卡
    self.MapDic[config.Map].gameObject:SetActiveEx(true)
    local stageGos = self.MapDic[config.Map].StageGos
    for _, stageGo in ipairs(stageGos) do
        stageGo.gameObject:SetActiveEx(false)
    end

    local stageCfgs = XMaverick2Configs.GetChapterStages(chapterId)
    for index, stageCfg in ipairs(stageCfgs) do
        local stageGo = stageGos[stageCfg.IconPos]
        local isUnlock = false
        local isActiveDailyStage = false
        if stageCfg then
            isUnlock = XDataCenter.Maverick2Manager.IsStageUnlock(stageCfg.StageId)
            isActiveDailyStage = XDataCenter.Maverick2Manager.IsShowDailyStage(stageCfg.StageId)
        end
        local isShowStage = isUnlock or isActiveDailyStage
        if isShowStage then
            stageGo.gameObject:SetActiveEx(true)
            self:RefreshStage(stageCfg, stageGo)
        end
    end

    -- 刷新每日关卡倒计时
    self:RefreshDailyListTime()

    -- 聚焦关卡
    local focusStage = nil -- 聚焦关卡
    for _, stageCfg in ipairs(stageCfgs) do
        local isCompare = false
        if stageCfg.StageType == XMaverick2Configs.StageType.Daily then
            local isActive = XDataCenter.Maverick2Manager.IsShowDailyStage(stageCfg.StageId)
            isCompare = isActive
        else
            local isUnlock = XDataCenter.Maverick2Manager.IsStageUnlock(stageCfg.StageId)
            local isPass = XDataCenter.Maverick2Manager.IsStagePassed(stageCfg.StageId)
            isCompare = isUnlock and not isPass
        end

        if isCompare then
            if focusStage == nil or XMaverick2Configs.FocusStageOrder[stageCfg.StageType] < XMaverick2Configs.FocusStageOrder[focusStage.StageType] then 
                focusStage = stageCfg
            end
        end
    end

    -- 特写指引聚焦每日关卡的章节id
    local isNotOpenedDaily = not XDataCenter.Maverick2Manager.IsOpenedDailyStage()
    if chapterId == GUIDE_DAILY_CHAPTER_ID and isNotOpenedDaily  then
        for _, stageCfg in ipairs(stageCfgs) do
            if stageCfg.StageType == XMaverick2Configs.StageType.Daily then
                local isActive = XDataCenter.Maverick2Manager.IsShowDailyStage(stageCfg.StageId)
                if isActive then
                    focusStage = stageCfg
                end
            end
        end
    end

    if focusStage then
        local uiObj = self.StageIdToUiObj[focusStage.StageId]
        uiObj:GetObject("Effect").gameObject:SetActiveEx(true)
        self:FocusStage(uiObj.gameObject, nil, nil, ANIM_TIME)
    else
        self:FocusStage(nil, nil, nil, ANIM_TIME)
    end
end

function XUiMaverick2Explore:RefreshStage(stageCfg, goParent)
    local stageId = stageCfg.StageId
    local instanceID = goParent:GetInstanceID()

    -- 隐藏Stage和StageDifficult两种关卡
    if self.StageLoadDic[instanceID] then
        local stage = self.StageLoadDic[instanceID].Stage

        if stage then
            stage.gameObject:SetActiveEx(false)
        end
        local stageDifficult = self.StageLoadDic[instanceID].StageDifficult
        if stageDifficult then
            stageDifficult.gameObject:SetActiveEx(false)
        end
    else
        self.StageLoadDic[instanceID] = {}
    end

    -- 显示、加载、刷新当前关卡
    local isDifficult = self:IsCurDifficult()
    local uiObj = isDifficult and self.StageLoadDic[instanceID].StageDifficult or self.StageLoadDic[instanceID].Stage

    -- 创建预制体
    if not uiObj then
        if isDifficult then
            local go = CS.UnityEngine.GameObject.Instantiate(self.StageDifficult, goParent)
            self.StageLoadDic[instanceID].StageDifficult = go
            uiObj = go:GetComponent("UiObject")
        else
            local go = CS.UnityEngine.GameObject.Instantiate(self.Stage, goParent)
            self.StageLoadDic[instanceID].Stage = go
            uiObj = go:GetComponent("UiObject")
        end
    end
    self.StageIdToUiObj[stageId] = uiObj
    
    -- 刷新ui
    uiObj.gameObject:SetActiveEx(true)
    uiObj:GetObject("BgNormal").gameObject:SetActiveEx(true)
    uiObj:GetObject("BgSelect").gameObject:SetActiveEx(false)
    local typeConfig = XMaverick2Configs.GetMaverick2StageType(stageCfg.StageType, true)
    uiObj:GetObject("IconNormal"):SetSprite(typeConfig.Icon)
    uiObj:GetObject("IconSelect"):SetSprite(typeConfig.Icon)
    local isPass = XDataCenter.Maverick2Manager.IsStagePassed(stageId)
    uiObj:GetObject("ImgClearNormal").gameObject:SetActiveEx(isPass)
    uiObj:GetObject("ImgClearSelect").gameObject:SetActiveEx(isPass)
    uiObj:GetObject("Effect").gameObject:SetActiveEx(false)

    -- 积分关卡
    local isScore = XMaverick2Configs.StageType.Score == stageCfg.StageType
    local txtScore = uiObj:GetObject("TxtScore")
    txtScore.gameObject:SetActiveEx(isScore)
    if isScore then
        local record = XDataCenter.Maverick2Manager.GetScoreStageRecord()
        txtScore.text = record.Score and tostring(record.Score) or "0"
    end

    -- 每日关卡，这里只控制显示，刷新在RefreshDailyListTime()函数
    local isDaily = stageCfg.StageType == XMaverick2Configs.StageType.Daily
    local txtTime = uiObj:GetObject("TxtTime")
    txtTime.gameObject:SetActiveEx(isDaily)

    -- 注册事件
    XUiHelper.RegisterClickEvent(self, uiObj:GetObject("BtnClick"), function() 
        self:OnClickStage(stageId)
    end)

    -- 解锁动画
    local isPlay = XDataCenter.Maverick2Manager.IsStagePlayUnlockAnim(stageId)
    if isPlay then
        XDataCenter.Maverick2Manager.SetStagePlayUnlockAnim(stageId)
        uiObj:GetObject("AnimEnable").transform:PlayTimelineAnimation()
        local line = goParent:Find("GridMaverick2StageLine")
        if line then
            local lineUiObj = line:GetComponent("UiObject")
            lineUiObj:GetObject("AnimEnable"):PlayTimelineAnimation()
        end
    end
end

function XUiMaverick2Explore:OnClickStage(stageId)
    if self.SelectStageId == stageId then
        return
    end

    self:CloseStageSelect()
    self:OpenStageSelect(stageId)
    self:CloseAllStageTipsEffect()

    local uiObj = self.StageIdToUiObj[stageId]
    self:FocusStage(uiObj.gameObject, SELECT_STAGE_WIDTH_OFFSET, nil, ANIM_TIME)

    -- 选中动画
    uiObj:GetObject("BgSelectEnable").transform:PlayTimelineAnimation(function()
        uiObj:GetObject("BgSelectLoop").transform:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

-- 打开关卡选中
function XUiMaverick2Explore:OpenStageSelect(stageId)
    self.SelectStageId = stageId
    local isDifficult = self:IsCurDifficult()
    local uiObj = self.StageIdToUiObj[stageId]
    uiObj:GetObject("BgNormal").gameObject:SetActiveEx(false)
    uiObj:GetObject("BgSelect").gameObject:SetActiveEx(true)
    XLuaUiManager.Open("UiMaverick2StageDetail", stageId, function()
        self:CloseStageSelect()
    end)
end

-- 关闭关卡选中
function XUiMaverick2Explore:CloseStageSelect()
    if not self.SelectStageId then 
        return 
    end

    local stageId = self.SelectStageId
    self.SelectStageId = nil
    local isDifficult = self:IsCurDifficult()
    local uiObj = self.StageIdToUiObj[stageId]
    uiObj:GetObject("BgNormal").gameObject:SetActiveEx(true)
    uiObj:GetObject("BgSelect").gameObject:SetActiveEx(false)
end

-- 聚焦在关卡
function XUiMaverick2Explore:FocusStage(stageObj, widthOffset, heightOffset, duration, easeType)
    widthOffset = widthOffset or 0.5
    heightOffset = heightOffset or 0.5
    duration = duration or 0
    easeType = easeType or CS.DG.Tweening.Ease.Linear
    local midScreenPos =
        CS.UnityEngine.Vector2(CS.UnityEngine.Screen.width * widthOffset, CS.UnityEngine.Screen.height * heightOffset)
    local _, midPos =
        CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        self.PanelStages,
        midScreenPos,
        CS.UnityEngine.Camera.main
    )
    local offset = CSVector3(midPos.x, midPos.y, 0)
    if stageObj then
        -- 避免地图节点缩放影响
        local stagePos = stageObj.transform.parent.localPosition
        local mapGo = stageObj.transform.parent.parent
        stagePos.x = stagePos.x * mapGo.localScale.x
        stagePos.y = stagePos.y * mapGo.localScale.y

        offset = offset - stagePos
    end

    -- 避免缩放影响
    offset.x = offset.x * self.PanelStages.localScale.x
    offset.y = offset.y * self.PanelStages.localScale.y
    self.AnimOffset = offset
    self.PanelStages:DOLocalMove(self.PanelStages.localPosition + offset, duration)
end

-- 关闭所有关卡提示特效
function XUiMaverick2Explore:CloseAllStageTipsEffect()
    local chapterId = self:GetCurChapterId()
    local stageCfgs = XMaverick2Configs.GetChapterStages(chapterId)
    for _, stageCfg in ipairs(stageCfgs) do
        local uiObj = self.StageIdToUiObj[stageCfg.StageId]
        if uiObj then
            uiObj:GetObject("Effect").gameObject:SetActiveEx(false)
        end
    end
end
---------------------------------------- 章节地图 end ----------------------------------------

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiMaverick2Explore:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiMaverick2Explore:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------

-- 刷新主线提示目的
function XUiMaverick2Explore:RefreshMainLineTips()
    local tips = nil
    local stageCfgs = XMaverick2Configs.GetMaverick2Stage()
    for _, stageCfg in pairs(stageCfgs) do
        local isUnlock = XDataCenter.Maverick2Manager.IsStageUnlock(stageCfg.StageId)
        local isPass = XDataCenter.Maverick2Manager.IsStagePassed(stageCfg.StageId)
        if isUnlock and not isPass and stageCfg.MainlineTips then
            tips = stageCfg.MainlineTips
            break
        end
    end

    local isShow = tips ~= nil
    self.PanelGuide.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtGuideTips.text = tips
        local isDifficult = self:IsCurDifficult()
        self.RImgGuideNormal.gameObject:SetActiveEx(not isDifficult)
        self.RImgGuidNightmare.gameObject:SetActiveEx(isDifficult)
    end
end

-- 刷新心智等级
function XUiMaverick2Explore:RefreshMentalLevel()
    local mentalLv = XDataCenter.Maverick2Manager.GetMentalLv()
    local maxMentalLv = XDataCenter.Maverick2Manager.GetMentalMaxLv()
    self.MentalLevel.text = tostring(mentalLv)
    self.MentalProgress.fillAmount = mentalLv / maxMentalLv

    local isMax = mentalLv == maxMentalLv
    if isMax then
        self.TxtUnitNumber.text = "MAX"
        self.RawImageUnit.gameObject:SetActiveEx(false)
        self.MentalProgress.fillAmount = 1
    else
        local unitCnt = XDataCenter.Maverick2Manager.GetUnitCount()
        local config = XMaverick2Configs.GetMaverick2Mental(mentalLv + 1, true)
        self.TxtUnitNumber.text = string.format("<color=#C64141>%s</color>/%s", unitCnt, config.NeedUnit)
        self.RawImageUnit.gameObject:SetActiveEx(true)
        local itemIcon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.Maverick2Unit)
        self.RawImageUnit:SetRawImage(itemIcon)
        self.MentalProgress.fillAmount = unitCnt / config.NeedUnit
    end

    -- 红点
    local robotId = XDataCenter.Maverick2Manager.GetLastSelRobotId()
    local isRed = XDataCenter.Maverick2Manager.IsShowTalentRed(robotId)
    self.BtnMental.transform:Find("Red").gameObject:SetActiveEx(isRed)
end

-- 新角色解锁/支援技能解锁弹窗tips
function XUiMaverick2Explore:ShowUnlockTips()
    XDataCenter.Maverick2Manager.CheckRobotUnlock()
    XDataCenter.Maverick2Manager.CheckAssistTalentLvUp()
end

-- 当前是否处于困难模式
function XUiMaverick2Explore:IsCurDifficult()
    return self.IsDifficult == true
end

-- 刷新切换章节组按钮
function XUiMaverick2Explore:RefreshSwitchChapterListBtn()
    local isUnlock = XDataCenter.Maverick2Manager.IsUnlockDifficultChapterList()
    if isUnlock then
        local isDifficult = self:IsCurDifficult()
        self.BtnNormalStage.gameObject:SetActiveEx(isDifficult)
        self.BtnNightmareStage.gameObject:SetActiveEx(not isDifficult)
    else
        self.BtnNormalStage.gameObject:SetActiveEx(false)
        self.BtnNightmareStage.gameObject:SetActiveEx(false)
    end
end

-- 战斗结束回到主界面播章节结束剧情
function XUiMaverick2Explore:PlayChapterEndMovie()
    local lastPassStageId = XDataCenter.Maverick2Manager.GetLastPassStageId()
    if lastPassStageId then
        local key = XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "UiMaverick2Explore_PlayChapterEndMovie_" .. tostring(lastPassStageId)
        if XSaveTool.GetData(key) then
            return
        end

        local stageCfg = XMaverick2Configs.GetMaverick2Stage(lastPassStageId, true)
        local movieCfgs = XMaverick2Configs.GetMaverick2Movie()
        for _, movieCfg in ipairs(movieCfgs) do
            for i, stageId in ipairs(movieCfg.CloseStageIds) do
                if stageId == lastPassStageId then
                    local movieId = movieCfg.CloseMovieIds[i]
                    XDataCenter.MovieManager.PlayMovie(movieId)
                    XSaveTool.SaveData(key, true)
                    return
                end
            end
        end
    end
end
