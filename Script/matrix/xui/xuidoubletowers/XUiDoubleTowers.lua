local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local CSXTextManagerGetText = CS.XTextManager.GetText
local StageState = XDoubleTowersConfigs.StageState
local CHILD_DETAIL_UI_NAME = "UiDoubleTowersDetail"
local SPECIAL_DOOR_INDEX = 0
local UI_DOOR_AMOUNT = 8
local UI_DOOR_BORDER = 50
local FOCUS_TIME = 0.5

---@class XUiDoubleTowers:XLuaUi
local XUiDoubleTowers = XLuaUiManager.Register(XLuaUi, "UiDoubleTowers")

--region init
function XUiDoubleTowers:Ctor()
    self._Timer = false
    self._PlaceDoorTimer = false
    self._SelectedGroupIndex = false
    self._FocusGroupIndex = false
    ---@type XUiDoubleTowersDoor[]
    self._UiDoor = {}
    self._DragAreaComponent = false
    self._FocusOffset = false
    self._CenterOffset = false
end

function XUiDoubleTowers:OnStart()
end

function XUiDoubleTowers:OnAwake()
    self:Init()
    self:InitCoinUi()
    -- 禁止玩家操作
    self:SetDragEnabled(false)
end

function XUiDoubleTowers:OnEnable()
    self:StartTimer()
    self:AddListeners()
    self:CheckSlotRedPoint()
    self:CheckTaskRedPoint()
    for i = 1, #self._UiDoor do
        self._UiDoor[i]:OnEnable()
    end
    -- 屏蔽排行榜红点显示
    self.BtnGradient:ShowReddot(false)
    self:OpenNextStageAfterFight()
end

function XUiDoubleTowers:OnDisable()
    self:StopTimer()
    self:RemoveListeners()

    for i = 1, #self._UiDoor do
        self._UiDoor[i]:OnDisable()
    end
end

-- 通关后打开下一关
function XUiDoubleTowers:OpenNextStageAfterFight()
    local justPassedStageId = XDataCenter.DoubleTowersManager.GetJustPassedStage()
    if justPassedStageId then
        local nextStageId = XDataCenter.DoubleTowersManager.GetNextStageId(justPassedStageId)
        if nextStageId and XDataCenter.DoubleTowersManager.IsStageCanChallenge(nextStageId) then
            self:OpenStage(nextStageId)
        else
            -- 找不到下一关，重复打开
            self:OpenStage(justPassedStageId)
        end
    end
end

function XUiDoubleTowers:Init()
    self:InitViews()
    self:RegisterButtonClick()
end

function XUiDoubleTowers:AddListeners()
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, self.OpenStageDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_FOCUS, self.FocusDoor, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_ON_OPENED_ROOM, self.OnRoomOpened, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_UPDATE_GATHER, self.UpdateGather, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_STAGE, self.OpenStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_DOUBLE_TOWERS_SLOT_UNLOCK, self.CheckSlotRedPoint, self)
end

function XUiDoubleTowers:RemoveListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, self.OpenStageDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_FOCUS, self.FocusDoor, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_ON_OPENED_ROOM, self.OnRoomOpened, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_UPDATE_GATHER, self.UpdateGather, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_OPEN_STAGE, self.OpenStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DOUBLE_TOWERS_SLOT_UNLOCK, self.CheckSlotRedPoint, self)
end
--endregion

