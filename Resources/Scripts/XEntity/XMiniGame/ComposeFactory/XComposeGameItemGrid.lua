-- 组合小游戏背包格对象
local XComposeGameItemGrid = XClass(nil, "XComposeGameItemGrid")

--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param bag:背包对象
--==================
function XComposeGameItemGrid:Ctor(bag)
    self.Bag = bag
    self:Reset()
end
--==================
--重置背包格状态
--==================
function XComposeGameItemGrid:Reset()
    self:ResetItem()
end
--==================
--重置背包格道具状态
--==================
function XComposeGameItemGrid:ResetItem()
    if not self.Item then
        local XItem = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItem")
        self.Item = XItem.New(nil, true)
    else
        self.Item:Reset()
    end
end
--==================
--向背包格添加指定ID的道具
--@param itemId:玩法道具ID
--==================
function XComposeGameItemGrid:AddItem(itemId)
    if not itemId then
        XDataCenter.ComposeGameManager.DebugLog(
            "XComposeGameItemGrid:AddItem往背包格添加道具展示失败，错误原因:要添加的道具Id为空。"
            )
        return
    elseif not self.Item:CheckIsEmpty() then
        XDataCenter.ComposeGameManager.DebugLog(
            "XComposeGameItemGrid:AddItem往背包格添加道具展示失败，错误原因:往已有展示道具的背包格添加道具。"
        )
        return
    end
    self:GetItem():RefreshItem(itemId)
end
--==================
--清空背包格的道具
--==================
function XComposeGameItemGrid:Empty()
    self:GetItem():Empty()
end
--==================
--检查背包格是否为指定ID的道具，是的话清空背包格的道具
--@param itemId:玩法道具ID
--==================
function XComposeGameItemGrid:EmptyByItemId(itemId)
    if self:GetItem():GetId() == itemId then
        self:Empty()
    end
end
--==================== END ========================

--=================对外接口(Get,Set,Check等接口)================
--==================
--获取背包格的道具
--==================
function XComposeGameItemGrid:GetItem()
    if not self.Item then
        self:ResetItem()
    end
    return self.Item
end
--==================
--获取背包格道具星级
--==================
function XComposeGameItemGrid:GetItemStar()
    return self:GetItem():GetStar()
end
--==================
--获取背包格道具顺序序号
--==================
function XComposeGameItemGrid:GetOrderId()
    return self:GetItem():GetOrderId()
end
--==================
--检查背包格是否为空
--==================
function XComposeGameItemGrid:CheckIsEmpty()
    return self:GetItem():CheckIsEmpty()
end
--==================== END ========================
return XComposeGameItemGrid