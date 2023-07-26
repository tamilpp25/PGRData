XAssistConfig = XAssistConfig or {}

local AssistRuleTemplate = {}

local TABLE_ASSISTRULE = "Share/Fuben/Assist/AssistRule.tab";

function XAssistConfig.Init()
    AssistRuleTemplate = XTableManager.ReadByIntKey(TABLE_ASSISTRULE, XTable.XTableAssistRule, "Id")
end
function XAssistConfig.GetAssistRuleTemplate(id)
    return AssistRuleTemplate[id]
end