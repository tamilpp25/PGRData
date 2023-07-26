local XUiGridTerminalTeamQuest = require("XUi/XUiDormQuest/XUiGridTerminalTeamQuest")
local XUiGridTerminalQuest = require("XUi/XUiDormQuest/XUiGridTerminalQuest")
local XUiPanelTerminalLevelUpgrade = require("XUi/XUiDormQuest/XUiPanelTerminalLevelUpgrade")
local XUiPanelTerminalMemberSelect = require("XUi/XUiDormQuest/XUiPanelTerminalMemberSelect")
local XUiPanelTerminalTips = require("XUi/XUiDormQuest/XUiPanelTerminalTips")

local ChildUiName = "UiDormTerminalLineDetail"
local XUguiDragProxy = CS.XUguiDragProxy

-- 宿舍委托终端
---@class XUiDormTerminalSystem : XLuaUi
local XUiDormTerminalSystem = XLuaUiManager.Register(XLuaUi, "UiDormTerminalSystem")

function XUiDormTerminalSystem:OnAwake()
    self:RegisterUiEvents()
    
    self.PanelLevelUpgrade.gameObject:SetActiveEx(false)
    self.GridTeamQuest.gameObject:SetActiveEx(false)
    self.PanelTerminal.gameObject:SetActiveEx(false)
    
    self.GridQuestList = {}
    self.CacheShowTips = {}
end

function XUiDormTerminalSystem:OnStart()
    local itemIds = { XDataCenter.ItemManager.ItemId.Coin, XDataCenter.ItemManager.ItemId.DormCoin, XDataCenter.ItemManager.ItemId.DormQuestCoin }
    local canBuyItemIds = { XDataCenter.ItemManager.ItemId.Coin }
    self.AssetPanel = XUiHelper.NewPanelActivityAsset(itemIds, self.PanelSpecialTool, nil, nil, canBuyItemIds)
    ---@type XDormTerminalTeam
    self.TerminalTeamEntity = XDataCenter.DormQuestManager.GetDormTerminalTeamEntity()
    ---@type XUiPanelTerminalLevelUpgrade
    self.TerminalLevelUpgrade = XUiPanelTerminalLevelUpgrade.New(self.PanelLevelUpgrade, self)
    ---@type XUiPanelTerminalMemberSelect
    self.TerminalMemberSelect = XUiPanelTerminalMemberSelect.New(self.PanelSelect, self, handler(self, self.MemberSelectCallBack))
    ---@type XUiPanelTerminalTips
    self.TerminalTips = XUiPanelTerminalTips.New(self.PaneTips, self)
    -- 特殊委托
    ---@type XUiGridTerminalQuest
    self.GridSpecialQuest = XUiGridTerminalQuest.New(self.PanelTerminalSs, self, handler(self, self.ClickQuestGrid), true)

    -- 拖拽
    local dragProxy = self.PaneQuestList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneQuestList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    self:InitTerminalUi()
    self:InitDynamicTable()
end

function XUiDormTerminalSystem:OnEnable()
    self:NextStartTimer()
    self:RefreshTerminalQuest()
    self:SetupDynamicTable()
    self:CheckBtnFileRedPoint()
    -- 检查是否升级
    self:CheckTerminalUpgradeSuccess()
    -- 检测是否显示可升级提示
    self:ShowTips(true, false)
end

function XUiDormTerminalSystem:OnGetEvents()
    return {
        XEventId.EVENT_DORM_TERMINAL_ACCEPT_QUEST,
        XEventId.EVENT_DORM_TERMINAL_QUEST_UPDATE,
    }
end

function XUiDormTerminalSystem:OnNotify(event, ...)
    if event == XEventId.EVENT_DORM_TERMINAL_ACCEPT_QUEST then
        self:TerminalAcceptQuest(...)
    elseif event == XEventId.EVENT_DORM_TERMINAL_QUEST_UPDATE then
        if XDataCenter.DormQuestManager.CheckIsAwarding() then
            table.insert(self.CacheShowTips, handler(self, self.TerminalQuestUpdate))
        else
            self:TerminalQuestUpdate()
        end
    end
end

function XUiDormTerminalSystem:OnDisable()
    self.CacheShowTips = {}
    self:BtnStopTimer()
    self:NextStopTimer()
    self:CancelSelect()
    self.TerminalLevelUpgrade:OnDisable()
    self.TerminalTips:OnDisable()
end

