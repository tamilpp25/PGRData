---@class XUiGuildWarSupportGrid
local XUiGuildWarSupportGrid = XClass(nil, "XUiGuildWarSupportGrid")

function XUiGuildWarSupportGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGuildWarSupportGrid:Update(data)
    local time = XTime.TimestampToLocalDateTimeString(data.UserTime, "yyyy-MM-dd HH:mm")
    local name1 = XPlayer.Name
    local memberData = XDataCenter.GuildManager.GetMemberDataByPlayerId(data.UserId)
    local name2 = memberData and memberData.Name or "???"
    local reward = data.Supply or 0
    local text
    if reward > 0 then
        text = XUiHelper.GetText("GuildWarAssistantLog", time, name1, name2, reward)
    else
        text = XUiHelper.GetText("GuildWarAssistantLogWithoutReward", time, name1, name2)
    end
    self.TxtRecord.text = XUiHelper.ReplaceUnicodeSpace(text)
end

return XUiGuildWarSupportGrid
