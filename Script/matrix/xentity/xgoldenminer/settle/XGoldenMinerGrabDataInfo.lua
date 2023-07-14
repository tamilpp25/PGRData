local type = type

--抓取的黄金类的道具信息
local XGoldenMinerGrabDataInfo = XClass(nil, "XGoldenMinerGrabDataInfo")

local Default = {
    _ItemId = 0, --GoldenMinerStone表的Id
    _Scores = 0, --抓取物积分
    _Count = 0, --抓到的数量
    _AdditionalItem = {}, --附加道具id
}

function XGoldenMinerGrabDataInfo:Ctor(itemId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._ItemId = itemId
end

--goldenMinerObj：XEntity/XGoldenMiner/Object目录下的对象
function XGoldenMinerGrabDataInfo:AddData(goldenMinerObj)
    self._Count = self._Count + 1
    self._Scores = self._Scores + goldenMinerObj:GetScore()

    local goldenMinerItemId = goldenMinerObj.GetItemId and goldenMinerObj:GetItemId()
    if XTool.IsNumberValid(goldenMinerItemId) then
        table.insert(self._AdditionalItem, goldenMinerItemId)
    end
end

function XGoldenMinerGrabDataInfo:GetItemId()
    return self._ItemId
end

function XGoldenMinerGrabDataInfo:GetScores()
    return math.floor(self._Scores)
end

function XGoldenMinerGrabDataInfo:GetCount()
    return self._Count
end

function XGoldenMinerGrabDataInfo:GetAdditionalItem()
    return self._AdditionalItem
end

return XGoldenMinerGrabDataInfo