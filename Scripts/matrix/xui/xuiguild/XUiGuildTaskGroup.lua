--region   ------------------任务格子 start-------------------

local XUiGuildTaskGrid = XClass(nil, "XUiGuildTaskGrid")

function XUiGuildTaskGrid:Ctor(ui, refreshTaskList)
    XTool.InitUiObjectByUi(self, ui)
    self.RewardGrids = {}
    self.RefreshTaskList = refreshTaskList
    self:InitCb()
end

function XUiGuildTaskGrid:Init(parent)
    self.Parent = parent
    self.RewardParent = self.GridCommon.transform.parent
end

function XUiGuildTaskGrid:InitCb()
    self.BtnSkip.CallBack = function() 
        self:OnBtnSkipClick()
    end
    
    self.BtnFinish.CallBack = function() 
        self:OnBtnFinishClick()
    end
    
    self.BtnReceiveBlueLight.CallBack = function() 
        self:OnBtnReceiveAllClick()
    end
end

function XUiGuildTaskGrid:OnBtnSkipClick()
    if not self.Data then
        return
    end
    
    XFunctionManager.SkipInterface(self.Data.SkipId)
end

function XUiGuildTaskGrid:OnBtnFinishClick()
    if not self.Data or self.Data.State ~= GuildBossRewardType.Available then
        return
    end
    if self.Data.TaskType == GuildTaskType.BossHp then
        XDataCenter.GuildBossManager.GuildBossHpBoxRequest(self.Data.TaskId, function()
            if self.RefreshTaskList then self.RefreshTaskList() end
        end)
    elseif self.Data.TaskType == GuildTaskType.BossScore then   
        XDataCenter.GuildBossManager.GuildBossScoreBoxRequest(self.Data.TaskId, function()
            if self.RefreshTaskList then self.RefreshTaskList() end
        end)
    end
end

function XUiGuildTaskGrid:OnBtnReceiveAllClick()
    XDataCenter.GuildBossManager.GuildBossGetAllBossRewardRequest(function()
        if self.RefreshTaskList then self.RefreshTaskList() end
    end)
end

function XUiGuildTaskGrid:Refresh(data)
    self.Data = data or self.Data
    if data.ReceiveAll then
        self:RefreshPanelAnimation(false)
    else
        self:RefreshPanelAnimation(true)
        self:RefreshNormal()
    end
end

