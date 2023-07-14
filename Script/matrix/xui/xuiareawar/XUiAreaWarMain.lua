local XUiPanelAreaWarMainBlockList3D = require("XUi/XUiAreaWar/XUiPanelAreaWarMainBlockList3D")
local XUiPanelAreaWarMainRank3D = require("XUi/XUiAreaWar/XUiPanelAreaWarMainRank3D")

local pairs = pairs
local CsXTextManagerGetText = CsXTextManagerGetText

local AUTO_REQ_ACTIVITY_DATA_INTERVAL = 2 * 60 * 1000 --界面打开后自动请求最新活动数据时间间隔(ms)

local XUiAreaWarMain = XLuaUiManager.Register(XLuaUi, "UiAreaWarMain")

function XUiAreaWarMain:OnAwake()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self:AutoAddListener()
    self:InitSceneRoot()
end

function XUiAreaWarMain:OnStart()
    self:InitView()
    self:InitReqActivityDataTimer()
end

function XUiAreaWarMain:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self:UpdateLeftTime()
    self:UpdateProgress()
    self:UpdateHangUp()
    self:UpdateTask()
    self:UpdateShop()
    self:UpdatePurificationLevel()
    self:UpdateSpecialRole()
    self:UpdateBlocks()
    self:CheckPopups()
end

function XUiAreaWarMain:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.AreaWar)
end

function XUiAreaWarMain:OnDestroy()
    self:DisposeReqActivityDataTimer()
    self.BlockList3DPanel:OnDispose()
end

function XUiAreaWarMain:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE,
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE,
        XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END,
        XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE
    }
end

function XUiAreaWarMain:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE then
        self:UpdateHangUp()
    elseif evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateSpecialRole()
        self:UpdateProgress()
        self:UpdateBlocks()
        self:CheckPopups()
    elseif evt == XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE then
        self:UpdateBlocks()
    elseif evt == XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE then
        self:UpdatePurificationLevel()
        self:CheckPopups()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarMain:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarMain")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnProgress.CallBack = function()
        self:OnClickBtnProgress()
    end
    self.BtnProfit.CallBack = function()
        self:OnClickBtnProfit()
    end
    self.BtnTask.CallBack = function()
        self:OnClickBtnTask()
    end
    self.BtnShop.CallBack = function()
        self:OnClickBtnShop()
    end
    self.BtnBuff.CallBack = function()
        self:OnClickBtnBuff()
    end
    self.BtnRole.CallBack = function()
        self:OnClickBtnRole()
    end
    self.BtnLocation.CallBack = function()
        self:OnClickBtnLocation()
    end
end

function XUiAreaWarMain:InitView()
    self.TxtTitle.text = XDataCenter.AreaWarManager.GetActivityName()
end

function XUiAreaWarMain:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarMain:UpdateLeftTime()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.AreaWar)
    XCountDown.BindTimer(
        self,
        XCountDown.GTimerName.AreaWar,
        function(time)
            time = time > 0 and time or 0
            local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTime.text = timeText
        end
    )
end

--全服进度
function XUiAreaWarMain:UpdateProgress()
    local clearCount, totalCount = XDataCenter.AreaWarManager.GetBlockProgress()

    self.TxtJd.text = clearCount
    self.TxtJdTotal.text = "/" .. totalCount
    self.ImgJdFillAmount.fillAmount = totalCount ~= 0 and clearCount / totalCount or 1
end

function XUiAreaWarMain:OnClickBtnProgress()
    XLuaUiManager.Open("UiAreaWarInformation")
end

--挂机收益
function XUiAreaWarMain:UpdateHangUp()
    if not XDataCenter.AreaWarManager.IsHangUpUnlock() then
        self.BtnProfit:SetDisable(true)
        return
    end
    self.BtnProfit:SetDisable(false)
    XRedPointManager.AddRedPointEvent(
        self.BtnProfit,
        function(_, count)
            self.BtnProfit:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionAreaWarHangUpReward}
    )
end

function XUiAreaWarMain:OnClickBtnProfit()
    XDataCenter.AreaWarManager.OpenUiHangUp()
end

--任务目标
function XUiAreaWarMain:UpdateTask()
    local tipStr = XDataCenter.AreaWarManager.GetNextTaskProgressTip()
    if not string.IsNilOrEmpty(tipStr) then
        self.BtnTask:SetNameByGroup(0, tipStr)
        self.BtnTask:SetDisable(false)
    else
        self.BtnTask:SetDisable(true)
    end
    XRedPointManager.AddRedPointEvent(
        self.BtnTask,
        function(_, count)
            self.BtnTask:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionAreaWarTask}
    )
end

function XUiAreaWarMain:OnClickBtnTask()
    XLuaUiManager.Open("UiAreaWarTask")
end

--商店
function XUiAreaWarMain:UpdateShop()
    XRedPointManager.AddRedPointEvent(
        self.BtnShop,
        function(_, count)
            self.BtnShop:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionAreaWarCanBuy}
    )
end

function XUiAreaWarMain:OnClickBtnShop()
    XDataCenter.AreaWarManager.OpenUiShop()
