--######################## XASelectableItem ########################
local XASelectableItem = XClass(nil, "XASelectableItem")

function XASelectableItem:Ctor(data)
    self.Data = data
end

function XASelectableItem:GetIcon()
    if self.Data.Type == XTheatreConfigs.SelectableEventItemType.ConsumeItem
        or self.Data.Type == XTheatreConfigs.SelectableEventItemType.CheckHasItem then
        return XEntityHelper.GetItemIcon(self.Data.ItemId)
    end
    return self.Data.Icon
end

function XASelectableItem:GetDesc()
    return self.Data.Desc
end

function XASelectableItem:GetItemId()
    return self.Data.ItemId
end

function XASelectableItem:GetItemCount()
    if self.Data.Type == XTheatreConfigs.SelectableEventItemType.ConsumeItem then
        return self.Data.ItemCount * -1
    end
    return self.Data.ItemCount
end

-- -- XTheatreConfigs.SelectableEventItemType
function XASelectableItem:GetSelectType()
    return self.Data.Type
end

function XASelectableItem:GetDownDesc()
    local OptionType = self.Data.Type
    if OptionType == XTheatreConfigs.SelectableEventItemType.ConsumeItem
        or OptionType == XTheatreConfigs.SelectableEventItemType.CheckHasItem then
        return string.format(self.Data.DownDesc, XEntityHelper.GetItemName(self.Data.ItemId))
    end
    return self.Data.DownDesc
end

function XASelectableItem:GetOptionId()
    return self.Data.OptionId
end

--######################## XAEventNode ########################
local XAEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAEventNode")
-- 选项事件节点
local XASelectableEventNode = XClass(XAEventNode, "XASelectableEventNode")

function XASelectableEventNode:Ctor()
end

function XASelectableEventNode:GetSelectableItems()
    if self.__SelectableItems == nil then
        local result = {}
        for index, desc in ipairs(self.EventConfig.OptionDesc) do
            if self:CheckOptionIsActive(index) then
                table.insert(result, XASelectableItem.New({
                    Desc = desc,
                    Type = self.EventConfig.OptionType[index],
                    ItemId = self.EventConfig.OptionItemId[index],
                    ItemCount = self.EventConfig.OptionItemCount[index],
                    DownDesc = self.EventConfig.OptionDownDesc[index],
                    Icon = self.EventConfig.OptionIcon[index],
                    OptionId = index,
                })) 
            end
        end
        self.__SelectableItems = result
    end
    return self.__SelectableItems
end

-- 检查事件选项是否已经激活
function XASelectableEventNode:CheckOptionIsActive(index)
    local needDecorationId = self.EventConfig.OptionNeedDecoration[index]
    if not needDecorationId then return true end
    if needDecorationId <= 0 then return true end
    local configs = XDataCenter.TheatreManager.GetDecorationManager():GetAllActiveLevelDecorationConfig()
    for _, config in ipairs(configs) do
        for i, cfgType in ipairs(config.Type) do
            if cfgType == XTheatreConfigs.DecorationEventOptionType then
                local params = string.Split(config.Param[i], "|")
                if self.EventConfig.EventId == tonumber(params[1] )
                    and self.EventConfig.StepId == tonumber(params[2])
                    and index == tonumber(params[3]) then
                    return true
                end
            end
        end
    end
    return false
end

function XASelectableEventNode:RequestTriggerNode(callback, optionIndex)
    local OptionType = self.EventConfig.OptionType[optionIndex]
    if OptionType == XTheatreConfigs.SelectableEventItemType.ConsumeItem
        or OptionType == XTheatreConfigs.SelectableEventItemType.CheckHasItem then
        if not XEntityHelper.CheckItemCountIsEnough(self.EventConfig.OptionItemId[optionIndex]
            , self.EventConfig.OptionItemCount[optionIndex]) then
            return 
        end
    end
    XASelectableEventNode.Super.RequestTriggerNode(self, callback, optionIndex)
end

return XASelectableEventNode