local XUiGridGuildTaskItem = XClass(nil, "XUiGridGuildTaskItem")

function XUiGridGuildTaskItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.RewardList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiGridGuildTaskItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridGuildTaskItem:SetItemData(itemData)
    self.Data = itemData
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.TxtGrade.text = config.Desc

    self:UpdateProgress(self.Data)

    -- 领取状态
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.ImgCannotReceive.gameObject:SetActiveEx(false)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnReceive.gameObject:SetActiveEx(true)
    elseif self.Data.State == XDataCenter.TaskManager.TaskState.Finish or self.Data.State == XDataCenter.TaskManager.TaskState.Invalid then
        self.ImgAlreadyReceived.gameObject:SetActiveEx(true)
    else
        self.ImgCannotReceive.gameObject:SetActiveEx(true)
    end

    -- 奖励
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    for i = 1, #self.RewardList do
        self.RewardList[i]:Refresh()
    end

    for i = 1, #rewards do
        local panel = self.RewardList[i]
        if not panel then
            if #self.RewardList == 0 then
                panel = XUiGridCommon.New(self.UiRoot, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.PanelTreasureContent, false)
                panel = XUiGridCommon.New(self.UiRoot, ui)
            end
            table.insert(self.RewardList, panel)
        end

        panel:Refresh(rewards[i])
    end

end

function XUiGridGuildTaskItem:UpdateProgress(data)
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtGradeStarNums.text = string.format("<size=50><color=#0f70bc>%d</color></size>/%d", pair.Value, result)
            self.ImgGradeStarActive.gameObject:SetActiveEx(pair.Value >= result)
        end)
    else
        self.ImgGradeStarActive.gameObject:SetActiveEx(false)
        self.TxtGradeStarNums.text = ""
    end
end

return XUiGridGuildTaskItem