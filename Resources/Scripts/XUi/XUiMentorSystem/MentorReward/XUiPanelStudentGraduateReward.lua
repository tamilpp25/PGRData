local XUiPanelStudentGraduateReward = XClass(nil, "XUiPanelStudentGraduateReward")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelStudentGraduateReward:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:InitPanel()
    self:SetButtonCallBack()
end

function XUiPanelStudentGraduateReward:SetButtonCallBack()
    self.PanelClostTask:GetObject("BtnGift").CallBack = function()
        self:OnBtnGiftClick()
    end
end

function XUiPanelStudentGraduateReward:OnBtnGiftClick()
    local mailId = XMentorSystemConfigs.GetMentorSystemData("GiftMailId")
    XLuaUiManager.Open("UiMentorRewardTisp", mailId, function ()
        self:UpdatePanel()
    end)
end

function XUiPanelStudentGraduateReward:InitPanel()
    local rewardId = XMentorSystemConfigs.GetMentorSystemData("GraduateRewardId")
    local rewards = XRewardManager.GetRewardList(rewardId)
    self.GridCommon.gameObject:SetActiveEx(false)
    if rewards then
        for _, item in pairs(rewards or {}) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon,self.RewaedContent)
            local grid = XUiGridCommon.New(self.Base, obj)
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
end

function XUiPanelStudentGraduateReward:UpdatePanel()
    local graduateLv = XMentorSystemConfigs.GetMentorSystemData("GraduateLv")
    local autoGraduateLv = XMentorSystemConfigs.GetMentorSystemData("AutoGraduateLv")
    local IsCanGraduate = XDataCenter.MentorSystemManager.CheckStudentCanGraduate()
    local IsCanSendGift = XDataCenter.MentorSystemManager.CheckStudentCanSendGift()
    
    self.PanelCurLevel:GetObject("Text").text = CSTextManagerGetText("MentorStudentCurLevelText", CSTextManagerGetText("MentorLevelText", XPlayer.Level))
    self.PanelUnClostTask:GetObject("Text").text = CSTextManagerGetText("MentorLevelText", graduateLv)
    self.PanelClostTask:GetObject("Text").text = CSTextManagerGetText("MentorLevelText", graduateLv)
    self.PanelUnGraduate:GetObject("Text").text = CSTextManagerGetText("MentorLevelText", autoGraduateLv)
    
    self.PanelUnClostTask.gameObject:SetActiveEx(not IsCanGraduate)
    self.PanelClostTask.gameObject:SetActiveEx(IsCanGraduate)
    
    self.PanelClostTask:GetObject("BtnGift").gameObject:SetActiveEx(IsCanSendGift)
    self.PanelClostTask:GetObject("BtnDisable").gameObject:SetActiveEx(not IsCanSendGift)
end

return XUiPanelStudentGraduateReward