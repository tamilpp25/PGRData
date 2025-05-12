-- XGridAchievementTask 肉鸽玩法2.1 成就任务
-- ================================================================================
local XGridAchievementTask = XClass(nil, "XGridAchievementTask")

function XGridAchievementTask:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "GridPartner/Effect")
    if self.Effect then self.Effect.gameObject:SetActiveEx(false) end
    self.Reddot = XUiHelper.TryGetComponent(self.Transform, "GridPartner/Red")
    if self.Reddot then self.Reddot.gameObject:SetActiveEx(false) end

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnFinishClick)
end

function XGridAchievementTask:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)

    self.Data = data
    self.TaskConfig = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self.TxtName.text = self.TaskConfig.Title
    self.TxtDesc.text = self.TaskConfig.Desc
    -- 状态
    self.ImgSelect.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    end
    if self.Reddot then
        self.Reddot.gameObject:SetActiveEx(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    end
    -- 进度
    if #self.TaskConfig.Condition < 2 then
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        -- self.TxtTaskNumQian.gameObject:SetActive(true)
        local result = self.TaskConfig.Result > 0 and self.TaskConfig.Result or 1
        XTool.LoopMap(data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
    end
end

function XGridAchievementTask:OnBtnFinishClick()
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        return
    end
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)

    if XTool.IsTableEmpty(rewards) then
        goto continue
    end
    for i = 1, #rewards do
        local rewardsId = rewards[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
    chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    ::continue::
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        if XTool.IsTableEmpty(rewardGoodsList) then
            return
        end
        XLuaUiManager.Open("UiBiancaTheatreTipReward", function ()
            self.RootUi:CheckAutoGetReward()
        end, rewardGoodsList, nil)
    end)
end



-- XPanelAchievementReward 肉鸽玩法2.1 成就奖励
-- ================================================================================
local XPanelAchievementReward = XClass(nil, "XPanelAchievementReward")

function XPanelAchievementReward:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    
    self.UpdateEffect = self.TxtName2.transform:Find("Effect")
    if self.UpdateEffect then
        self.UpdateEffect.gameObject:SetActiveEx(false)
    end
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, self.OnClickRewardDetail)
end

function XPanelAchievementReward:Refresh(taskCount, finishCount, curNeedCountLevel, isLast, cb)
    local haveReward = taskCount - finishCount >= 0
    local showCount = haveReward and (taskCount - finishCount) or 0
    local baseTaskCount = (finishCount < taskCount and curNeedCountLevel > 1 and XDataCenter.BiancaTheatreManager.GetAchievementNeedCounts(curNeedCountLevel - 1)) or 0
    local refreshAnimCb = function ()
        self.ShowCount = showCount
        self.FinishCount = finishCount
        self.TaskCount = taskCount
        self.RewardId = XDataCenter.BiancaTheatreManager.GetAchievementRewardIds(curNeedCountLevel)
        self.TxtName2.text = self.ShowCount
        self.ImgProgress2.fillAmount = (self.FinishCount - baseTaskCount) / (self.TaskCount - baseTaskCount)
        local rewardItems = XRewardManager.GetRewardList(self.RewardId)
        local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
        self.RImgIcon:SetRawImage(XEntityHelper.GetItemIcon(rewardGoodsList[1].TemplateId))
        if self.FinishCount >= self.TaskCount and isLast then
            local descConfig = XBiancaTheatreConfigs.GetTheatreClientConfig("AchievementRewardAllGet")
            self.TxtName2.text = descConfig and descConfig.Values[1]
            self.TxtName.gameObject:SetActiveEx(false)
        end
        if cb then cb() end
    end
    if self.ShowCount and self.ShowCount ~= showCount and haveReward then
        self:RefreshUpdateEffect(refreshAnimCb, (finishCount - baseTaskCount) / (taskCount - baseTaskCount))
    else
        refreshAnimCb()
    end
end

function XPanelAchievementReward:OnClickRewardDetail()
    self.RootUi:OpenRewardDetail()
end

