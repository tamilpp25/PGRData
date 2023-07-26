local XCampNotifyData = require("XEntity/XGuardCamp/XCampNotifyData")

local type = type

local XGuardActivityNotifyData = XClass(nil, "XGuardActivityNotifyData")

local Default = {
    __Id = 0,               --活动id
    __WinCampId = 0,        --胜利阵营
    __PondCount = 0,        --奖池数量
    __CampDatas = {},       --阵营信息
}

function XGuardActivityNotifyData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.__Id = id
end

function XGuardActivityNotifyData:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self.__WinCampId = data.WinCampId
    self.__PondCount = data.PondCount

    if not XTool.IsTableEmpty(data.CampDatas) then
        for _, v in ipairs(data.CampDatas) do
            if not self.__CampDatas[v.Id] then
                self.__CampDatas[v.Id] = XCampNotifyData.New(v.Id)
            end
            self.__CampDatas[v.Id]:UpdateData(v)
        end
    end
end

function XGuardActivityNotifyData:GetWinCampId()
    return self.__WinCampId
end

function XGuardActivityNotifyData:GetPondCount()
    return self.__PondCount
end

function XGuardActivityNotifyData:GetJoinNumByCampId(campId)
    return self.__CampDatas[campId] and self.__CampDatas[campId]:GetJoinNum() or 0
end

function XGuardActivityNotifyData:GetSupportNumByCampId(campId)
    return self.__CampDatas[campId] and self.__CampDatas[campId]:GetSupportNum() or 0
end

function XGuardActivityNotifyData:GetJoinTotalNum()
    local totalNum = 0
    local joinNum
    for id in pairs(self.__CampDatas) do
        joinNum = self:GetJoinNumByCampId(id)
        totalNum = totalNum + joinNum
    end
    return totalNum
end

return XGuardActivityNotifyData