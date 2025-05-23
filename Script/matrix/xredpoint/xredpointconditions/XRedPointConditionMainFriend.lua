
----------------------------------------------------------------
--角色入口红点检测
local XRedPointConditionMainFriend = {}
local SubConditions = nil

function XRedPointConditionMainFriend.Check()
    local count = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FRIEND_CONTACT)
    if count > 0 then
        return count
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FRIEND_WAITPASS) then
        return true
    end
end

function XRedPointConditionMainFriend.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_FRIEND_CONTACT,     --私聊信息标签
        XRedPointConditions.Types.CONDITION_FRIEND_WAITPASS
    }
    return SubConditions
end

return XRedPointConditionMainFriend