function XPanelAchievementReward:RefreshUpdateEffect(cb, fillAmount)
    local oldFillAmount = self.ImgProgress2.fillAmount
    local changeFillAmount = fillAmount - oldFillAmount
    XUiHelper.Tween(0.5, function(f)
        -- 防止动画还没结束就关闭界面导致计时器报错
        if XTool.UObjIsNil(self.Transform) then return end
        self.ImgProgress2.fillAmount = oldFillAmount + changeFillAmount * f
    end, function()
        if self.UpdateEffect then
            self.UpdateEffect.gameObject:SetActiveEx(false)
            self.UpdateEffect.gameObject:SetActiveEx(self.FinishCount < self.TaskCount)
            if cb then cb() end
        end
    end)
end



-- XUiBiancaTheatreAchievement 肉鸽玩法2.1 成就系统界面
-- ================================================================================
local XUiBiancaTheatreAchievement = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreAchievement")
local PerPageTackCount = 6

function XUiBiancaTheatreAchievement:OnAwake()
    self.ScrollRect = self.PanelAchievementTable:GetComponent("ScrollRect")
    self.PanelReward = XPanelAchievementReward.New(self.PanelDetail, self)

    self:InitCurPageIndex()
    self:AddClickListener()
end

function XUiBiancaTheatreAchievement:OnStart(closeCb)
    self.CloseCb = closeCb
    self.TaskManager = XDataCenter.BiancaTheatreManager.GetTaskManager()
    self:InitTabBtns()
end

function XUiBiancaTheatreAchievement:OnEnable()
    if self.SelectIndex then
        self.PanelTab:SelectIndex(self.SelectIndex)
    end
    self.ScrollRect.vertical = false
end


-- 界面刷新相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreAchievement:Refresh()
    self:RefreshTab()
    self:RefreshPage()
    self:RefreshReward()
    self:RefreshRedPoint()

    self:CheckAutoGetReward()
end

function XUiBiancaTheatreAchievement:RefreshTab()
    local allTaskCount = self.TaskManager:GetAllAchievementTabTaskCount()
    local allFinishCount = self.TaskManager:GetAllAchievementTabFinishCount()
    for index, btn in ipairs(self.TabBtns) do
        local process = 0
        local taskCount = self.TaskManager:GetAchievementTabTaskCount(index)
        local finishCount = self.TaskManager:GetAchievementTabFinishCount(index)
        if XTool.IsNumberValid(taskCount) then
            process = math.ceil(finishCount / taskCount * 100)
        end
        btn:SetNameByGroup(1, process .. "%")
    end
    self.TxtQuantity.text = string.format(XBiancaTheatreConfigs.GetClientConfig("AchievementAllPrecoss"), allFinishCount, allTaskCount)
end

function XUiBiancaTheatreAchievement:RefreshPage()
    self.TxtTurnPages.text = self:GetCurPageIndex(self.SelectIndex) .. " / " .. self:GetPageCount(self.SelectIndex)
    self.BtnRightArrow:SetDisable(self:GetCurPageIndex(self.SelectIndex) == self.PageData[self.SelectIndex])
    self.BtnLeftArrow:SetDisable(self:GetCurPageIndex(self.SelectIndex) == 1)
end

function XUiBiancaTheatreAchievement:RefreshReward(cb)
    local curNeedCountLevel, finishCount, needCount, isLast = self:GetCurRewardData()
    self.PanelReward:Refresh(needCount, finishCount, curNeedCountLevel, isLast, cb)
end

function XUiBiancaTheatreAchievement:RefreshRedPoint()
    for index, btn in ipairs(self.TabBtns) do
        if btn then
            btn:ShowReddot(self.TaskManager:GetAchievementTabIsAchieved(index))
        end
    end
end

function XUiBiancaTheatreAchievement:UpdatePage(oldCurIndex)
    if oldCurIndex ~= self:GetCurPageIndex(self.SelectIndex) then
        self:UpdateTaskItemList()
        self:RefreshRedPoint()
        self:PlayAnimation("QieHuan")
        self:RefreshPage()
    end
end

--------------------------------------------------------------------------------

-- 页签相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreAchievement:InitTabBtns()
    self.TabBtns = {}
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    for index, id in ipairs(achievementIdList) do
        local tabBtn = self["BtnTab0" .. index]
        tabBtn:SetNameByGroup(0, XBiancaTheatreConfigs.GetAchievementTagName(id))
        tabBtn.gameObject:SetActiveEx(true)
        table.insert(self.TabBtns, tabBtn)
    end

    self.PanelTab:Init(self.TabBtns, function(index) self:OnSelectedTab(index) end)
    self.SelectIndex = 1
