local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiDlcHuntTaskGridItem = require("XUi/XUiDlcHunt/Task/XUiDlcHuntTaskGridItem")

---@class XUiDlcHuntTaskGrid:XDynamicGridTask
local XUiDlcHuntTaskGrid = XClass(XDynamicGridTask, "XUiDlcHuntTaskGrid")

function XUiDlcHuntTaskGrid:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    --self.GridTaskTimeline:PlayTimelineAnimation()
end

function XUiDlcHuntTaskGrid:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.ImgComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.Data = data

    if self.PanelAnimationGroup then
        -- 先显示
        self.PanelAnimationGroup.alpha = 1
    end

    if self.TaskReceive then
        --一键领取栏出现在首位 其他所有任务数据往后移一格
        if data.ReceiveAll then
            --隐藏其他界面
            local childCount = self.PanelAnimation.childCount
            for i = 0, childCount - 1 do
                self.PanelAnimation:GetChild(i).gameObject:SetActiveEx(false)
            end

            self.TaskReceive.gameObject:SetActive(true)
            self.ReceiveAllBtn = self.TaskReceive.transform:Find("BtnReceiveBlueLight"):GetComponent("XUiButton")
            self.ReceiveAllBtn.CallBack = function()
                self:OnBtnAllReceiveClick()
            end
            return
        else
            --隐藏一键领取
            local childCount = self.PanelAnimation.childCount
            for i = 0, childCount - 1 do
                self.PanelAnimation:GetChild(i).gameObject:SetActiveEx(true)
            end
            if self.PanelTime then
                self.PanelTime.gameObject:SetActiveEx(false)
            end

            self.TaskReceive.gameObject:SetActive(false)
        end
    end

    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    self.TxtSubTypeTip.text = config.Suffix or ""
    --self.RootUi:SetUiSprite(self.RImgTaskType, config.Icon)
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
                panel = XUiDlcHuntTaskGridItem.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiDlcHuntTaskGridItem.New(self.RootUi, ui)
            end

            if self.ClickFunc then
                XUiHelper.RegisterClickEvent(panel, panel.BtnClick, function()
                    self.ClickFunc(reward)
                end)
            end

            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(reward)
        local amount = reward.Count
        local textComponent = XUiHelper.TryGetComponent(panel.Transform, "Txt", "Text")
        if textComponent then
            textComponent.text = "X" .. amount
        end
        panel.TxtName.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntTaskGrid:OpenUiObtain(...)
    XDataCenter.DlcHuntManager.OpenUiObtain(...)
end

return XUiDlcHuntTaskGrid