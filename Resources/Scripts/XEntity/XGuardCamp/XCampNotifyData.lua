local type = type

local XCampNotifyData = XClass(nil, "XCampNotifyData")

local Default = {
    __Id = 0,                --阵营id
    __JoinNum = 0,           --加入人数
    __SupportNum = 0,        --支援数量
}

function XCampNotifyData:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.__Id = id
end

function XCampNotifyData:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self.__JoinNum = data.JoinNum
    self.__SupportNum = data.SupportNum
end

function XCampNotifyData:GetJoinNum()
    return self.__JoinNum
end

function XCampNotifyData:GetSupportNum()
    return self.__SupportNum
end

return XCampNotifyData