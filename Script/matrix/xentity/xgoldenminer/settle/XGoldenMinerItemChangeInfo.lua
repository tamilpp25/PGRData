local type = type

--道具栏变更状态同步
local XGoldenMinerItemChangeInfo = XClass(nil, "XGoldenMinerItemChangeInfo")

local Default = {
    _ItemId = 0,
    _Status = 1, --变更状态（1消耗，2获得）
    _GridIndex = 0, --格子位置
}

function XGoldenMinerItemChangeInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XGoldenMinerItemChangeInfo:UpdateData(data)
    self._ItemId = data.ItemId
    self._Status = data.Status
    self._GridIndex = data.GridIndex
end

function XGoldenMinerItemChangeInfo:GetItemId()
    return self._ItemId
end

function XGoldenMinerItemChangeInfo:GetStatus()
    return self._Status
end

function XGoldenMinerItemChangeInfo:GetGridIndex()
    return self._GridIndex
end

return XGoldenMinerItemChangeInfo