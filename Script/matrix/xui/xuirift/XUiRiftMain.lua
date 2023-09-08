---@class XUiRiftMain:XLuaUi 大秘境主界面
local XUiRiftMain = XLuaUiManager.Register(XLuaUi, "UiRiftMain")
local XUiPanel3DMap = require("XUi/XUiRift/Grid/XUiPanelRiftMain3D")
local XUiGridRiftChapterOutliers = require("XUi/XUiRift/Grid/XUiGridRiftChapterOutliers") -- 主界面看异常点用的，对应作战层

local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftCoin
}

function XUiRiftMain:OnAwake()
    self.CurrSelectIndex = 1
    self.CurrSelectChapter = nil
    self.OutliersGridDic = {}
    self.ChildUi = nil
    self.RewardGridList = {}

    self:InitButton()
    self:Init3DPanel()
    self:InitComponent()
    self:SetDragCallBack()

    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))
end

function XUiRiftMain:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnRiftFightLayerSelect, self.OnBtniRiftFightLayerSelectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, function() XLuaUiManager.Open("UiRiftTask") end)
    XUiHelper.RegisterClickEvent(self, self.BtnRanking, self.OnBtnRank)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, function() XDataCenter.RiftManager.OpenUiShop() end)
    XUiHelper.RegisterClickEvent(self, self.BtnForGuide, self.OnBtnForGuideClick)
end

function XUiRiftMain:Init3DPanel()
    local root = self.UiModelGo.transform
    ---@type XUiPanelRiftMain3D
    self.Panel3D = XUiPanel3DMap.New(root, self)
end

function XUiRiftMain:OnChildUiClose()
    self:SetChapterInfoBubbleActive(false)
    self:OpenChildToShowOrHide(true)
    self.Panel3D:SetCameraAngleByChapterId(nil) -- 默认关闭区域层级俯视镜头
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) or XTool.UObjIsNil(self.Panel3D.GameObject) then
            return
        end
        
        self.Panel3D:SetOtherGameObjectShowByChapterId(nil) 
    end, 300)
    self.ChildUi = nil
    self.Panel3D:Refresh()
    self:RefreshUiShow()
end

function XUiRiftMain:OnEnable()
    self:SetChapterInfoBubbleActive(false) -- 默认关闭数据构建层气泡
    self.Panel3D:SetCameraAngleByChapterId(nil) -- 默认关闭区域层级俯视镜头
    self.Panel3D:SetOtherGameObjectShowByChapterId(nil) 
    self.Panel3D:Refresh()
    self:AutoGotoLayer()
    self:AutoPositioning()
    self:RefreshUiShow()
    self:SetTimer()
    self:CheckShowSeasonStart()
end

