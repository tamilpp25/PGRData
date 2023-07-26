---@class XNewYearLuckLevel
local XNewYearLuckLevel = XClass(nil, "XNewYearLuckLevel")

function XNewYearLuckLevel:Ctor(type, gridIndex, price)
    self.Type = type
    self.GridIndex = gridIndex
    self.Price = price
    self.Status = -1
end

function XNewYearLuckLevel:UpdateData(data)
    if not data then
        return
    end
    self.LuckNumber = data.LuckNum
    self.Status = data.AwardStatus
    self.LevelId = data.LevelId
end

function XNewYearLuckLevel:GetLuckNumber()
    return self.LuckNumber
end

function XNewYearLuckLevel:IsDraw()
    return self.Status == 0
end

function XNewYearLuckLevel:IsRewarded()
    return self.Status == 1
end
---@return XTable.XTableNewYearLuckLevel
function XNewYearLuckLevel:GetLevelConfig()
    if not self.LevelId then
        return
    end
    return XDataCenter.NewYearLuckManager.GetLevelConfig(self.LevelId)
end

function XNewYearLuckLevel:AwardRequest(cb)
    local req = {
        LevelId = self.LevelId,
        GridIndex = self.GridIndex
    }
    XNetwork.Call("NewYearAwardRequest",req,function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self.Status = 1
        if cb then
            cb(res.AwardList)
        end
    end)
end

function XNewYearLuckLevel:LotteryRequest(type,cb)
    local req = {
        GroupType = type,
        GridIndex = self.GridIndex
    }
    XNetwork.Call("NewYearLotteryRequest",req,function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self.LevelId = res.LevelId
        self.LuckNumber = res.LuckNum
        self.Status = 0
        if cb then
            cb()
        end
    end)
end

return XNewYearLuckLevel