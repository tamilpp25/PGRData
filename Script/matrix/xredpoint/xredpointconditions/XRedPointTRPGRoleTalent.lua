----------------------------------------------------------------
--主线跑团调查员天赋红点检测
local XRedPointTRPGRoleTalent = {}
local Events = nil

function XRedPointTRPGRoleTalent.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TRPG_BASE_INFO_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_TRPG_ROLES_DATA_CHANGE),
    }
    return Events
end

function XRedPointTRPGRoleTalent.Check()
    return XDataCenter.TRPGManager.CheckRoleTalentRedPoint()
end

return XRedPointTRPGRoleTalent