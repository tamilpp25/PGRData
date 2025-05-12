---@class XUiGridVersionGiftTask
local XUiGridVersionGiftTask = XClass(XUiNode, "XUiGridVersionGiftTask")

--region 生命周期

---@param rootUi XLuaUi
function XUiGridVersionGiftTask:OnStart(rootUi, beforeFinishCheckEvent, afterFinishCb)
    self.RootUi = rootUi
    self.RewardPanelList = {}
    self:InitAutoScript()
    self.ImgComplete.gameObject:SetActive(false)
    self.BeforeFinishCheckEvent = beforeFinishCheckEvent
    self.AfterFinishCb = afterFinishCb
end

--endregion

--region 初始化
function XUiGridVersionGiftTask:InitAutoScript()
    self:AutoAddListener()
end

function XUiGridVersionGiftTask:AutoAddListener()
    self.BtnCollect.CallBack = handler(self, self.OnBtnFinishClick)

    self.BtnSkip.CallBack = handler(self, self.OnBtnSkipClick)

    if self.BtnReceiveBlueLight then
        self.BtnReceiveBlueLight.CallBack = handler(self, self.OnBtnAllReceiveClick)
    end
end
--endregion

--region 界面刷新

function XUiGridVersionGiftTask:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data

    self.TaskRoot.gameObject:SetActiveEx(not self.Data.ReceiveAll)
    self.TaskReceive.gameObject:SetActiveEx(self.Data.ReceiveAll or false)
    
    if self.Data.ReceiveAll then
        self:RefreshRecieveAllShow()
    else
        self:RefreshTaskDataShow()
    end
end

function XUiGridVersionGiftTask:RefreshRecieveAllShow()
    
end

function XUiGridVersionGiftTask:RefreshTaskDataShow()
    if self.TaskReceive then
        self.TaskReceive.gameObject:SetActive(false)
    end
    self.ImgComplete.gameObject:SetActive(self.Data.State == XDataCenter.TaskManager.TaskState.Finish)

    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    if self.TxtTitle then
        self.TxtTitle.text = config.Title
    end
    self.TxtTaskDescribe.text = config.Desc
    if self.TxtSubTypeTip then
        self.TxtSubTypeTip.text = config.Suffix or ""
    end

    if self.RImgTaskType then
        self.RImgTaskType:SetRawImage(config.Icon)
    end
    self:UpdateProgress(self.Data)
end

function XUiGridVersionGiftTask:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            if self.TxtTaskNumQian then
                self.TxtTaskNumQian.text = pair.Value .. "/" .. result
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtTaskNumQian then
            self.TxtTaskNumQian.gameObject:SetActive(false)
        end
    end

    if not self:IsHasButton() then
        return
    end
    self.BtnCollect.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    if self.BtnReceiveHave then
        self.BtnReceiveHave.gameObject:SetActive(false)
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnCollect.gameObject:SetActive(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActive(true)

        if self.BtnSkip["SetButtonState"] then
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            if skipId == nil or skipId == 0 then
                self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
            else
                self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
            end
        end
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish then
        if self.BtnReceiveHave then
            self.BtnReceiveHave.gameObject:SetActive(true)
        end
    end
end

--endregion

--region 事件回调
function XUiGridVersionGiftTask:OnBtnFinishClick()
    if self.BeforeFinishCheckEvent then
        if not self.BeforeFinishCheckEvent(self.tableData) then
            return
        end
    end
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.tableData.RewardId)
    if not XTool.IsTableEmpty(rewards) then
        for i = 1, #rewards do
            local rewardsId = self.RewardPanelList[i].TemplateId
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
    end
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        if not XTool.IsTableEmpty(rewards) then
            for i = 1, #rewards do
                if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                    return
                end
            end
        end

        if self.AfterFinishCb then
            self.AfterFinishCb()
        end

        if not XTool.IsTableEmpty(rewardGoodsList) then
            self:OpenUiObtain(rewardGoodsList, nil, function()
                self.Parent:CheckAndRefreshFreeItemCanGet()
            end)
        end
    end)
end

function XUiGridVersionGiftTask:OnBtnSkipClick()
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.RunMain()
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            XFunctionManager.SkipInterface(skipId)
        end)
    else
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiGridVersionGiftTask:OnBtnAllReceiveClick()
    local weaponCount = 0
    local chipCount = 0

    for key, taskId in pairs(self.Data.AllAchieveTaskDatas) do --装备上限判断
        local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(taskId)

        if XTool.IsNumberValid(taskCfg.RewardId) then
            local rewards = XRewardManager.GetRewardList(taskCfg.RewardId)

            if not XTool.IsTableEmpty(rewards) then
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
                end
            end
        end
    end

    --批量领取任务奖励
    if self.Data.ReceiveCb then
        self.Data.ReceiveCb()
    else
        local taskIds = self.Data.AllAchieveTaskDatas
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)

            if self.AfterFinishCb then
                self.AfterFinishCb()
            end
            
            local horizontalNormalizedPosition = 0
            if not XTool.IsTableEmpty(rewardGoodsList) then
                self:OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
            end
        end)
    end
end
--endregion

function XUiGridVersionGiftTask:OpenUiObtain(...)
    XUiManager.OpenUiObtain(...)
end

function XUiGridVersionGiftTask:IsHasButton()
    return true
end

function XUiGridVersionGiftTask:SetTaskLock(isLock, lockTxt)
    if not self.TxtLock then
        return
    end
    if isLock then
        if self.BtnFinish.gameObject.activeSelf then
            self.BtnFinish.gameObject:SetActiveEx(false)
        end
        if self.BtnSkip.gameObject.activeSelf then
            self.BtnSkip.gameObject:SetActiveEx(false)
        end
        self.TxtLock.gameObject:SetActiveEx(true)
        self.TxtLock.text = lockTxt
    else
        self.TxtLock.gameObject:SetActiveEx(false)
    end
end

return XUiGridVersionGiftTask