end

--净化加成
function XUiAreaWarMain:UpdatePurificationLevel()
    local usingCount, unlockCount = XDataCenter.AreaWarManager.GetPluginProgress()
    self.BtnBuff:SetNameByGroup(0, usingCount)
    self.BtnBuff:SetNameByGroup(1, "/" .. unlockCount)

    if not XDataCenter.AreaWarManager.IsPurificationLevelUnlock() then
        self.BtnBuff:SetDisable(true)
        return
    end
    self.BtnBuff:SetDisable(false)

    XRedPointManager.AddRedPointEvent(
        self.BtnBuff,
        function(_, count)
            self.BtnBuff:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionAreaWarPluginToUnlock}
    )
end

function XUiAreaWarMain:OnClickBtnBuff()
    XDataCenter.AreaWarManager.OpenUiPurificationLevel()
end

--特攻角色
function XUiAreaWarMain:UpdateSpecialRole()
    local unlockCount = XDataCenter.AreaWarManager.GetUnlockSpecialRoleCount()
    self.BtnRole:SetNameByGroup(0, unlockCount)

    if not XDataCenter.AreaWarManager.IsAnySpecialRoleUnlock() then
        self.BtnRole:SetDisable(true)
        return
    end
    self.BtnRole:SetDisable(false)

    XRedPointManager.AddRedPointEvent(
        self.BtnRole,
        function(_, count)
            self.BtnRole:ShowReddot(count >= 0)
        end,
        self,
        {XRedPointConditions.Types.XRedPointConditionAreaWarSpecialRoleReward}
    )
end

function XUiAreaWarMain:OnClickBtnRole()
    XDataCenter.AreaWarManager.OpenUiSpecialRole()
end

function XUiAreaWarMain:OnClickBtnLocation()
    self.NextFightingBlockId = XDataCenter.AreaWarManager.GetNextFightingBlockId(self.NextFightingBlockId)
    if not XTool.IsNumberValid(self.NextFightingBlockId) then
        XUiManager.TipText("AreaWarNoBlockFighting")
        return
    end
    self.BlockList3DPanel:SetNormalCameraFollowBlock(self.NextFightingBlockId)
end

--活动数据刷新定时器
function XUiAreaWarMain:InitReqActivityDataTimer()
    self.ActivityDataTimer =
        self.ActivityDataTimer or
        XScheduleManager.ScheduleForever(
            function()
                XDataCenter.AreaWarManager.AreaWarGetActivityDataRequest()
            end,
            AUTO_REQ_ACTIVITY_DATA_INTERVAL
        )
end

function XUiAreaWarMain:DisposeReqActivityDataTimer()
    if self.ActivityDataTimer then
        XScheduleManager.UnSchedule(self.ActivityDataTimer)
        self.ActivityDataTimer = nil
    end
end

------------------3D场景相关----------------------------
function XUiAreaWarMain:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.VitrulCameraDic = {
        --普通状态下相机
        Normal = {
            root:FindTransform("UiCamFarMain1"):GetComponent("CinemachineVirtualCamera"),
            root:FindTransform("UiCamNearMain1"):GetComponent("CinemachineVirtualCamera")
        },
        --关卡详情下相机
        StageDetail = {
            root:FindTransform("UiCamFarMain2"):GetComponent("CinemachineVirtualCamera"),
            root:FindTransform("UiCamNearMain2"):GetComponent("CinemachineVirtualCamera")
        }
    }

    --区块地图
    local go = root:FindTransform("PanelStageList")
    local go1 = self.UiSceneInfo.Transform:FindTransform("Uimqfjz_02Bai")
    local grids3d = XTool.InitUiObjectByUi({}, go1) --场景中区块对应的3D格子
    local clickBlockCb = handler(self, self.OnClickBlock)
    self.BlockList3DPanel = XUiPanelAreaWarMainBlockList3D.New(go, grids3d, self.VitrulCameraDic, clickBlockCb)

    --区块排行榜
    local go = root:FindTransform("PanelRank")
    self.RankPanel = XUiPanelAreaWarMainRank3D.New(go)
    self.RankPanel.GameObject:SetActiveEx(false)

    self:UpdateVirtualCameras(self.VitrulCameraDic.Normal)
end

function XUiAreaWarMain:UpdateVirtualCameras(showCameras)
    for _, group in pairs(self.VitrulCameraDic) do
        for _, camera in pairs(group) do
            camera.gameObject:SetActiveEx(false)
        end
    end
    for _, camera in pairs(showCameras) do
        camera.gameObject:SetActiveEx(true)
    end
end

--区块展示
function XUiAreaWarMain:UpdateBlocks()
    local canvas = self.Transform:GetComponent("Canvas")
    local canvasUi3D = self.UiModelGo.transform:FindTransform("3DUiCanvas"):GetComponent("Canvas")
    canvasUi3D.sortingOrder = canvas.sortingOrder + 1
    self.RankPanel:Refresh()
    self.BlockList3DPanel:Refresh()

    --更新区块详情
    if self.StageDetailBlockId then
        self:OnOpenStageDetail(self.StageDetailBlockId)
    end
