local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridFashionStoryTask=XClass(nil,"XUiGridFashionStoryTask")

local ButtonState={
    Normal=CS.UiButtonState.Normal,
    Disable=CS.UiButtonState.Disable
}

--region 初始化
function XUiGridFashionStoryTask:Ctor(ui,rootUi,beforeFinishCheckEvent, clickFunc)
    XTool.InitUiObjectByUi(self,ui)
    self.RootUi = rootUi
    self.RewardPanelList = {}
    self.GridCommon.gameObject:SetActive(false)
    self.ImgComplete.gameObject:SetActive(false)
    self.PanelAnimation.gameObject:SetActive(true)
    self.BeforeFinishCheckEvent = beforeFinishCheckEvent
    self.ClickFunc = clickFunc  --重写点击道具方法
    self.SpecialSoundMap = {}
    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
    self.BtnSkip.CallBack = function() self:OnBtnSkipClick() end
    self.BtnSkip:SetButtonState(ButtonState.Disable)
end

--endregion

--region 数据更新
function XUiGridFashionStoryTask:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.Data = data

    if self.PanelAnimationGroup then    -- 先显示
        self.PanelAnimationGroup.alpha = 1
    end
    
    --未完成时是否支持跳转
    local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
    if skipId then
        self.BtnSkip:SetButtonState(ButtonState.Normal)
    else
        self.BtnSkip:SetButtonState(ButtonState.Disable)
    end

    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
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

            if self.ClickFunc then
                XUiHelper.RegisterClickEvent(panel, panel.BtnClick, function()
                    self.ClickFunc(reward)
                end)
            end

            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(reward)

    end
end

function XUiGridFashionStoryTask:UpdateProgress(data)
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
    
    self.BtnFinish.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    self.ImgComplete.gameObject:SetActive(false)
    if self.BtnReceiveHave then
        self.BtnReceiveHave.gameObject:SetActive(false)
    end
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActive(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActive(true)
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish then
        self.ImgComplete.gameObject:SetActive(true)
    end
end
--endregion

--region 事件处理
function XUiGridFashionStoryTask:OnBtnFinishClick()
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
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        for i = 1, #rewards do
            if rewards[i].RewardType == XRewardManager.XRewardType.Nameplate then
                return
            end
        end
        self:OpenUiObtain(rewardGoodsList,nil,function() self.RootUi:RefreshTasks() end)
    end)
end

function XUiGridFashionStoryTask:OnBtnSkipClick()
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

function XUiGridFashionStoryTask:OpenUiObtain(...)
    XUiManager.OpenUiObtain(...)
end

function XUiGridFashionStoryTask:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskTimeline:PlayTimelineAnimation()
end

--endregion

return XUiGridFashionStoryTask