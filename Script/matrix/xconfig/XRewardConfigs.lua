XRewardConfigs = XRewardConfigs or {}

local TABLE_REWARD_CONFIRM = "Client/Reward/RewardConfirm.tab"

local RewardConfirmTemplates

function XRewardConfigs.Init()
    RewardConfirmTemplates = XTableManager.ReadByIntKey(TABLE_REWARD_CONFIRM, XTable.XTableRewardConfirm, "Id")
end

function XRewardConfigs.IsRewardNeedConfirm(Id)
    return RewardConfirmTemplates[Id] ~= nil
end

function XRewardConfigs.GetRewardConfirmTemplate(Id)
    local template = RewardConfirmTemplates[Id]
    if template then
        return RewardConfirmTemplates[Id]
    end
end