--region click
function XUiDoubleTowers:RegisterButtonClick()
    -- back and main
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    -- 任务
    self:RegisterClickEvent(self.BtnMileage, self.OnClickTaskBtn)
    -- 排行榜
    self:RegisterClickEvent(self.BtnGradient, self.OnClickRankBtn)
    -- 部署成员
    self:RegisterClickEvent(self.BtnDeploy, self.OnClickDeployBtn)
    -- 收菜
    self:RegisterClickEvent(self.BtnTreasure, self.OnClickGatherBtn)
    -- 图文教学界面
    self:BindHelpBtn(self.BtnHelp, XDataCenter.DoubleTowersManager.GetHelpKey())
    -- 关闭detail界面
    self:RegisterClickEvent(self.BtnCloseDetail, self.OnClickBtnCloseDetail)

    -- 普通关卡
    for groupIndex = 1, UI_DOOR_AMOUNT do
        local uiDoor = self:GetUiDoor(groupIndex)
        local buttonComponent = uiDoor:GetButtonComponent()
        self:RegisterClickEvent(
            uiDoor:GetButtonComponent(),
            function()
                self:onDoorBtnClick(groupIndex)
            end
        )
    end
    -- 特殊关卡
    local uiDoor = self:GetUiDoor(SPECIAL_DOOR_INDEX)
    self:RegisterClickEvent(
        uiDoor:GetButtonComponent(),
        function()
            self:onSpecialDoorBtnClick()
        end
    )
    
end

function XUiDoubleTowers:onSpecialDoorBtnClick()
    local stageId = XDataCenter.DoubleTowersManager.GetSpecialStageId()
    if not XDataCenter.DoubleTowersManager.IsStageCanChallenge(stageId) then
        XUiManager.TipErrorWithKey("DoubleTowersAllStageNotClear")
        return
    end
    self:OpenStageDetail(stageId)
    self:SetDoorSelected(SPECIAL_DOOR_INDEX)
    XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_FOCUS, SPECIAL_DOOR_INDEX)
end

function XUiDoubleTowers:OnClickRankBtn()
    if not XDataCenter.DoubleTowersManager.IsSpecialGroupUnlock() then
        XUiManager.TipErrorWithKey("DoubleTowersLockRank")
    -- return 策划要求可以打开，但伴随提示
    end
    XDataCenter.DoubleTowersManager.RequestDoubleTowerGetRank(
        function()
            XLuaUiManager.Open("UiDoubleTowersRank")
        end
    )
end

function XUiDoubleTowers:CheckTaskRedPoint()
    self.BtnMileage:ShowReddot(XDataCenter.TaskManager.GetIsRewardForEx(TaskType.DoubleTower))
end

function XUiDoubleTowers:OnClickTaskBtn()
    XLuaUiManager.Open(
        "UiFubenTaskReward",
        TaskType.DoubleTower,
        nil,
        function()
            self:CheckTaskRedPoint()
        end
    )
end

function XUiDoubleTowers:OnClickDeployBtn()
    XLuaUiManager.Open("UiDoubleTowersDeploy")
end

function XUiDoubleTowers:OnClickGatherBtn()
    local canGatherCoins = XDataCenter.DoubleTowersManager.GetCanGatherCoins()
    if canGatherCoins <= 0 then
        XUiManager.TipText("DoubleTowersGatherFail")
        return
    end
    -- 请求收菜
    XDataCenter.DoubleTowersManager.RequestGatherCoins()
end

function XUiDoubleTowers:OnClickBtnCloseDetail()
    self:ClearDoorSelected()
end
--endregion

--region 收菜 gather
function XUiDoubleTowers:StartTimer()
    if self._Timer then
        return
    end
    self:UpdateGather()
    self._Timer =
        XScheduleManager.ScheduleForever(
        function()
            self:UpdateGather()
        end,
        XScheduleManager.SECOND
    )
end

function XUiDoubleTowers:UpdateGather()
    if not self:UpdateTime() then
        return
    end
    self:UpdateCoin()
    self:CheckRedPoint()
end

function XUiDoubleTowers:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

-- set coin icon
function XUiDoubleTowers:InitCoinUi()
    local ImgCoin =
        XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelProgress/PanelTool/RImgTool1", "RawImage")
    local itemId = XDataCenter.DoubleTowersManager.GetCoinItemId()
    local item = XDataCenter.ItemManager.GetItem(itemId)
    ImgCoin:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
end