end

--区块被点击
function XUiAreaWarMain:OnClickBlock(blockId)
    if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.WorldBoss) then
        --世界Boss类型区块有独立的主UI
        local asynOpenUi = asynTask(XDataCenter.AreaWarManager.OpenUiWorldBoss)
        local asynPlayAnimation = asynTask(self.PlayAnimationWithMask, self)
        RunAsyn(
            function()
                self:DisposeReqActivityDataTimer()
                self:OnOpenStageDetail(blockId, true)
                asynPlayAnimation("DarkEnable")
                asynOpenUi(blockId)
                asynWaitSecond(0) --等待UI完全重新打开之后再播放动画
                self:OnCloseStageDetail(blockId)
                asynPlayAnimation("DarkDisable")
                self:InitReqActivityDataTimer()
            end
        )
    elseif XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.Mystery) then
        --神秘类型区块只播放剧情
        local movieId = XAreaWarConfigs.GetBlockMovieId(blockId)
        XDataCenter.MovieManager.PlayMovie(movieId)
    else
        --打开区块详情界面
        local closeCb = handler(self, self.OnCloseStageDetail)
        XLuaUiManager.Open("UiAreaWarStageDetail", blockId, closeCb)

        self:OnOpenStageDetail(blockId)
    end
end

--打开区块详情
function XUiAreaWarMain:OnOpenStageDetail(blockId, hideRankPanel)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.StageDetailBlockId = blockId

    --相机推进
    self:UpdateVirtualCameras(self.VitrulCameraDic.StageDetail)

    --锁定区块
    self.BlockList3DPanel:SetDetailCameraFollowBlock(blockId)

    --隐藏主界面2D的UI
    self.SafeAreaContentPane.gameObject:SetActiveEx(false)

    if not hideRankPanel then
        --更新区块排行榜, 并挂载到对应区块父节点上，然后打开
        self.RankPanel:Refresh(blockId)
        self.BlockList3DPanel:SetAsBlockChild(self.RankPanel.Transform, blockId)
        self.RankPanel.GameObject:SetActiveEx(true)
    end

    self:PlayAnimationWithMask("UiDisable")
end

--关闭区块详情
function XUiAreaWarMain:OnCloseStageDetail(blockId)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.StageDetailBlockId = nil

    --显示主界面2D的UI
    self.SafeAreaContentPane.gameObject:SetActiveEx(true)

    --关闭区块排行榜
    self.RankPanel.GameObject:SetActiveEx(false)

    --更新相机
    self:UpdateVirtualCameras(self.VitrulCameraDic.Normal)

    --还原相机跟随目标
    self.BlockList3DPanel:SetNormalCameraFollowBlock(blockId)

    --播放格子的远景动画
    self.BlockList3DPanel:PlayGridFarAnim(blockId)

    self:PlayAnimationWithMask("UiEnable")
end

--[[检查是否有弹窗弹出，优先级：
        1.区块净化进度
        2.净化等级变更
        3.特攻角色解锁
        4.挂机收益功能解锁
    ]]
function XUiAreaWarMain:CheckPopups()
    if self.IsPoping then
        return
    end
    self.IsPoping = true

    local asynPopUp = asynTask(XLuaUiManager.Open)
    local asynPlayAnimation = asynTask(self.PlayAnimationWithMask, self)
    local asynLetsLift = asynTask(self.BlockList3DPanel.LetsLift, self.BlockList3DPanel)
    local asynReqUpdate = asynTask(XDataCenter.AreaWarManager.AreaWarGetActivityDataRequest)

    RunAsyn(
        function()
            local poped = false

            --区块净化进度弹窗
            if XDataCenter.AreaWarManager.CheckHasNewClearBlockId() then
                asynPopUp("UiAreaWarSszbTips")
                poped = true
            end

            --净化等级变更弹窗
            if XDataCenter.AreaWarManager.CheckHasRecordPfLevel() then
                asynPopUp("UiAreaWarJingHuaTips")
                poped = true
            end

            --特攻角色解锁弹窗
            if XDataCenter.AreaWarManager.CheckHasRecordSpecialRole() then
                asynPopUp("UiAreaWarTegongjsTips")
                poped = true
            end

            --挂机收益功能解锁弹窗
            if XDataCenter.AreaWarManager.CheckHangUpUnlockPopUp() then
                asynPopUp("UiAreaWarHangUpJs")
                XDataCenter.AreaWarManager.SetHangUpUnlockPopUpCookie()
                poped = true
            end

            --弹窗展示过了
            if poped then
                --请求服务端最新数据
                asynReqUpdate()
                --通知服务端更新历史记录
                XDataCenter.AreaWarManager.AreaWarPopupRequest()
            end

            XLuaUiManager.SetMask(true)
            --播放3D场景格子升起动画
            asynLetsLift()

            --更新新解锁区块的状态
            self.BlockList3DPanel:RefreshNewUnlockBlocks()

            --清除已经弹窗展示过的最新记录
            XDataCenter.AreaWarManager.ClearNewRecord()

            XLuaUiManager.SetMask(false)

            self.IsPoping = nil
        end
    )
end
