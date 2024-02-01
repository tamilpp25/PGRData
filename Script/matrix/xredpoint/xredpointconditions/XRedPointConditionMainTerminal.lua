

local XRedPointConditionMainTerminal = {}
local subConditions = nil

local subEvent = nil

function XRedPointConditionMainTerminal.GetSubEvents()
    subEvent = subEvent or {
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE)
    }
    return subEvent
end

function XRedPointConditionMainTerminal.GetSubConditions()
    subConditions = subConditions or {
        --XRedPointConditions.Types.CONDITION_MAIN_WEEK,
        XRedPointConditions.Types.CONDITION_MAIN_FRIEND,
        XRedPointConditions.Types.CONDITION_MAIN_SET,
        XRedPointConditions.Types.CONDITION_SUBMENU_NEW_NOTICES,
        XRedPointConditions.Types.CONDITION_SUBMENU_NEW_SYSTEM,
        XRedPointConditions.Types.CONDITION_SCENE_SETTING,
    }
    return subConditions
end

function XRedPointConditionMainTerminal.Check()
    local conditions = XRedPointConditionMainTerminal.GetSubConditions()
    for _, condition in pairs(conditions) do
        local state = XRedPointConditions[condition].Check()
        if state then
            return true
        end
    end

    if XDataCenter.PurchaseManager.CheckYKContinueBuy() then
        return true
    end

    local giftCount = XDataCenter.PurchaseManager.ExpireCount or 0
    if giftCount > 0 then
        return true
    end
    
    local dormEntrust = XDataCenter.DormQuestManager.CheckDormEntrustRedPoint(true)
    if dormEntrust then
        return true
    end

    ---@type XUiMainAgency
    local ag = XMVCA:GetAgency(ModuleId.XUiMain)
    local itemList = ag:GetAllActiveTipExpensiveiItems()
    if not XTool.IsTableEmpty(itemList) and not ag:CheckPanelTipClicked(XEnumConst.Ui_MAIN.TerminalTipType.ExpensiveItem) then
        return true
    end
    
    return false
end

return XRedPointConditionMainTerminal