function XUiDormTerminalSystem:InitTerminalUi()
    ---@type XDormQuestTerminal
    self.TerminalViewModel = XDataCenter.DormQuestManager.GetCurLevelTerminalViewModel()
    -- 终端等级
    self.TxtTerminalLevel.text = self.TerminalViewModel:GetTerminalLvDesc()
    self.PanelReward.gameObject:SetActiveEx(false)
    XDataCenter.DormQuestManager.CheckPopupShopTip(function(isShow)
        if not isShow then
            return
        end
        self:OnShowShopTip()
    end)
end

-- 刷新终端按钮
function XUiDormTerminalSystem:UpdateTerminalBtn()
    local isGoing = self.TerminalViewModel:CheckTerminalOnGoing()
    self:ActiveTerminalBtnUi(isGoing)
    if isGoing then
        self.FinishTime = self.TerminalViewModel:GetTerminalUpgradeFinishTime()
        self:BtnStartTimer()
    else
        self:BtnStopTimer()
    end
    -- 终端按钮红点
    local isUpgrade = self.TerminalViewModel:CheckTerminalCanUpgrade()
    self.BtnTerminalSystem:ShowReddot(isUpgrade)
end

function XUiDormTerminalSystem:ActiveTerminalBtnUi(isActive)
    self.BtnTerminalSystem:ActiveTextByGroup(0, not isActive)
    self.ImgUpgradeNormal.gameObject:SetActiveEx(isActive)
    self.ImgUpgradePress.gameObject:SetActiveEx(isActive)
end

-- 检查档案馆红点
function XUiDormTerminalSystem:CheckBtnFileRedPoint()
    local fileRedPoint = XDataCenter.DormQuestManager.CheckQuestFileRedPoint()
    self.BtnFile:ShowReddot(fileRedPoint)
end

function XUiDormTerminalSystem:RefreshTerminalQuest()
    local allQuestData = XDataCenter.DormQuestManager.GetTerminalAllQuestData()
    local maxQuestCount = XDataCenter.DormQuestManager.GetTerminalMaxQuestCount()
    -- 特殊委托 默认解锁
    self.GridSpecialQuest:Refresh(allQuestData.SpecialQuest, true)
    -- 委托
    for i = 1, maxQuestCount - 1 do
        local questData = allQuestData.Quest[i]
        local grid = self.GridQuestList[i]
        if not grid then
            local parent = XUiHelper.TryGetComponent(self.PanelQuestContent, string.format("Stage%d", i))
            local go = XUiHelper.Instantiate(self.PanelTerminal, parent)
            grid = XUiGridTerminalQuest.New(go, self, handler(self, self.ClickQuestGrid))
            self.GridQuestList[i] = grid
            grid.GameObject:SetActiveEx(true)
            grid.Parent = parent
        end
        -- 是否解锁
        local curQuestCount = self.TerminalViewModel:GetQuestTerminalQuestCount() - 1
        local isUnlock = i <= curQuestCount
        grid:Refresh(questData, isUnlock)
    end
end

function XUiDormTerminalSystem:ShowQuestDetail(questId, index)
    if not XLuaUiManager.IsUiShow(ChildUiName) then
        self:OpenOneChildUi(ChildUiName, self)
    end
    self:FindChildUiObj(ChildUiName):Refresh(questId, index)
end

function XUiDormTerminalSystem:HideQuestDetail()
    local childUiObj = self:FindChildUiObj(ChildUiName)
    if childUiObj then
        childUiObj:Hide()
    end
end

function XUiDormTerminalSystem:CloseQuestDetail()
    if XLuaUiManager.IsUiShow(ChildUiName) then
        self:CancelSelect()
        return true
    end
    return false
end

-- 选中一个委托Grid
---@param grid XUiGridTerminalQuest
function XUiDormTerminalSystem:ClickQuestGrid(grid)
    local curGrid = self.CurQuestGrid
    if curGrid and curGrid.Index == grid.Index then
        return
    end
    -- 选中回调
    self:ShowQuestDetail(grid.QuestId, grid.Index)
    -- 取消上一个选择
    if curGrid then
        curGrid:SetQuestSelect(false)
        if not curGrid.IsSpecialQuest and grid.IsSpecialQuest then
            self.PaneQuestScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        end
    end
    -- 选中当前选择
    grid:SetQuestSelect(true)
    if not curGrid then
        self:PlayAnimation("SystemDisable")
    end
    
    if not grid.IsSpecialQuest then
        -- 滚动容器自由移动
        self.PaneQuestScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        -- 面板移动
        self:PlayScrollViewMove(grid)
    else
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false)
        end, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration * 1000)
    end
    
    self.CurQuestGrid = grid
