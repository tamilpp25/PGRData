local tableInsert = table.insert

XMailConfigs = XMailConfigs or {}

local TABLE_MAIL_PATH = "Share/Mail/Mail.tab"
local TABLE_MAIL_REWARD_GOODS_PATH = "Share/Mail/MailRewardGoods.tab"

local MailRewardTemplates = {}


function XMailConfigs.Init()
    local mailTable = XTableManager.ReadByIntKey(TABLE_MAIL_PATH, XTable.XTableMail, "Id")
    local rewardGoodsTable = XTableManager.ReadByIntKey(TABLE_MAIL_REWARD_GOODS_PATH, XTable.XTableRewardGoods, "Id")

    for k, v in pairs(mailTable) do
        local list = {}
        for _, id in pairs(v.RewardIds) do
            local tab = rewardGoodsTable[id]
            if not tab then
                XLog.ErrorTableDataNotFound("XMailConfigs.Init", "tab", TABLE_MAIL_REWARD_GOODS_PATH, "id", tostring(id))
                return
            end
            tableInsert(list, XRewardManager.CreateRewardGoodsByTemplate(tab))
        end
        MailRewardTemplates[k] = list
    end

    MailRewardTemplates = XReadOnlyTable.Create(MailRewardTemplates)
end

function XMailConfigs.GetMailRewardTemplates()
    return MailRewardTemplates
end

function XMailConfigs.GetRewardList(mailId)
    local rewardList = MailRewardTemplates[mailId]
    if not rewardList then
        XLog.ErrorTableDataNotFound("XMailConfigs.GetRewardList", "tab", TABLE_MAIL_REWARD_GOODS_PATH, "id", tostring(mailId))
        return
    end

    return rewardList
end