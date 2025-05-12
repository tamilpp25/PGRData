local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridGachaCanLiverTask
local XUiGridGachaCanLiverTask = XClass(XUiNode, "XUiGridGachaCanLiverTask")

--region 生命周期

---@param rootUi XLuaUi
function XUiGridGachaCanLiverTask:OnStart(rootUi, beforeFinishCheckEvent, clickFunc, afterFinishCb)
    self.RootUi = rootUi
    self.RewardPanelList = {}
    self:InitAutoScript()
    self.GridCommon.gameObject:SetActive(false)
    self.ImgComplete.gameObject:SetActive(false)
    self.PanelAnimation.gameObject:SetActive(true)
    self.BeforeFinishCheckEvent = beforeFinishCheckEvent
    self.ClickFunc = clickFunc  --重写点击道具方法
    self.AfterFinishCb = afterFinishCb
end

--endregion

--region 初始化
function XUiGridGachaCanLiverTask:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

--- 获取一些自定义组件
function XUiGridGachaCanLiverTask:AutoInitUi()
    self.PanelTime = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/PanelTime", nil)
    self.RImgTaskType = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/RImgTaskType", "RawImage")
    self.TxtSubTypeTip = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtSubTypeTip", "Text")
    self.TxtLock = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/TxtLock", "Text")
end

function XUiGridGachaCanLiverTask:AutoAddListener()
    local clickXUiBtn = self.BtnClick:GetComponent("XUiButton")
    if not clickXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
    else
        self.BtnClick = clickXUiBtn
        self.BtnClick.CallBack = function() self:OnBtnClickClick() end
    end

    local finishXUiBtn = self.BtnFinish:GetComponent("XUiButton")
    if not finishXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
    else
        self.BtnFinish = finishXUiBtn
        self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
    end

    local skipXUiBtn = self.BtnSkip:GetComponent("XUiButton")
    if not skipXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    else
        self.BtnSkip = skipXUiBtn
        self.BtnSkip.CallBack = function() self:OnBtnSkipClick() end
    end
end
--endregion

--region 界面刷新

function XUiGridGachaCanLiverTask:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data

    if self.TaskReceive then
        self.TaskReceive.gameObject:SetActive(false)
    end
    self.ImgComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    ---@type XTableTask
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)

    if self.RawImgTitleResident then
        self.RawImgTitleResident.gameObject:SetActiveEx(string.IsNilOrEmpty(config.EndTime) and config.Type ~= XDataCenter.TaskManager.TaskType.TimeLimit)
    end
    
    if self.RawImgTitleTimeLimit then
        self.RawImgTitleTimeLimit.gameObject:SetActiveEx(not string.IsNilOrEmpty(config.EndTime) or config.Type == XDataCenter.TaskManager.TaskType.TimeLimit)
    end



    self.tableData = config
    if self.TxtTaskTitle then
        self.TxtTaskTitle.text = config.Title
    end
    self.TxtTaskDescribe.text = config.Desc
    if self.TxtSubTypeTip then
        self.TxtSubTypeTip.text = config.Suffix or ""
    end
    
    if self.RImgTaskType then
        self.RImgTaskType:SetRawImage(config.Icon)
    end
    self:UpdateProgress(self.Data)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    -- reset reward panel
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        local reward = rewards[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end

            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(reward)

        if self.ClickFunc then
            XUiHelper.RegisterClickEvent(panel, panel.BtnClick, function()
                self.ClickFunc(reward)
            end)
        end
    end
end

function XUiGridGachaCanLiverTask:UpdateProgress(data)
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
    self.BtnFinish.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    if self.BtnReceiveHave then
        self.BtnReceiveHave.gameObject:SetActive(false)
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActive(true)
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

function XUiGridGachaCanLiverTask:OnBtnClickClick()

end

function XUiGridGachaCanLiverTask:OnBtnFinishClick()
    if self.BeforeFinishCheckEvent then
        if not self.BeforeFinishCheckEvent(self.tableData) then
            return
        end
    end
    local weaponCount = 0
    local chipCount = 0
    local rewards = XRewardManager.GetRewardList(self.tableData.RewardId)
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
    self._Control:SetLockTickout(true)
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        for i = 1, #rewards do
            if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                return
            end
        end

        if self.AfterFinishCb then
            self.AfterFinishCb()
        end
        self.Parent:CheckAndRefreshFreeItemCanGet(true)
        
        self:OpenUiObtain(rewardGoodsList, nil, function()
            self._Control:SetLockTickout(false)
            self.Parent:CheckAndRefreshFreeItemCanGet()
        end)
    end)
end

function XUiGridGachaCanLiverTask:OnBtnSkipClick()
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
--endregion

function XUiGridGachaCanLiverTask:OpenUiObtain(...)
    XUiManager.OpenUiObtain(...)
end

function XUiGridGachaCanLiverTask:IsHasButton()
    return true
end

function XUiGridGachaCanLiverTask:SetTaskLock(isLock, lockTxt)
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

return XUiGridGachaCanLiverTask