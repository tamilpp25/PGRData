---@class XUiFuben2023YuanXiaoTaskGrid
local XUiFuben2023YuanXiaoTaskGrid = XClass(XDynamicGridTask, "XUiFuben2023YuanXiaoTaskGrid")

function XUiFuben2023YuanXiaoTaskGrid:AutoAddListener()
end

function XUiFuben2023YuanXiaoTaskGrid:ResetData(data)
    if not data then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    local isComplete = data.State == XDataCenter.TaskManager.TaskState.Finish
    self.ImgComplete.gameObject:SetActiveEx(isComplete)
    self.RawImage.gameObject:SetActiveEx(not isComplete)
    self.Text.gameObject:SetActiveEx(not isComplete)
    self.Data = data

    if self.PanelAnimationGroup then    -- 先显示
        self.PanelAnimationGroup.alpha = 1
    end

    if self.TaskReceive then --一键领取栏出现在首位 其他所有任务数据往后移一格
        if data.ReceiveAll then
            --隐藏其他界面
            local childCount = self.PanelAnimation.childCount
            for i = 0, childCount - 1 do
                self.PanelAnimation:GetChild(i).gameObject:SetActiveEx(false)
            end

            self.TaskReceive.gameObject:SetActive(true)
            self.ReceiveAllBtn = self.TaskReceive.transform:Find("BtnReceiveBlueLight"):GetComponent("XUiButton")
            self.ReceiveAllBtn.CallBack = function() self:OnBtnAllReceiveClick() end
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
    --self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
    --self.RootUi:SetUiSprite(self.RImgTaskType, config.Icon)
    if self.RImgTaskType then
        self.RImgTaskType:SetRawImage(config.Icon)
    end
    self:UpdateProgress(self.Data)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    if not rewards then
        return
    end
    local count = rewards[1] and rewards[1].Count
    self.Text.text = count
end

function XUiFuben2023YuanXiaoTaskGrid:IsHasButton()
    return false
end

return XUiFuben2023YuanXiaoTaskGrid