function XUiGuildTaskGrid:RefreshReward()
    local rewardList = XRewardManager.GetRewardList(self.Data.RewardId)
    for i, reward in ipairs(rewardList or {}) do
        local grid = self.RewardGrids[i]
        if not grid then
            local ui = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.RewardParent)
            grid = XUiGridCommon.New(self.Parent, ui)
            self.RewardGrids[i] = grid
        end
        grid:Refresh(reward)
    end
    
    for i, grid in ipairs(self.RewardGrids) do
        grid.GameObject:SetActiveEx(i <= #rewardList)
    end
end

function XUiGuildTaskGrid:RefreshNormal()
    self.TxtTaskName.text = self.Data.Title
    local curValue, maxValue, percent
    if self.Data.TaskType == GuildTaskType.BossHp then
        local amount = self.Data.Value <= self.Data.Target and 1 or 0
        percent = amount
        self.TxtTaskDescribe.text = string.format("%s %s%%", self.Data.Desc, self.Data.Target)
        self.TxtTaskNumQian.text = string.format("<size=40><color=#0f70bc>%s</color></size>/1", amount)
    else
        curValue, maxValue = math.min(self.Data.Value, self.Data.Target), self.Data.Target
        percent = XUiHelper.GetFillAmountValue(curValue, maxValue)
        self.TxtTaskNumQian.text = string.format("<size=40><color=#0f70bc>%s</color></size>/%s", curValue, maxValue)
        self.TxtTaskDescribe.text = self.Data.Desc
    end
    
    self.ImgProgress.fillAmount = math.min(1, percent)
    self:RefreshReward()
    self:RefreshButton()
end

function XUiGuildTaskGrid:RefreshPanelAnimation(show)
    local childCount = self.PanelAnimation.childCount
    for i = 0, childCount - 1 do
        local child = self.PanelAnimation:GetChild(i)
        if child then
            child.gameObject:SetActiveEx(show)
        end
    end
    self.TaskReceive.gameObject:SetActiveEx(not show)
end

function XUiGuildTaskGrid:RefreshButton()
    local state = self.Data.State
    self.ImgComplete.gameObject:SetActiveEx(state == GuildBossRewardType.Acquired)
    self.BtnSkip.gameObject:SetActiveEx(state == GuildBossRewardType.Disable)
    self.BtnFinish.gameObject:SetActiveEx(state == GuildBossRewardType.Available)
end

--endregion------------------任务格子 finish------------------

--region   ------------------工会活跃度 start-------------------

---@class XUiPanelGuildActivity 工会活跃度界面
local XUiPanelGuildActivity = XClass(nil, "XUiPanelGuildActivity")

--设计显示奖励个数
local DesignGridCount = 5

function XUiPanelGuildActivity:Ctor(ui, parentUi)
    XTool.InitUiObjectByUi(self, ui)
    self.ParentUi = parentUi
    self.ScrollRect = self.Transform:GetComponent("ScrollRect")
    self:InitCb()
    self:InitDynamicTable()
end

function XUiPanelGuildActivity:InitCb()
    self.ScrollRect.onValueChanged:AddListener(function(offset) 
        self:OnScroll(offset)
    end)
end

function XUiPanelGuildActivity:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(require("XUi/XUiGuild/XUiChildItem/XUiGridGuildBoxItem"), self.ParentUi)
    self.DynamicTable:SetDelegate(self)
    self.GridCourse.gameObject:SetActiveEx(false)

    local imp = self.DynamicTable:GetImpl()
    local gridWidth = self.GridCourse.transform.rect.width
    local width = imp.transform.rect.width - gridWidth
    local space = (width / DesignGridCount) - gridWidth
    imp.Padding.left = math.floor(space + gridWidth / 2)

    imp.Spacing = CS.UnityEngine.Vector2(space, imp.Spacing.y)
    
    self.OffsetX = self.PanelContent.anchoredPosition.x - self.DaylyActiveProgressBg.anchoredPosition.x
end

function XUiPanelGuildActivity:Show()
    local guildId = XDataCenter.GuildManager.GetGuildId()
    local asyncRequest = asynTask(XDataCenter.GuildManager.GetGuildDetails)
    RunAsyn(function()
        asyncRequest(guildId)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        self:Refresh()
        self.GameObject:SetActiveEx(true)
    end)
end

function XUiPanelGuildActivity:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelGuildActivity:Refresh()
    local maxContribute = 0
    local giftContribute = XDataCenter.GuildManager.GetGiftContribute()
    self.TxtDailyActive.text = giftContribute

    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    local giftConfigs = XGuildConfig.GetGuildGiftByGuildLevel(giftGuildLevel)
    for _, cfg in pairs(giftConfigs or {}) do
        maxContribute = math.max(maxContribute, cfg.GiftContribute)
    end
    
    self.DataList = giftConfigs
    self.MaxContribute = maxContribute
    self.CurContribute = giftContribute
    
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelGuildActivity:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshGift(self.DataList[idx], idx, self.MaxContribute)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self.DaylyActiveProgressBg:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, self.PanelContent.sizeDelta.x)
        self.ImgDaylyActiveProgress.fillAmount = XUiHelper.GetFillAmountValue(self.CurContribute, self.MaxContribute)
    end
end

function XUiPanelGuildActivity:OnScroll(offset)
    local contentX = self.PanelContent.anchoredPosition.x
    local offsetX = contentX - self.OffsetX
    offsetX = CS.UnityEngine.Mathf.Clamp(offsetX, contentX, 0)
    local pos = self.DaylyActiveProgressBg.anchoredPosition
    pos.x = offsetX
    self.DaylyActiveProgressBg.anchoredPosition = pos
