--######################## XASelectableItem ########################
local XASelectableItem = XClass(nil, "XASelectableItem")

function XASelectableItem:Ctor(data)
    self.Data = data
end

function XASelectableItem:GetIcon()
    if not self.Data.ItemId then
        return
    end
    if self.Data.Type == XBiancaTheatreConfigs.SelectableEventItemType.ConsumeItem
        or self.Data.Type == XBiancaTheatreConfigs.SelectableEventItemType.CheckHasItem then
        return XBiancaTheatreConfigs.GetEventStepItemIcon(self.Data.ItemId, self:GetItemType())
    end
    return self.Data.Icon
end

function XASelectableItem:GetDesc()
    return self.Data.Desc
end

function XASelectableItem:GetItemId()
    return self.Data.ItemId
end

function XASelectableItem:GetItemType()
    return self.Data.ItemType
end

function XASelectableItem:GetItemCount()
    if self.Data.Type == XBiancaTheatreConfigs.SelectableEventItemType.ConsumeItem then
        return self.Data.ItemCount and self.Data.ItemCount * -1
    end
    return XTool.IsNumberValid(self.Data.ItemCount) and self.Data.ItemCount or nil
end

-- -- XBiancaTheatreConfigs.SelectableEventItemType
function XASelectableItem:GetSelectType()
    return self.Data.Type
end

function XASelectableItem:GetDownDesc()
    local OptionType = self.Data.Type
    if OptionType == XBiancaTheatreConfigs.SelectableEventItemType.ConsumeItem
        or OptionType == XBiancaTheatreConfigs.SelectableEventItemType.CheckHasItem then
        if self.Data.ItemId then
            if string.IsNilOrEmpty(self.Data.DownDesc) then
                return self.Data.DownDesc
            end
            return string.format(self.Data.DownDesc, XBiancaTheatreConfigs.GetEventStepItemName(self.Data.ItemId, self:GetItemType()))
        else
            XLog.Error("选项事件没配置道具Id", self.Data)
        end
    end
    return self.Data.DownDesc
end

function XASelectableItem:GetOptionId()
    return self.Data.OptionId
end

--######################## XAEventNode ########################
local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
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
                    ItemType = self.EventConfig.OptionItemType[index],
                })) 
            end
        end
        self.__SelectableItems = result
    end
    return self.__SelectableItems
end

-- 检查事件选项是否已经激活
function XASelectableEventNode:CheckOptionIsActive(index)
    local conditionId = self.EventConfig.OptionCondition[index]
    if not conditionId then
        return true
    end
    local result, _ = XConditionManager.CheckCondition(conditionId)
    return result
end

function XASelectableEventNode:RequestTriggerNode(callback, optionIndex)
    local OptionType = self.EventConfig.OptionType[optionIndex]
    if OptionType == XBiancaTheatreConfigs.SelectableEventItemType.ConsumeItem
        or OptionType == XBiancaTheatreConfigs.SelectableEventItemType.CheckHasItem then
        if not XDataCenter.BiancaTheatreManager.CheckItemCountIsEnough(self.EventConfig.OptionItemId[optionIndex], 
                self.EventConfig.OptionItemCount[optionIndex],
                self.EventConfig.OptionItemType[optionIndex])then
            return 
        end
    end
    XASelectableEventNode.Super.RequestTriggerNode(self, callback, optionIndex)
end

return XASelectableEventNode