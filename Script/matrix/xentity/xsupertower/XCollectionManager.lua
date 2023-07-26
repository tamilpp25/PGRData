local XCollectionManager = XClass(nil, "XCollectionManager")

function XCollectionManager:Ctor()
    self.Datas = {}
    self.CurrentCapacity = 0
    self.MaxCapacity = 0
end

function XCollectionManager:InitDatas(datas)
    self.Datas = datas
end

function XCollectionManager:UpdateCurrentCapacity(value)
    self.CurrentCapacity = value
end

function XCollectionManager:UpdateMaxCapacity(value)
    self.MaxCapacity = value
end

function XCollectionManager:GetMaxCapacity()
    return self.MaxCapacity
end

function XCollectionManager:GetCurrentCapacity()
    return self.CurrentCapacity
end

function XCollectionManager:AddData(data)
    table.insert(self.Datas, data)
end

function XCollectionManager:DeleteData(id)
    local data
    for i = #self.Datas, 1, -1 do
        data = self.Datas[i]
        if self:GetDataIsEqual(data, id) then
            table.remove(self.Datas, i)
            break
        end
    end
end

function XCollectionManager:GetIsHaveData(id)
    local data = self:GetData(id)
    if not data then return false end
    return data:GetCount() > 0
end

function XCollectionManager:GetData(id)
    local data
    for i = #self.Datas, 1, -1 do
        data = self.Datas[i]
        if self:GetDataIsEqual(data, id) then
            return data
        end
    end
    return nil
end

function XCollectionManager:GetDatas()
    return self.Datas
end

function XCollectionManager:UpdateData(id, data)
    local data
    for i = #self.Datas, 1, -1 do
        data = self.Datas[i]
        if self:GetDataIsEqual(data, id) then
            self.Datas[i] = data
            break
        end
    end
end

--######################## 私有方法 ########################

function XCollectionManager:GetDataIsEqual(data, id)
    -- 兼容直接id的写法与获取id的写法
    return (data.Id and data.Id == id) 
        or (data.GetId and type(data.GetId) == "function" and data:GetId() == id)
end

return XCollectionManager