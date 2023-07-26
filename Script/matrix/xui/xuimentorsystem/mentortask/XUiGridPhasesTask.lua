local XUiGridPhasesTask = XClass(nil, "XUiGridPhasesTask")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridPhasesTask:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridPhasesTask:SetButtonCallBack()
    self.BtnActive.CallBack = function()
        self:OnBtnActiveClick()
    end
end


function XUiGridPhasesTask:OnBtnActiveClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local rewardData = XRewardManager.GetRewardList(self.Data.RewardId)
    local IsCanGet = mentorData:CheckStudentWeeklyRewardCanGetByCount(self.Data.Count)
    local IsGeted = mentorData:CheckStudentWeeklyRewardGetedByCount(self.Data.Count)
    if IsCanGet then
        if IsGeted then
            return
        end
        
        XDataCenter.MentorSystemManager.StudentGetTaskProgressRewardRequest(self.Data.Count, function (rewardGoodsList)
                self.Base:UpdatePanelPhasesTask()
                if rewardGoodsList then
                    XUiManager.OpenUiObtain(rewardGoodsList)
                else
                    XLog.Error("rewardGoodsList Is NULL!")
                end
        end)
    else
        XUiManager.OpenUiTipReward(rewardData, CSTextManagerGetText("DailyActiveRewardTitle"))
    end
end

function XUiGridPhasesTask:UpdateData(data)
    self.Data = data
    if data then
        local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
        local IsCanGet = mentorData:CheckStudentWeeklyRewardCanGetByCount(data.Count)
        local IsGeted = mentorData:CheckStudentWeeklyRewardGetedByCount(data.Count)
        if IsCanGet then
            self.ImgActive:SetSprite(CS.XGame.ClientConfig:GetString("TaskDailyActiveReach1"))
            self.PanelEffect.gameObject:SetActiveEx(not IsGeted)
            self.ImgRe.gameObject:SetActiveEx(IsGeted)
        else
            self.ImgActive:SetSprite(CS.XGame.ClientConfig:GetString("TaskDailyActiveNotReach1"))
            self.PanelEffect.gameObject:SetActiveEx(false)
            self.ImgRe.gameObject:SetActiveEx(false)
        end
        self.TxtValue.text = string.format("%d",data.Count)
    end
end

return XUiGridPhasesTask