function XUiDoubleTowers:UpdateTime()
    local remainTime = XDataCenter.DoubleTowersManager.GetActivityRemainTime()
    if remainTime <= 0 then
        self:Close()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        return false
    end
    self.TimeTxt.text = XUiHelper.GetTime(remainTime)
    return true
end

-- 收菜时间和币
function XUiDoubleTowers:UpdateCoin()
    -- 代币
    local canGatherCoins = XDataCenter.DoubleTowersManager.GetCanGatherCoins()
    local maxCoinsAmount = XDataCenter.DoubleTowersManager.GetMaxCoinAmount()

    local gatherReaminTime, gatherInterval = XDataCenter.DoubleTowersManager.GetGatherRemainTime()

    -- 时间进度
    self.ImgProgress.fillAmount = (gatherInterval - gatherReaminTime) / gatherInterval

    -- 收菜时间
    self.GatherTimeTxt.text = XUiHelper.GetTime(gatherReaminTime, XUiHelper.TimeFormatType.DOUBLE_TOWER)

    if canGatherCoins == maxCoinsAmount then
        self.CoinTxt.text = string.format("<color=#189affFF>%d/%d</color>", canGatherCoins, maxCoinsAmount)
        return
    end
    self.CoinTxt.text = string.format("%d/%d", canGatherCoins, maxCoinsAmount)
end
--endregion

--region 关卡
function XUiDoubleTowers:onDoorBtnClick(groupIndex)
    return self:SetDoorSelected(groupIndex)
end
-- 折叠 X之门
function XUiDoubleTowers:FoldDoor(groupIndex)
    if not groupIndex then
        return
    end
    local uiDoor = self:GetUiDoor(groupIndex)
    if uiDoor then
        uiDoor:Fold()
    end
end
-- 展开 X之门
function XUiDoubleTowers:UnfoldDoor(groupIndex)
    if not groupIndex then
        return false
    end
    if not self:CheckGroupOpen(groupIndex) then
        return
    end
    local groupBtn = self:GetUiDoor(groupIndex)
    if groupBtn then
        groupBtn:Unfold()
        -- 只在展开的时候更新
        local groupId = XDataCenter.DoubleTowersManager.GetGroupId(groupIndex)
        groupBtn:UpdateStage(groupId)
    end
    return true
end

function XUiDoubleTowers:CheckGroupOpen(groupIndex)
    local groupId = XDataCenter.DoubleTowersManager.GetGroupId(groupIndex)
    local state = XDataCenter.DoubleTowersManager.GetGroupState(groupId)

    -- 未解锁
    if state == StageState.Lock then
        local reason = XDataCenter.DoubleTowersManager.GetGroupLockReason(groupId)
        if reason == XDoubleTowersConfigs.ReasonOfLockGroup.TimeLimit then
            local groupName = XDoubleTowersConfigs.GetGroupName(groupId)
            XUiManager.TipErrorWithKey("DoubleTowersStageTimeLimit", groupName)
            return false
        end
        if reason == XDoubleTowersConfigs.ReasonOfLockGroup.PreconditionStageNotClear then
            -- tip 请先通过 前置关卡名
            local preconditionStageId = XDoubleTowersConfigs.GetGroupPreconditionStage(groupId)
            if not XDataCenter.DoubleTowersManager.IsStageClear(preconditionStageId) then
                local preconditionStageName = XDoubleTowersConfigs.GetStageName(preconditionStageId)
                XUiManager.TipErrorWithKey("DoubleTowersPreconditionGroupNotClear", preconditionStageName)
            else
                XLog.Debug("[XUiDoubleTowers] other reason to lock group, please fix it")
            end
            return false
        end
        return false
    end
    return true
end