function XUiRiftMain:RefreshUiShow()
    -- 目标(任务/权限回收)
    self:RefreshUiTask()
    -- 资源栏
    self:UpdateAssetPanel()
    -- 商店展示道具
    self:RefreshShopReward()

    self.IsRankUnlock, self.RankConditionDesc = XDataCenter.RiftManager:IsRankUnlock()
    self.BtnRanking:SetButtonState(self.IsRankUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiRiftMain:OnBtnRank()
    if not self.IsRankUnlock then
        XUiManager.TipError(self.RankConditionDesc)
        return
    end
    XLuaUiManager.Open("UiRiftRanking")
end

function XUiRiftMain:CheckShowSeasonStart()
    XDataCenter.RiftManager:CheckShowSeasonStart()
end

-- (被3D面板调用)
function XUiRiftMain:RefreshChapterInfoShow(xChapter)
    self.TxtTitle.text = xChapter:GetConfig().Name

    local textUnKnown = CS.XTextManager.GetText("UnKnown")
    local isLock = xChapter:CheckHasLock()
    -- 危险值
    self.TxtDangerTip.text = isLock and textUnKnown or xChapter:GetConfig().DangerValue

    -- 深度范围：第一个作战层id ~ 最后1个作战层id
    local fightLayerList = xChapter:GetAllFightLayersOrderList()
    local firstDeep = fightLayerList[1]:GetId()
    local lastDeep = fightLayerList[#fightLayerList]:GetId()
    self.TxtDepth.text = isLock and textUnKnown or CS.XTextManager.GetText("RiftChapterDepthRange", firstDeep, lastDeep)
    -- 已探测
    local currMaxFightLayer = xChapter:GetPassedLayerOrderMaxFightLayer()
    local depth = currMaxFightLayer and currMaxFightLayer:GetId() or 0
    self.TxtCurrPos.gameObject:SetActiveEx(not isLock)
    self.TxtCurrPos.text = CS.XTextManager.GetText("RiftDepth", depth)

    -- 层进度(清理进度)
    local curr, total = xChapter:GetProgress()
    self.TxtChapterClearProgress.text = isLock and textUnKnown or math.floor((curr/total)*100).."%"
    -- 异常点
    local outliersFightLayerList = xChapter:GetAllOutliersList() -- 所有异常点(多队伍层)
    -- 刷新前先隐藏一遍
    local text = ""
    for i = 1, 4 do -- 最多只显示4个异常点，且只有固定的4个格子
        local gridTrans = self.PanelOutliers:Find("Grid"..i)
        gridTrans.gameObject:SetActiveEx(false)
    end
    for i = 1, 4 do 
        local gridTrans = self.PanelOutliers:Find("Grid"..i)
        if i > #outliersFightLayerList then
            gridTrans.gameObject:SetActiveEx(false)
        else
            local grid = self.OutliersGridDic[i]
            if not grid then
                grid = XUiGridRiftChapterOutliers.New(gridTrans, self)
                self.OutliersGridDic[i] = grid
            end
            local xFightLayer = outliersFightLayerList[i]
            grid:UpdateData(xFightLayer)
            text = text..xFightLayer:GetId().."KM "
        end
    end
    self.TxtOutlier.text = isLock and textUnKnown or text
    -- 倒计时（没到时间不显示入口）
    self.BtnRiftFightLayerSelect.gameObject:SetActive(not isLock)
    self.PanelTime.gameObject:SetActive(isLock)
    if xChapter:CheckTimeLock() then
        local leftTime = xChapter:GetOpenLeftTime()
        local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PIVOT_COMBAT)
        local leftText = CS.XTextManager.GetText("Residue")
        local openText = CS.XTextManager.GetText("EscapeTimeCondition", leftTimeStr)
        self.TxtLeftTime.text = leftText..openText
    elseif xChapter:CheckPreLock() then
        self.TxtLeftTime.text = CS.XTextManager.GetText("RiftChapterPreLimit")
    end
end

-- (被3D面板调用)
-- 显示区域信息气泡
function XUiRiftMain:SetChapterInfoBubbleActive(flag)
    self.PanelOutliers.gameObject:SetActiveEx(flag)
    self.PanelTangchuan.gameObject:SetActiveEx(flag)
    self.ImgLineChargeShadow.gameObject:SetActiveEx(flag)
end

-- 自动滑动定位区域
-- 1.如果有正在作战的作战层 优先定位到区域
-- 2.定位到最新可挑战层
-- 3.全部通关则定位到第一层
function XUiRiftMain:AutoPositioning()
    if not self.SafeAreaContentPane.gameObject.activeSelf then
        if XTool.IsNumberValid(self.CurrSelectIndex) then
            self.Panel3D:ImmediatelyGoToNodeIndex(self.CurrSelectIndex)
        end
        return -- 关卡选择界面开着时，直接移动到选中层
    end

    local targetIndex = 1

    if not self.CurPlayingChapter then
        self.CurPlayingChapter = XDataCenter.RiftManager.GetCurrPlayingChapter()
    end
    if self.CurPlayingChapter then
        targetIndex = self.CurPlayingChapter:GetId()
    elseif not XDataCenter.RiftManager.IsAllPass() then
        local maxUnlock = XDataCenter.RiftManager.GetMaxUnLockFightLayerId()
        local maxUnlockLayer = XDataCenter.RiftManager.GetEntityFightLayerById(maxUnlock)
        targetIndex = maxUnlockLayer:GetParent():GetId()
    end
    self.CurrSelectIndex = targetIndex
    -- 滑动chapter列表
    self:AutoPositioningToOpenBubbleByChapterId(targetIndex)
end

-- 自动滑动并打开目标区域的bubble
function XUiRiftMain:AutoPositioningToOpenBubbleByChapterId(chapterId)
    self.Panel3D:FocusTargetNodeIndex(chapterId, -1, function ()
        self.CurrSelectIndex = chapterId
        self.CurrSelectChapter = XDataCenter.RiftManager.GetEntityChapterById(chapterId)
        self:RefreshChapterInfoShow(self.CurrSelectChapter)
        self:SetChapterInfoBubbleActive(true)
    end)
end

function XUiRiftMain:SetDragCallBack()
    self.Panel3D:SetDragCallBack(function(gridRiftChapter3D)
        self.CurrSelectChapter = gridRiftChapter3D.XChapter
        self.CurrSelectIndex = self.CurrSelectChapter:GetId()
        self:RefreshChapterInfoShow(self.CurrSelectChapter)
        self:SetChapterInfoBubbleActive(true)
    end, function()
        self:SetChapterInfoBubbleActive(false)
    end)
end

function XUiRiftMain:OpenChildToShowOrHide(flag)
    self.SafeAreaContentPane.gameObject:SetActiveEx(flag)
    -- 不加Open和Close会有“activeInHierarchy依旧为false”的报错
    if flag then
        self.AssetActivityPanel:Open()
    else
        self.AssetActivityPanel:Close()
    end
end

-- 进入区域
function XUiRiftMain:OnBtniRiftFightLayerSelectClick()
    local currPlayingChapter = XDataCenter.RiftManager.GetCurrPlayingChapter()
    if currPlayingChapter and currPlayingChapter ~= self.CurrSelectChapter then
        XUiManager.DialogTip("", XUiHelper.GetText("RiftLayerGiveUp"), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.RiftManager.RiftStopLayerRequest(function()
                self:OnBtniRiftFightLayerSelectClick()
            end)
        end)
        return
    end

    if not self.CurrSelectChapter or self.CurrSelectChapter:CheckHasLock() then
        if self.CurrSelectChapter:CheckPreLock() then
            XUiManager.TipError(CS.XTextManager.GetText("RiftChapterPreLimit"))
            return
        end

        if self.CurrSelectChapter:CheckTimeLock() then
            XUiManager.TipError(CS.XTextManager.GetText("RiftChapterTimeLimit"))
            return
        end
    end
    self:OpenOneChildUi("UiRiftFightLayerSelect", self, self.Panel3D)
    self:OpenChildToShowOrHide(false)
    self.CurrSelectChapter:SaveFirstEnter()
end

-- 结算后自动打开关卡选择界面
function XUiRiftMain:AutoGotoLayer()
    local layerId = XDataCenter.RiftManager.GetIsOpenLayerSelectTrigger()
    local layer = XDataCenter.RiftManager.GetEntityFightLayerById(layerId)
    if layerId and layer then
        self.CurPlayingChapter = XDataCenter.RiftManager.GetEntityChapterById(layer:GetConfig().ChapterId)
        self.CurrSelectIndex = self.CurPlayingChapter:GetId()
        self:OpenOneChildUi("UiRiftFightLayerSelect", self, self.Panel3D, layerId)
        self:OpenChildToShowOrHide(false)
        self.CurPlayingChapter:SaveFirstEnter()
    end
end

-- 点击选中Chapter
function XUiRiftMain:OnChapterSelected(gridRiftChapter3D)
    self.CurrSelectChapter = gridRiftChapter3D.XChapter
    self.CurrSelectIndex = self.CurrSelectChapter:GetId()
    self:RefreshChapterInfoShow(self.CurrSelectChapter)
    self.Panel3D:FocusTargetNodeIndex(self.CurrSelectIndex, -1, function ()
        self:SetChapterInfoBubbleActive(true)
    end)
end

-- 临时新手点击按钮，写死进入chapter1
function XUiRiftMain:OnBtnForGuideClick()
    self.CurrSelectChapter = XDataCenter.RiftManager.GetEntityChapterById(1)
    self.CurrSelectIndex = self.CurrSelectChapter:GetId()
    self:RefreshChapterInfoShow(self.CurrSelectChapter)
    self:SetChapterInfoBubbleActive(true)

    self.BtnRiftFightLayerSelect.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.PanelTangchuan.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.TxtDepth.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.TxtCurrPos.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.TxtOutlier.gameObject:GetComponent("CanvasGroup").alpha = 1
    self.TxtChapterClearProgress.transform.parent:GetComponent("CanvasGroup").alpha = 1
    self.PanelTime.gameObject:GetComponent("CanvasGroup").alpha = 1

    self.BtnForGuide.gameObject:SetActiveEx(false)
end

function XUiRiftMain:SetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
    end, XScheduleManager.SECOND, 0)
