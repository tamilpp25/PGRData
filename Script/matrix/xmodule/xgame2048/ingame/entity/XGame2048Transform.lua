--- 记录一个完整操作后的棋盘变换，用于服务端记录
---@class XGame2048Transform
local XGame2048Transform = XClass(nil, 'XGame2048Transform')

function XGame2048Transform:Ctor()
    self.Data = {}
end

function XGame2048Transform:Reset()
    self.Data = {}
end

function XGame2048Transform:SetAfterBlocks(entities)
    -- 转换成基础table的列表形式
    ---@param v XGame2048Grid
    for i, v in pairs(entities) do
        local grid = {
            BlockId = v.Id,
            X = v:GetX(),
            Y = v:GetY(),
            Value = v:GetValue(),
            ExtValue = v:GetExValue(),
        }
        table.insert(self.Data, grid)
    end
end

function XGame2048Transform:GetDataForServer()
    return self.Data
end

return XGame2048Transform