-- 可能是普通关卡or特殊关卡
function XUiDoubleTowers:GetUiDoor(groupIndex)
    local uiDoor = self._UiDoor[groupIndex]
    if not uiDoor then
        if groupIndex == SPECIAL_DOOR_INDEX then
            local uiStage = self.GridMajorTower
            local XUiDoubleTowersSpecialDoor = require("XUi/XUiDoubleTowers/XUiDoubleTowersSpecialDoor")
            uiDoor = XUiDoubleTowersSpecialDoor.New(uiStage)
        else
            local XUiDoubleTowersDoor = require("XUi/XUiDoubleTowers/XUiDoubleTowersDoor")
            local uiStage = self.PanelTower:Find(string.format("Stage%s/GridTower", groupIndex))
            if not uiStage then
                XLog.Warning("[XUiDoubleTowers] 找不到门的ui，门的序号是", groupIndex)
                return false
            end
            uiDoor = XUiDoubleTowersDoor.New(uiStage)
        end
        self._UiDoor[groupIndex] = uiDoor
    end
    return uiDoor
end

function XUiDoubleTowers:InitDoor()
    for groupIndex = 1, UI_DOOR_AMOUNT do
        local uiDoor = self:GetUiDoor(groupIndex)
        if uiDoor then
            local groupId = XDataCenter.DoubleTowersManager.GetGroupId(groupIndex)
            uiDoor:SetGroup(groupId)
            -- 假如美术加了z，强制归0，否则随着每次focus，z值会越来越大
            if uiDoor.Transform.localPosition.z ~= 0 then
                uiDoor.Transform.localPosition =
                    Vector3(uiDoor.Transform.localPosition.x, uiDoor.Transform.localPosition.y, 0)
            end
        end
    end
end

function XUiDoubleTowers:UpdateSpecialDoor()
    ---@type XUiDoubleTowersSpecialDoor
    local uiDoor = self:GetUiDoor(SPECIAL_DOOR_INDEX)
    uiDoor:Refresh()
end

-- 选中关卡
function XUiDoubleTowers:SetDoorSelected(groupIndex)
    if self._SelectedGroupIndex == groupIndex then
        if groupIndex then
            self:CheckGroupOpen(groupIndex)
            self:SetDoorSelected(false)
        end
        --点击未解锁关卡，重复弹tips
        return false
    end
    -- 特殊关卡ui结构与普通关卡不同，选中时就打开detail，故不关闭
    if groupIndex ~= SPECIAL_DOOR_INDEX then
        self:CloseStageDetail()
    -- local groupId = XDataCenter.DoubleTowersManager.GetGroupId(groupIndex)
    -- 已通关
    -- if XDataCenter.DoubleTowersManager.GetGroupState(groupId) == XDoubleTowersConfigs.StageState.Clear then
    --     XUiManager.TipText("DoubleTowersPassed")
    --     return
    -- end
    end
    self:FoldDoor(self._SelectedGroupIndex)
    self:UnfoldDoor(groupIndex)
    self._SelectedGroupIndex = groupIndex
    return true
end

function XUiDoubleTowers:ClearDoorSelected()
    self:SetDoorSelected(false)
    self:CloseStageDetail()
end
--endregion

--region ui
function XUiDoubleTowers:InitViews()
    self._DragAreaComponent = self.PanelDrag:GetComponentInChildren(typeof(CS.XDragArea))
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.DoubleTowersManager.GetCoinItemId())
    self:InitDoor()
    self:UpdateSpecialDoor()
end

function XUiDoubleTowers:OpenStageDetail(stageId)
    if not XLuaUiManager.IsUiShow(CHILD_DETAIL_UI_NAME) then
        self:PlayAnimation("UiDisable")
        self:OpenOneChildUi(CHILD_DETAIL_UI_NAME, self)
    end
    self:FindChildUiObj(CHILD_DETAIL_UI_NAME):SetStage(stageId)
end

function XUiDoubleTowers:CloseStageDetail()
    XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_ON_DETAIL_CLOSED)
    if XLuaUiManager.IsUiShow(CHILD_DETAIL_UI_NAME) then
        self:PlayAnimation("UiEnable")
        self:FindChildUiObj(CHILD_DETAIL_UI_NAME):CloseDetailWithAnimation()
        self:FocusDoor(false)
    end