end

--显示倒计时与处理倒计时完成时事件
function XUiRiftMain:SetResetTime()
    local startTime, endTimeSecond = XDataCenter.RiftManager.GetTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = CS.XTextManager.GetText("ShopActivityItemCount", remainTime)
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end

--停止界面计时器
function XUiRiftMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--活动周期结束时弹回主界面
function XUiRiftMain:OnActivityReset()
    if self.IsReseting then return end
    self.IsReseting = true
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("RiftFinish"))
end

function XUiRiftMain:OnGuideStart()
    if not self.ChildUi then
        self.BtnForGuide.gameObject:SetActiveEx(true) -- 新手指引临时按钮
    end
end

function XUiRiftMain:OnDisable()
    self:StopTimer()
end

function XUiRiftMain:OnDestroy()
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_START, handler(self, self.OnGuideStart))
end

-- 记录战斗前后数据
function XUiRiftMain:OnReleaseInst()
    local stageGroup = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup()
    if stageGroup then
        return { CurrFightLayer = stageGroup:GetParent() }
    end
    return nil
end

function XUiRiftMain:OnResume(data)
    data = data or {}
    self.ResumeLayer = {}
    local xFightLayer = data.CurrFightLayer
    if xFightLayer then
        self.ResumeLayer = xFightLayer
    end
end

function XUiRiftMain:InitComponent()
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
end

function XUiRiftMain:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(ItemIds)
end

-- 刷新任务ui
function XUiRiftMain:RefreshUiTask()
    local titleName, desc = XDataCenter.RiftManager.GetBtnShowTask()
    local isShow = titleName ~= nil
    self.PanelTask.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTaskName.text = titleName
        self.TxtTaskDesc.text = desc
        local isShowRed = XDataCenter.RiftManager.CheckTaskCanReward()
        self.BtnTask:ShowReddot(isShowRed)
    end
end

-- 刷新商店展示道具
function XUiRiftMain:RefreshShopReward()
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftShop, 1)
    for i, itemId in ipairs(config.ShowItemId) do
        local grid = self.RewardGridList[i]
        if grid == nil then
            local obj = self.GridReward
            if i > 1 then
                obj = CS.UnityEngine.GameObject.Instantiate(self.GridReward, self.GridReward.transform.parent)
            end
            grid = XUiGridCommon.New(self, obj)
            table.insert(self.RewardGridList, grid)
        end
        
        grid:Refresh({TemplateId = itemId})
    end
end

return XUiRiftMain