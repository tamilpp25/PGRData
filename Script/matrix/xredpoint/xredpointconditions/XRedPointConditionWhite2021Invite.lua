--2021白色情人节活动邀约红点
local XRedPointConditionWhite2021Invite = {}
local Events = nil
function XRedPointConditionWhite2021Invite.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_WHITEVALENTINE_INVITE_CHANCE_REFRESH),
        XRedPointEventElement.New(XEventId.EVENT_WHITEVALENTINE_CHARA_CHANGE)
    }
    return Events
end

function XRedPointConditionWhite2021Invite.Check()
    local GameController = XDataCenter.WhiteValentineManager.GetGameController()
    return GameController:CheckCanInviteChara()
end
return XRedPointConditionWhite2021Invite