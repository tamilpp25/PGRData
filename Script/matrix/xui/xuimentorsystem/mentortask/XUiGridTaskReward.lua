local XUiGridTaskReward = XClass(nil, "XUiGridTaskReward")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridTaskReward:Ctor(ui,root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self.AccomplishRewardGridList = {}
    self.UndoneRewardGridList = {}
    self:SetButtonCallBack()
end

function XUiGridTaskReward:SetButtonCallBack()
    self.PanelUndone:GetObject("BtnStand").CallBack = function()
        self:OnBtnStandClick()
    end
    self.PanelAccomplish:GetObject("BtnStand").CallBack = function()
        self:OnBtnStandClick()
    end
end

function XUiGridTaskReward:OnBtnStandClick()
    if not self.Data or not self.Student then
       return 
    end

    if self:IsCanGive() then
        if self:IsGiven() then return end
        
        local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
        local gift = mentorData:GetTeacherGift()
        if gift.Count <= 0 then
            XUiManager.TipText("MentorTeacherGiftEmptyHint")
            return
        end
        XDataCenter.MentorSystemManager.MentorGiveRewardRequest(self.Student.PlayerId, self.Data.TaskId, function()
                XUiManager.TipText("MentorTeacherGiftCompletHint")
                self:UpdateGrid(self.Data,self.Student)
            end)
    else
        if not self:IsCanGet() then return end
        XDataCenter.MentorSystemManager.MentorGetWeeklyTaskRewardRequest(self.Student.PlayerId, self.Data.TaskId, function (rewardGoodsList)
                XUiManager.OpenUiObtain(rewardGoodsList)
        end)
    end
end

function XUiGridTaskReward:UpdateGrid(data,student)
    self.Data = data
    self.Student = student
    if data then
        self.PanelUndone.gameObject:SetActiveEx(not self:IsCanGive())
        self.PanelAccomplish.gameObject:SetActiveEx(self:IsCanGive())
        if self:IsCanGive() then
            self:UpdatePanelAccomplish(data)
        else
            self:UpdatePanelUndone(data)
        end
    end
end

function XUiGridTaskReward:UpdatePanelAccomplish(data)
    local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data.TaskId)
    local grid = self.PanelAccomplish:GetObject("GridCommon")
    local parent = self.PanelAccomplish:GetObject("TaskGridList")
    local itemId = XMentorSystemConfigs.GetMentorSystemData("ActivationItemId")
    local rewards 
    if self:IsGiven() then
        rewards = {XRewardManager.CreateRewardGoods(itemId)}
    end
    
    self.PanelAccomplish:GetObject("TextName").text = taskCfg.Title
    self.PanelAccomplish:GetObject("TextHint").text = CSTextManagerGetText("MentorTeacherGiveItemHint")
    self.PanelAccomplish:GetObject("BtnStand"):SetDisable(self:IsGiven())
    
    self:ShowReward(rewards, self.AccomplishRewardGridList, grid, parent)
end

function XUiGridTaskReward:UpdatePanelUndone(data)
    local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data.TaskId)
    local rewardId = XMentorSystemConfigs.GetTeacherWeeklyTaskRewardById(data.TaskId).RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)
    local grid = self.PanelUndone:GetObject("GridCommon")
    local parent = self.PanelUndone:GetObject("TaskGridList")
    local curCount = self.PanelUndone:GetObject("CurCount")
    local maxCount = self.PanelUndone:GetObject("MaxCount")
    local schedule = self.PanelUndone:GetObject("Schedule")
    
    self.PanelUndone:GetObject("TextName").text = taskCfg.Title
    self.PanelUndone:GetObject("TextDesc").text = taskCfg.Desc
    self.PanelUndone:GetObject("BtnStand"):SetDisable(not self:IsCanGet())
    
    if #taskCfg.Condition < 2 then--显示进度
        schedule.gameObject:SetActiveEx(true)
        schedule.gameObject:SetActiveEx(true)
        local result = taskCfg.Result > 0 and taskCfg.Result or 1
        XTool.LoopMap(data.Schedule, function(_, pair)
                pair.Value = (pair.Value >= result) and result or pair.Value
                curCount.text = pair.Value
                maxCount.text = string.format("/%d",result)
            end)
    else
        schedule.gameObject:SetActiveEx(false)
    end
    
    self:ShowReward(rewards, self.UndoneRewardGridList, grid, parent)
end

function XUiGridTaskReward:ShowReward(rewards, rewardList, grid, parent)
    grid.gameObject:SetActiveEx(false)
    for i = 1, #rewardList do
        rewardList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = rewardList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(grid)
            ui.transform:SetParent(parent, false)
            ui.gameObject:SetActiveEx(true)
            panel = XUiGridCommon.New(self.Root, ui)
            table.insert(rewardList, panel)
        end
        panel:Refresh(rewards[i])
    end
end

function XUiGridTaskReward:IsCanGive()
    return self.Data.Status >= XMentorSystemConfigs.TaskStatus.GetReward
end

function XUiGridTaskReward:IsGiven()
    return self.Data.Status >= XMentorSystemConfigs.TaskStatus.GiveEquip
end

function XUiGridTaskReward:IsCanGet()
    return self.Data.Status == XMentorSystemConfigs.TaskStatus.Completed
end
---------------------------------------------------------------------------
return XUiGridTaskReward