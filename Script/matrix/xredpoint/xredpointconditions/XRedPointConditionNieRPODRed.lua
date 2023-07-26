
local XRedPointConditionNieRPODRed = {}
local Events = nil
function XRedPointConditionNieRPODRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_NIER_STAGE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_NIER_POD_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_NIER_CHARACTER_UPDATE),
    }
    local consumeIdDic = {}
    local podSkillLevelCfgs = XNieRConfigs.GetAllNieRSupportSkillLevelConfig()
    
    for _, cfg in pairs(podSkillLevelCfgs) do
        local consumeId = cfg.UpgradeConsumeId
        if consumeId ~= 0 and not consumeIdDic[consumeId] then
            consumeIdDic[consumeId] = true
            table.insert(Events, XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. consumeId))
        end
    end
    return Events
end

function XRedPointConditionNieRPODRed.Check()
    local red = XDataCenter.NieRManager.CheckNieRPODRed()
    return red
end

return XRedPointConditionNieRPODRed