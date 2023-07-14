local type = type

local XLivWarmActivityStageDb = XClass(nil, "XLivWarmActivityStageDb")

local DefaultMain = {
    _StageId = 0,   --关卡id
    _GridData = {}, --格子的数据（二维数组）
    _DismisCount = 0,   --累计消除进度计数
    _TakeRewardProgressIndex = -1,    --已领取奖励的索引，服务端下发的需+1索引配置，小于等于该索引的为已领取
    _IsWin = false, --是否胜利
    _ChangeCount = 0,   --改变次数
}

function XLivWarmActivityStageDb:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XLivWarmActivityStageDb:UpdateData(data)
    if data.StageId then
        self._StageId = data.StageId
    end
    if data.GridData then
        self._GridData = data.GridData
    end
    if data.DismisCount then
        self._DismisCount = data.DismisCount
    end
    if data.TakeRewardProgressIndex then
        self._TakeRewardProgressIndex = data.TakeRewardProgressIndex + 1
    end
    if data.ChangeCount then
        self._ChangeCount = data.ChangeCount
    end

    self._IsWin = data.IsWin or false
end

function XLivWarmActivityStageDb:GetGridData()
    return self._GridData
end

function XLivWarmActivityStageDb:GetDismisCount()
    return self._DismisCount
end

function XLivWarmActivityStageDb:IsWin()
    return self._IsWin
end

function XLivWarmActivityStageDb:GetChangeCount()
    return self._ChangeCount
end

function XLivWarmActivityStageDb:SetTakeRewardProgressIndex(index)
    self._TakeRewardProgressIndex = index
end

function XLivWarmActivityStageDb:GetTakeRewardProgressIndex()
    return self._TakeRewardProgressIndex
end

function XLivWarmActivityStageDb:AddOnceChangeCount()
    self._ChangeCount = self._ChangeCount + 1
end

return XLivWarmActivityStageDb