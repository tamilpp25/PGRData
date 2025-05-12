local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridPhasesReward = XClass(nil, "XUiGridPhasesReward")
local CSTextManagerGetText = CS.XTextManager.GetText
local DefaultIndex = 1

function XUiGridPhasesReward:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridPhasesReward:SetButtonCallBack()
    self.BtnActive.CallBack = function()
        self:OnBtnActiveClick()
    end
end

function XUiGridPhasesReward:OnBtnActiveClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local IsCanGet = mentorData:CheckTeacherStageRewardCanGetByCount(self.Data.Count)
    local IsGeted = mentorData:CheckTeacherStageRewardGetedByCount(self.Data.Count)
    if IsCanGet then
        if IsGeted then
            return
        end
        
        XDataCenter.MentorSystemManager.MentorGetStageRewardRequest(self.Data.Count, function (rewardGoodsList)
                self.Base:UpdatePanelPhasesReward()
                XUiManager.OpenUiObtain(rewardGoodsList)
        end)
    end
end

function XUiGridPhasesReward:UpdateData(data)
    self.Data = data
    if data then
        local rewardData = XRewardManager.GetRewardList(self.Data.RewardId)
        local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
        local IsCanGet = mentorData:CheckTeacherStageRewardCanGetByCount(data.Count)
        local IsGeted = mentorData:CheckTeacherStageRewardGetedByCount(data.Count)
       
        if IsCanGet then
            self.PanelEffect.gameObject:SetActiveEx(not IsGeted)
            self.PanelFinish.gameObject:SetActiveEx(IsGeted)
            self.BtnActive.gameObject:SetActiveEx(not IsGeted)
        else
            self.PanelEffect.gameObject:SetActiveEx(false)
            self.PanelFinish.gameObject:SetActiveEx(false)
            self.BtnActive.gameObject:SetActiveEx(false)
        end
        
        if not self.RewardGrid then
            self.RewardGrid = XUiGridCommon.New(self.Root, self.GridCommon)
        end

        self.RewardGrid:Refresh(rewardData[DefaultIndex])
        self.TxtValue.text = string.format("%d",data.Count)
    end
end

return XUiGridPhasesReward