end

function XUiDormTerminalSystem:CancelSelect()
    if not self.CurQuestGrid then
        return
    end
    if not self.CurQuestGrid.IsSpecialQuest then
        self.PaneQuestScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    end
    -- 取消当前选择
    self.CurQuestGrid:SetQuestSelect(false)
    self.CurQuestGrid = nil
    self:PlayAnimation("SystemEnable")
    -- 取消回调
    self:HideQuestDetail()
end

function XUiDormTerminalSystem:OnDragProxy(dragType)
    if dragType == 0 then
        self:CancelSelect()
    end
end

function XUiDormTerminalSystem:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelQuestContent.localPosition.x
    if diffX < XDormQuestConfigs.UiGridQuestMoveMinX or diffX > XDormQuestConfigs.UiGridQuestMoveMaxX then
        local tarPosX = XDormQuestConfigs.UiGridQuestMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelQuestContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelQuestContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiDormTerminalSystem:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTeamList)
    self.DynamicTable:SetProxy(XUiGridTerminalTeamQuest, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormTerminalSystem:SetupDynamicTable()
    self.DataList = self.TerminalTeamEntity:GetTerminalTeamList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTerminalTeamQuest
function XUiDormTerminalSystem:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CacheShowTips = {}
        grid:OnBtnClick()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnClose()
    end
end

-- 检查终端是否升级
function XUiDormTerminalSystem:CheckTerminalUpgradeSuccess()
    XDataCenter.DormQuestManager.CheckTerminalUpgradeSuccess(function(isUpgrade, isRefreshUi, oldLevel, curLevel)
        if isUpgrade then
            XDataCenter.DormQuestManager.SaveQuestTerminalLevel()
            self.TerminalLevelUpgrade:Refresh(oldLevel, curLevel)
        end
        if isRefreshUi then
            -- 刷新Ui
            self:InitTerminalUi()
            self:RefreshTerminalQuest()
            self:SetupDynamicTable()
        end
        -- 刷新终端按钮
        self:UpdateTerminalBtn()
    end)
end

-- 召回队伍
function XUiDormTerminalSystem:ShowRecallTeamUi(index, resetCount)
    local title = XUiHelper.GetText("DormQuestTerminalRecallTeamTitle")
    local content = XUiHelper.ReadTextWithNewLine("DormQuestTerminalRecallTeamContent")
    local SureCallback = function()
        XDataCenter.DormQuestManager.QuestRecallTeamRequest(index, resetCount, function()
            -- 刷新委托面板和队伍面板
            self:RefreshTerminalQuest()
            self:SetupDynamicTable()
        end)
    end
    XUiManager.DialogDragTip(title, content, XUiManager.DialogType.Normal, nil, SureCallback)
end

-- 委托完成领取奖励
function XUiDormTerminalSystem:QuestFinishReceiveReward(finishQuestInfos)
    local asynOpenCompleteDetail = asynTask(function(finishQuestInfo, cb)
        XLuaUiManager.Open("UiDormTerminalCompleteDetail", finishQuestInfo, cb)
    end)
    RunAsyn(function()
        for _, finishQuestInfo in pairs(finishQuestInfos) do
            asynOpenCompleteDetail(finishQuestInfo)
        end
        -- 领取奖励结束
        XDataCenter.DormQuestManager.SetIsAwarding(false)
        -- 刷新队伍面板
        self:SetupDynamicTable()
        -- 刷新终端按钮
        self:UpdateTerminalBtn()
        self:CheckBtnFileRedPoint()
        -- 显示弹框
        self:ShowTips(true, true)
        for _, func in pairs(self.CacheShowTips) do
            func()
        end
        self.CacheShowTips = {}
    end)
end

-- 显示弹框
function XUiDormTerminalSystem:ShowTips(isUpgrade, isFile)
    if isUpgrade then
        -- 检查是否可升级
        local isShowUpgradeTips = self:CheckIsShowUpgradeTips()
        if isShowUpgradeTips then
            self.TerminalTips:ShowUpgradeTips()
        end
    end
    if isFile then
        -- 检查是否获得新文件
        local isNewFile = XDataCenter.DormQuestManager.GetIsHaveNewQuestFile()
        if isNewFile then
            self.TerminalTips:ShowFileTips()
        end
    end
end

function XUiDormTerminalSystem:CheckIsShowUpgradeTips()
    local isUpgrade = self.TerminalViewModel:CheckTerminalCanUpgrade()
    local isShowed = XDataCenter.DormQuestManager.CheckTerminalShowUpgradeTip()
    return isUpgrade and not isShowed
end

-- 接取委托
function XUiDormTerminalSystem:TerminalAcceptQuest(questId, index)
    -- 打开成员选择界面
    self.TerminalMemberSelect:Refresh(questId, index)
end

function XUiDormTerminalSystem:MemberSelectCallBack()
    -- 点击确认后关闭详情面板
    self:CancelSelect()
    -- 刷新委托面板和队伍面板
    self:RefreshTerminalQuest()
    self:SetupDynamicTable()
end

-- 委托刷新
function XUiDormTerminalSystem:TerminalQuestUpdate()
    -- 委托刷新时 关闭详情界面
    self:CloseQuestDetail()
    XUiManager.TipText("DormQuestTerminalQuestUpdate")
    self:RefreshTerminalQuest()
end

function XUiDormTerminalSystem:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTerminalSystem, self.OnBtnTerminalSystemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFile, self.OnBtnFileClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnBtnCloseDetailClick)
    self:BindHelpBtn(self.BtnHelp, "DormTerminalSystem")

    -- ScrollRect的点击会触发关闭详细面板
    XUiHelper.RegisterClickEvent(self, self.PaneQuestScrollRect, self.OnBtnCloseDetailClick)
