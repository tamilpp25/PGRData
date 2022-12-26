
local XRedPointConditionNieRCharacterRed = {}
local Events = nil
function XRedPointConditionNieRCharacterRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_NIER_STAGE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_NIER_CHARACTER_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA),
    }
    return Events
end

function XRedPointConditionNieRCharacterRed.Check(args)
    local characterId = args.CharacterId
    local isInfor = args.IsInfor
    local isTeach = args.IsTeach
    local red = XDataCenter.NieRManager.CheckNieRCharacterRed(characterId, isInfor, isTeach)
    return red
end

return XRedPointConditionNieRCharacterRed