end

function XUiDoubleTowers:OnRoomOpened()
    -- self:ClearDoorSelected()
end
--endregion

--region 伪聚焦
function XUiDoubleTowers:OpenStage(stageId)
    local groupIndex = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
    local groupId = XDataCenter.DoubleTowersManager.GetGroupId(groupIndex)
    if XDataCenter.DoubleTowersManager.IsSpecialGroup(groupId) then
        self:onSpecialDoorBtnClick()
    else
        self:onDoorBtnClick(groupIndex)
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_FOCUS, groupIndex)
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_OPEN_DETAIL, stageId)
    end
end

-- 这是虚假的禁止拖拽，利用EndFocus函数，在awake的时候focus一次，但是不end，后续每次focus前end一次
function XUiDoubleTowers:SetDragEnabled(value)
    if value then
        self._DragAreaComponent:EndFocus()
    else
        self:FocusCenter()
    end
end

function XUiDoubleTowers:FocusDoor(groupIndex)
    if groupIndex == self._FocusGroupIndex then
        return
    end
    self._FocusGroupIndex = groupIndex

    if groupIndex then
        local door = self:GetUiDoor(groupIndex)
        if door then
            if not self._FocusOffset then
                local screen = CS.UnityEngine.Screen
                local leftPos =
                    CS.XUiManager.Instance.UiCamera:ScreenToWorldPoint(
                    Vector3(screen.width / 4, screen.height / 2, self.Transform.position.z)
                )
                local centerPos =
                    CS.XUiManager.Instance.UiCamera:ScreenToWorldPoint(
                    Vector3(screen.width / 2, screen.height / 2, self.Transform.position.z)
                )
                local offsetX = leftPos.x - centerPos.x
                self._FocusOffset = Vector3(offsetX, 0, 0)
            end
            self:SetDragEnabled(true)
            self._DragAreaComponent:StartFocus(
                door.Transform.position,
                self._DragAreaComponent.MaxScale,
                FOCUS_TIME,
                self._FocusOffset,
                false
            )
            return
        end
    end
    self:SetDragEnabled(true)
    self:FocusCenter()
end

function XUiDoubleTowers:FocusCenter()
    if not self._CenterOffset then
        -- 保留美术设置的ui偏移
        local screen = CS.UnityEngine.Screen
        local centerPos =
            CS.XUiManager.Instance.UiCamera:ScreenToWorldPoint(
            Vector3(screen.width / 2, screen.height / 2, self.Transform.position.z)
        )
        local stageCenterTransform = self.PanelTower
        local offsetPosition = stageCenterTransform.position
        self._CenterOffset = centerPos - offsetPosition
    end

    -- 取一个居中transform的位置，也可以是别的
    local stageCenterTransform = self.PanelTower
    local offset = Vector3.zero
    self._DragAreaComponent:StartFocus(
        stageCenterTransform.position + self._CenterOffset,
        self._DragAreaComponent.MinScale,
        FOCUS_TIME,
        offset,
        false
    )
end
--endregion

--region red point
function XUiDoubleTowers:CheckRedPoint()
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, {XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS})
end

function XUiDoubleTowers:OnCheckRedPoint(count)
    --有可收集代币时，仅在内部显示红点
    self.ImgRedPoint.gameObject:SetActive(count > 0 or XDataCenter.DoubleTowersManager.GetCanGatherCoins() > 0)
end

function XUiDoubleTowers:CheckSlotRedPoint()
    XRedPointManager.CheckOnce(
        self.OnCheckBtnDeployRedPoint,
        self,
        {XRedPointConditions.Types.CONDITION_DOUBLE_TOWERS_SLOT_UNLOCKED}
    )
end

function XUiDoubleTowers:OnCheckBtnDeployRedPoint(count)
    self.BtnDeploy:ShowReddot(count >= 0)
end
--endregion

return XUiDoubleTowers
