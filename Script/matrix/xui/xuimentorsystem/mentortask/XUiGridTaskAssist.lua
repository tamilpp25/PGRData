local XUiGridTaskAssist = XClass(nil, "XUiGridTaskAssist")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridTaskAssist:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    XTool.InitUiObject(self)
    self.RewardPanelList = {}
    self:SetButtonCallBack()
end

function XUiGridTaskAssist:SetButtonCallBack()
    self.BtnStand.CallBack = function()
        self:OnBtnStandClick()
    end
end

function XUiGridTaskAssist:OnBtnStandClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local maxCount = XMentorSystemConfigs.GetMentorSystemData("ChangeTaskCount")
    local curCount = maxCount - mentorData:GetDailyChangeTaskCount()
    if curCount <= 0 then
        XUiManager.TipText("MentorCantChangeTaskHint")
        return
    end
    XDataCenter.MentorSystemManager.MentorGetChangeDailyTaskRequest(self.Student.PlayerId, function ()
            XLuaUiManager.Open("UiMentorSelectTask", true, self.Data.TaskId, self.Student)
    end)
end

function XUiGridTaskAssist:UpdateGrid(data,student)
    self.Data = data
    self.Student = student
    if data then
        local IsInit = data.Status == XMentorSystemConfigs.TaskStatus.Init
        local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data.TaskId)
        local rewardId = XMentorSystemConfigs.GetTeacherWeeklyTaskRewardById(data.TaskId).RewardId
        local rewards = XRewardManager.GetRewardList(rewardId)
        
        self:ShowReward(rewards)
        self.TextName.text = taskCfg.Title
        self.TextDesc.text = taskCfg.Desc
        
        self.BtnStand.gameObject:SetActiveEx(IsInit and not data.HasChange)
        self.BtnChanged.gameObject:SetActiveEx(IsInit and data.HasChange)
        self.BtnReceived.gameObject:SetActiveEx(not IsInit)
    end
end

function XUiGridTaskAssist:ShowReward(rewards)
    
    self.GridCommon.gameObject:SetActiveEx(false)
    
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.transform:SetParent(self.Content, false)
            ui.gameObject:SetActiveEx(true)
            panel = XUiGridCommon.New(self.Root, ui)
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
    end
end


return XUiGridTaskAssist