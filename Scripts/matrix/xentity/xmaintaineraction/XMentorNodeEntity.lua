local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XMentorNodeEntity = XClass(XMaintainerActionNodeEntity, "XMentorNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XMentorNodeEntity:Ctor()
    self.MemberName = ""
    self.MentorStatus = XMaintainerActionConfigs.MonterNodeStatus.NotActive
    self.OldEventId = nil
end

function XMentorNodeEntity:GetMemberName()
    return self.MemberName
end

function XMentorNodeEntity:GetMentorStatus()
    return self.MentorStatus
end

function XMentorNodeEntity:GetOldEventId()
    return self.OldEventId
end

function XMentorNodeEntity:GetOldCfg()
    if self.OldEventId then
        return XMaintainerActionConfigs.GetMaintainerActionEventTemplateById(self.OldEventId)
    else
        return XMaintainerActionConfigs.GetMaintainerActionEventTemplateById(self.EventId)
    end
end

function XMentorNodeEntity:GetHint()
    return self:GetOldCfg().HintText
end

function XMentorNodeEntity:GetRewardList()
    local rewardList = {}
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()

    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)

    if mentorData:IsTeacher() then
        rewardList = mailAgency:GetRewardList(gameData:GetTeacherMailId())
    elseif mentorData:IsStudent() then
        rewardList = mailAgency:GetRewardList(gameData:GetStudentMailId())
    end
    return rewardList
end

function XMentorNodeEntity:GetRewardTitle()
    return CS.XTextManager.GetText("MaintainerActionMentorReward")
end

function XMentorNodeEntity:OpenDescTip()
    XLuaUiManager.Open("UiFubenMaintaineractionDetailsTips", self, true)
end

function XMentorNodeEntity:GetDesc()
    return string.format(self:GetCfg().DescText,self.MemberName)
end

function XMentorNodeEntity:DoEvent(data)
    if not data then return end
    data.player:MarkNodeEvent()
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:SetMentorStatus(self:GetMentorStatus())
    if data.cb then data.cb() end
end

function XMentorNodeEntity:EventRequest(mainUi, player, cb)
    XDataCenter.MaintainerActionManager.NodeEventRequest(function (data)
            self:UpdateData(data)
            self:OpenHintTip(function ()
                    local tmpData = {
                        player = player,
                        cb = cb,
                        mainUi = mainUi
                    }
                    self:DoEvent(tmpData)
                end)
        end,function ()
            player:MarkNodeEvent()
            if cb then cb() end
        end)
end

return XMentorNodeEntity