end

function XUiBiancaTheatreAchievement:OnSelectedTab(index)
    self.SelectIndex = index
    self:PlayAnimation("QieHuan2")

    self:UpdateAchievementData()
    self:UpdateTaskItemList()
    self:Refresh()
end

--------------------------------------------------------------------------------

-- 成就任务列表相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreAchievement:DataToPage()
    self.TaskDataList = self.AchievementTaskListDir[self.SelectIndex]
    -- 数据分页
    self.ShowDataList = {}
    local curPageIndex = self:GetCurPageIndex(self.SelectIndex)
    local startIndex = math.max((curPageIndex - 1) * PerPageTackCount + 1, 1)
    local endIndex = math.min((curPageIndex - 1) * PerPageTackCount + PerPageTackCount, #self.TaskDataList)
    for i = startIndex, endIndex, 1 do
        table.insert(self.ShowDataList, self.TaskDataList[i])
    end
end

function XUiBiancaTheatreAchievement:UpdateTaskItemList()
    if XTool.IsTableEmpty(self.AchievementTaskListDir) then
        return
    end
    self:DataToPage()

    if not self.TaskItemList then
        self.TaskItemList = {}
    end

    for index, taskData in ipairs(self.ShowDataList) do
        if not self.TaskItemList[index] then
            local taskItem = XGridAchievementTask.New(XUiHelper.Instantiate(self.PanelBagItem, self["Item" .. index]), self)
            self.TaskItemList[index] = taskItem
        end
        self["Item" .. index].gameObject:SetActiveEx(true)
        self.TaskItemList[index]:ResetData(taskData)
    end
    -- 隐藏多余
    for i = #self.ShowDataList + 1, #self.TaskItemList, 1 do
        self.TaskItemList[i]:ResetData(nil)
    end
    self.PanelBagItem.gameObject:SetActiveEx(false)
end

--------------------------------------------------------------------------------

-- 成就任务数据相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreAchievement:UpdateAchievementData()
    self.AchievementTaskListDir = self.TaskManager:GetAchievementTaskListDir()
    self:UpdatePageData()
end

function XUiBiancaTheatreAchievement:InitCurPageIndex()
    self.CurPageIndex = {}
    if XTool.IsTableEmpty(XBiancaTheatreConfigs.GetAchievementIdList()) then
        return
    end
    for index, _ in ipairs(XBiancaTheatreConfigs.GetAchievementIdList()) do
        self.CurPageIndex[index] = 1
    end
end

function XUiBiancaTheatreAchievement:UpdatePageData()
    self.PageData = {}
    if XTool.IsTableEmpty(XBiancaTheatreConfigs.GetAchievementIdList()) then
        return
    end
    for index, _ in ipairs(XBiancaTheatreConfigs.GetAchievementIdList()) do
        self.PageData[index] = math.max(math.ceil(self.TaskManager:GetAchievementTabTaskCount(index) / PerPageTackCount), 1)
    end
end

function XUiBiancaTheatreAchievement:GetCurPageIndex(index)
    self.CurPageIndex[index] = math.min(self.CurPageIndex[index], self.PageData[index])
    self.CurPageIndex[index] = math.max(self.CurPageIndex[index], 1)
    return self.CurPageIndex[index]
end

function XUiBiancaTheatreAchievement:GetPageCount(index)
    return self.PageData[index]
end

-- 当前成就等级数据
-- curNeedCountLevel:当前选中成就页签的奖励等级
-- finishCount:当前奖励等级任务已完成数量
-- needCounts[curNeedCountLevel]:当前奖励任务数量需求
function XUiBiancaTheatreAchievement:GetCurRewardData()
    local curNeedCountLevel = 1
    local needCounts = XDataCenter.BiancaTheatreManager.GetAchievementNeedCounts()
    local finishCount = self.TaskManager:GetAllAchievementTabFinishCount()
    for index, value in ipairs(needCounts) do
        if finishCount <= value then
            curNeedCountLevel = index
            break
        end
    end
    if XDataCenter.BiancaTheatreManager.CheckAchievementRecordIsGet(curNeedCountLevel) then
        curNeedCountLevel = curNeedCountLevel + 1
    end
    if curNeedCountLevel > #needCounts or finishCount > needCounts[#needCounts] then
        curNeedCountLevel = #needCounts
    end
    return curNeedCountLevel, finishCount, needCounts[curNeedCountLevel], curNeedCountLevel == #needCounts
end

function XUiBiancaTheatreAchievement:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        -- 辅助机升级弹窗借来用用
        XLuaUiManager.Open("UiPartnerPopupTip", XBiancaTheatreConfigs.GetAchievementFinishTipTxt())
        self:UpdateAchievementData()
        self:UpdateTaskItemList()
        self:RefreshTab()
        self:RefreshPage()
        self:RefreshRedPoint()

        if self:CheckGetAchievementReward() then
            self:RefreshReward()
            self:CheckAutoGetReward()
        else
            self:RefreshReward(function ()
                self:PlayAnimation("AnimEnable")
            end)
        end
    end
end

function XUiBiancaTheatreAchievement:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

--------------------------------------------------------------------------------

-- 自动领奖相关
--------------------------------------------------------------------------------

---自动领取成就奖励
function XUiBiancaTheatreAchievement:CheckAutoGetReward()
    local curNeedCountLevel, finishCount, needCount = self:GetCurRewardData()
    if finishCount < needCount or XDataCenter.BiancaTheatreManager.CheckAchievementRecordIsGet(curNeedCountLevel) then
        return
    end
    XDataCenter.BiancaTheatreManager.RequestAchievementReward(curNeedCountLevel, function ()
        self:RefreshReward()
        self:PlayAnimationWithMask("AnimEnable", function ()
            self:Refresh()
        end)
    end)
end

---返回是否可获得累计成就任务
---@return boolean
function XUiBiancaTheatreAchievement:CheckGetAchievementReward()
    local curNeedCountLevel, finishCount, needCount = self:GetCurRewardData()
    return not (finishCount < needCount or XDataCenter.BiancaTheatreManager.CheckAchievementRecordIsGet(curNeedCountLevel))
end

function XUiBiancaTheatreAchievement:OpenRewardDetail()
    local curNeedCountLevel, _, _, _ = self:GetCurRewardData()
    local rewardId = XDataCenter.BiancaTheatreManager.GetAchievementRewardIds(curNeedCountLevel)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    XLuaUiManager.Open("UiBiancaTheatreTips", rewardList[1].TemplateId)
end

function XUiBiancaTheatreAchievement:OpenAllReward()
    local achievementIdList = XBiancaTheatreConfigs.GetAchievementIdList()
    local achievementId = achievementIdList[self.SelectIndex]
    if not achievementId then
        return
    end
    XLuaUiManager.Open("UiBiancaTheatrePreviewTips", achievementId)
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreAchievement:AddClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLeftArrow, self.OnClickLeftArrow)
    XUiHelper.RegisterClickEvent(self, self.BtnRightArrow, self.OnClickRightArrow)
    XUiHelper.RegisterClickEvent(self, self.BtnExclamatory, self.OpenAllReward)
end

function XUiBiancaTheatreAchievement:OnClickLeftArrow()
    if XTool.IsNumberValid(self.CurPageIndex[self.SelectIndex]) then
        local oldCurIndex = self:GetCurPageIndex(self.SelectIndex)
        self.CurPageIndex[self.SelectIndex] = self.CurPageIndex[self.SelectIndex] - 1
        if self.CurPageIndex[self.SelectIndex] < 1 then
            XUiManager.TipErrorWithKey("BiancaTheatreAchievementLeft")
        end
        self:UpdatePage(oldCurIndex)
    end
end

function XUiBiancaTheatreAchievement:OnClickRightArrow()
    if XTool.IsNumberValid(self.CurPageIndex[self.SelectIndex]) then
        local oldCurIndex = self:GetCurPageIndex(self.SelectIndex)
        self.CurPageIndex[self.SelectIndex] = self.CurPageIndex[self.SelectIndex] + 1
        if self.CurPageIndex[self.SelectIndex] > self.PageData[self.SelectIndex] then
            XUiManager.TipErrorWithKey("BiancaTheatreAchievementRight")
        end
        self:UpdatePage(oldCurIndex)
    end
end

function XUiBiancaTheatreAchievement:OnCloseClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

--------------------------------------------------------------------------------