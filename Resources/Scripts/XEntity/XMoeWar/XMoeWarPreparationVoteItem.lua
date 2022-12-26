--萌战赛事筹备--应援数据
local type = type

local XMoeWarPreparationVoteItem = XClass(nil, "XMoeWarPreparationVoteItem")

local DefaultMain = {
    ItemId = 0,     --道具id
    ItemCount = 0,  --道具数量
}

function XMoeWarPreparationVoteItem:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XMoeWarPreparationVoteItem:UpdateData(data)
    self.ItemId = data.ItemId
    self.ItemCount = data.ItemCount
end

function XMoeWarPreparationVoteItem:GetItemCount()
    return self.ItemCount
end

return XMoeWarPreparationVoteItem