local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiMentorRewardTisp = XLuaUiManager.Register(XLuaUi, "UiMentorRewardTisp")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiMentorRewardTisp:OnStart(mailId, cb)
    self:SetButtonCallBack()
    self:ShowPanel(mailId)
    self.CallBack = cb
end

function XUiMentorRewardTisp:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnStand.CallBack = function()
        self:OnBtnStandClick()
    end
end

function XUiMentorRewardTisp:OnBtnStandClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    local teacher = mentorData:GetTeacherData()
    XDataCenter.MentorSystemManager.MentorStudentSendRewardRequest(teacher.PlayerId, function ()
            XUiManager.TipText("MentorStudentGiftCompletHint")
            self:Close()
            if self.CallBack then self.CallBack() end
        end)
end

function XUiMentorRewardTisp:ShowPanel(mailId)
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    local rewards = mailAgency:GetRewardList(mailId)
    self.GridGift.gameObject:SetActiveEx(false)
    if rewards then
        for _, item in pairs(rewards or {}) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridGift,self.PanelGift)
            local grid = XUiGridCommon.New(self, obj)
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
end