end

--endregion------------------工会活跃度 finish------------------


local XUiGuildTaskGroup = XLuaUiManager.Register(XLuaUi, "UiGuildTaskGroup")


local DefaultSelectTabIndex = 1

function XUiGuildTaskGroup:OnAwake()
    self:InitView()
    self:InitCb()
end 

function XUiGuildTaskGroup:OnStart()
    self.CurGuildId = XDataCenter.GuildManager.GetGuildId()
    local joinGuild = XDataCenter.GuildManager.IsJoinGuild()
    
    self.GuildBossOpen = joinGuild and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.GuildBoss)

    self:RefreshGiftContribute()
end 

function XUiGuildTaskGroup:OnEnable()
    self:UpdateView()
end

function XUiGuildTaskGroup:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED, self.RefreshGuildActivity, self)
end

function XUiGuildTaskGroup:InitView()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList)
    self.DynamicTable:SetProxy(XUiGuildTaskGrid, handler(self, self.RefreshTask))
    self.DynamicTable:SetDelegate(self)
    
    self.GiftGrids = {}
    
    self.TxtEmptyTask = self.PanelNoneDailyTask.transform:Find("ImgEmpty/TxtNone"):GetComponent("Text")

    self.GridTask.gameObject:SetActiveEx(false)
    
    local tabBtn = {
        self.Tog1
    }
    
    self.TabPanelGroup:Init(tabBtn, function(index) 
        self:OnSelectTab(index)
    end)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, 
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self.PanelGuildActivity = XUiPanelGuildActivity.New(self.PanelGuildActivity, self)
end

function XUiGuildTaskGroup:InitCb()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED, self.RefreshGuildActivity, self)
end

function XUiGuildTaskGroup:RefreshGuildActivity()
    if not self.PanelGuildActivity then
        return
    end
    self.PanelGuildActivity:Refresh()
end

function XUiGuildTaskGroup:UpdateView()
    self.TabPanelGroup:SelectIndex(self.TabIndex or DefaultSelectTabIndex)
end 

function XUiGuildTaskGroup:RefreshTask()
    XLuaUiManager.SetMask(true)
    XDataCenter.GuildBossManager.ProcessTaskList(function(taskList)
        XLuaUiManager.SetMask(false)
        if XTool.IsTableEmpty(taskList) or not self.GuildBossOpen then
            self.PanelTaskDailyList.gameObject:SetActiveEx(false)
            self.PanelNoneDailyTask.gameObject:SetActiveEx(true)
            self.TxtEmptyTask.text = XTool.IsTableEmpty(taskList) 
                    and XUiHelper.GetText("GuildBossNotCurrentActivity") or XUiHelper.GetText("GuildBossNotOpen")
            return
        end
        
        local finalList = {{ReceiveAll = true}}
        local receiveAll = false
        for _, task in ipairs(taskList or {}) do
            if not receiveAll 
                    and task.State == GuildBossRewardType.Available then
                receiveAll = true
            end
            table.insert(finalList, task)
        end

        if not receiveAll then
            table.remove(finalList, 1)
        end
        --放内部，是可能存在协议未发，导致分数不对
        self.TxtDailyNumber.text = XDataCenter.GuildBossManager.GetMyTotalScore()

        self.TaskList = finalList
        self.DynamicTable:SetDataSource(self.TaskList)
        self.DynamicTable:ReloadDataASync()
        
        
    end)
end

function XUiGuildTaskGroup:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    self.TabIndex = index
    self:RefreshTask()
end

function XUiGuildTaskGroup:RefreshGiftContribute()
    if not self.PanelGuildActivity then
        return
    end
    self.PanelGuildActivity:Show()
end

function XUiGuildTaskGroup:ChecKickOut()
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self:Close()
        return true
    end
    return false
end

function XUiGuildTaskGroup:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskList[idx])
    end
end