end

function XUiDormTerminalSystem:Close()
    if self:CloseQuestDetail() then
        return
    end
    self.Super.Close(self)
end

function XUiDormTerminalSystem:OnBtnMainUiClick()
    if self:CloseQuestDetail() then
        return
    end
    XDataCenter.DormManager.ExitDormitoryBackToMain()
end

-- 终端升级
function XUiDormTerminalSystem:OnBtnTerminalSystemClick()
    if self:CloseQuestDetail() then
        return
    end
    XLuaUiManager.Open("UiDormTerminalUpgradeDetail",function()
        -- 刷新终端按钮
        self:UpdateTerminalBtn()
    end)
end

-- 档案
function XUiDormTerminalSystem:OnBtnFileClick()
    XLuaUiManager.Open("UiDormArchivesCenter")
end

-- 商店
function XUiDormTerminalSystem:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm, nil, XDataCenter.DormQuestManager.GetShopId())
end

function XUiDormTerminalSystem:OnBtnCloseDetailClick()
    self:CancelSelect()
end

function XUiDormTerminalSystem:OnShowShopTip()
    self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self, self.GridReward)
    self.RewardGrid:Refresh(XDataCenter.DormQuestManager.GetShowFragmentId())
    self.PanelReward.gameObject:SetActiveEx(true)
end

--region 计时器

function XUiDormTerminalSystem:BtnStartTimer()
    if self.BtnTimer then
        self:BtnStopTimer()
    end

    self:BtnUpdateTimer()
    self.BtnTimer = XScheduleManager.ScheduleForever(function()
        self:BtnUpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiDormTerminalSystem:BtnUpdateTimer()
    if XTool.UObjIsNil(self.BtnTerminalSystem) then
        self:BtnStopTimer()
        return
    end

    local endTime = self.FinishTime
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:BtnStopTimer()
        if XDataCenter.DormQuestManager.CheckIsAwarding() then
            table.insert(self.CacheShowTips, handler(self, self.CheckTerminalUpgradeSuccess))
        else
            self:CheckTerminalUpgradeSuccess()
        end
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.BtnTerminalSystem:SetNameByGroup(1, XUiHelper.GetText("DormQuestTerminalUpgradeTime", timeText))
end

function XUiDormTerminalSystem:BtnStopTimer()
    if self.BtnTimer then
        XScheduleManager.UnSchedule(self.BtnTimer)
        self.BtnTimer = nil
    end
end

function XUiDormTerminalSystem:NextStartTimer()
    if self.NextTimer then
        self:NextStopTimer()
    end

    self:NextUpdateTimer()
    self.NextTimer = XScheduleManager.ScheduleForever(function()
        self:NextUpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiDormTerminalSystem:NextUpdateTimer()
    if XTool.UObjIsNil(self.TxtNextTime) then
        self:NextStopTimer()
        return
    end

    local endTime = XTime.GetSeverNextRefreshTime()
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        leftTime = 0
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.TxtNextTime.text = XUiHelper.GetText("DormQuestTerminalNextQuestRefreshTime", timeText)
end

function XUiDormTerminalSystem:NextStopTimer()
    if self.NextTimer then
        XScheduleManager.UnSchedule(self.NextTimer)
        self.NextTimer = nil
    end
end

--endregion

return XUiDormTerminalSystem