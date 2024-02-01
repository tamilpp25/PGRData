local type = type

---@class XLuaVector2
XLuaVector2 = XClass(nil, "XLuaVector2")

function XLuaVector2:Ctor(x, y)
    self.x = x or 0
    self.y = y or 0
end

--region static - public
---@param value XLuaVector2
function XLuaVector2.CheckIsVector(value)
    return type(value) == "table" and value.__cname == "XLuaVector2"
end

function XLuaVector2.Equal(value1, value2)
    return value1.x & value2.x and value1.y & value2.y
end

---@param a XLuaVector2
---@param b XLuaVector2
---@return XLuaVector2
function XLuaVector2.Add(a, b)
    if not XLuaVector2.CheckIsVector(a) or not XLuaVector2.CheckIsVector(b) then
        XLog.Error("XLuaVector2 Addition Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector2.New(a.x + b.x, a.y + b.y)
end

---@param a XLuaVector2
---@param b XLuaVector2
---@return XLuaVector2
function XLuaVector2.Sub(a, b)
    if not XLuaVector2.CheckIsVector(a) or not XLuaVector2.CheckIsVector(b) then
        XLog.Error("XLuaVector2 Subtraction Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector2.New(a.x - b.x, a.y - b.y)
end

---@return XLuaVector2
function XLuaVector2.Mul(a, b)
    if XLuaVector2.CheckIsVector(a) and type(b) == "number" then
        return XLuaVector2.New(a.x * b, a.y * b)
    end

    if XLuaVector2.CheckIsVector(b) and type(a) == "number" then
        return XLuaVector2.New(b.x * a, b.y * a)
    end

    XLog.Error("XLuaVector2 Multiplication Error Parameter error! Please check the parameter!")
    return false
end

---@return XLuaVector2
function XLuaVector2.Div(a, b)
    if XLuaVector2.CheckIsVector(a) and type(b) == "number" then
        if XTool.IsNumberValid(b) then
            return XLuaVector2.New(a.x / b, a.y / b)
        else
            XLog.Error("XLuaVector2 Division Error Parameter error: b = 0!")
            return false
        end
    end

    if XLuaVector2.CheckIsVector(b) and type(a) == "number" then
        if XTool.IsNumberValid(a) then
            return XLuaVector2.New(b.x / a, b.y / a)
        else
            XLog.Error("XLuaVector2 Division Error Parameter error: a = 0!")
            return false
        end
    end
    XLog.Error("XLuaVector2 Division Error Parameter error! Please check the parameter!")
    return false
end

---@param value1 XLuaVector2
---@param value2 XLuaVector2
---@return number
function XLuaVector2.Dot(value1, value2)
    return value1.x * value2.x + value1.y * value2.y
end

---@param value1 XLuaVector2
---@param value2 XLuaVector2
---@return number
function XLuaVector2.Distance(value1, value2)
    local x = value1.x - value2.x
    local y = value1.y - value2.y
    return math.sqrt(x * x + y * y)
end

---@param value XLuaVector2
---@return number
function XLuaVector2.Magnitude(value)
    return math.sqrt(value.x * value.x + value.y * value.y)
end

---@param value XLuaVector2
---@return XLuaVector2
function XLuaVector2.Normalize(value)
    local num = XLuaVector2.Magnitude(value)
    return XLuaVector2.New(value.x / num, value.y / num)
end

function XLuaVector2.GetLinesCrossPoint(line1P1, line1P2, line2P1, line2P2)
    --- 1:y = k1 * x + b1
    --- 2:y = k2 * x + b2
    --- 3:k = (y2 - y1) / (x2 - x1)
    --- 4:b = (x2 * y1 - x1 * y2) / (x2 - x1)
    ---@type XLuaVector2
    local crossLine = XLuaVector2.New()
    local k1 = (line1P2.y - line1P1.y) / (line1P2.x - line1P1.x)
    local b1 = (line1P2.x * line1P1.y - line1P1.x * line1P2.y) / (line1P2.x - line1P1.x)
    local k2 = (line2P2.y - line2P1.y) / (line2P2.x - line2P1.x)
    local b2 = (line2P2.x * line2P1.y - line2P1.x * line2P2.y) / (line2P2.x - line2P1.x)
    local x = (b2 - b1) / (k1 - k2)
    local y = (b1 * k2 - b2 * k1) / (k2 - k1)
    crossLine:Update(x, y)
    return crossLine
end
--endregion

--region public
function XLuaVector2:EqualVector(value)
    return self.x & value.x and self.y & value.y
end

function XLuaVector2:Update(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function XLuaVector2:UpdateByVector(vector)
    self.x = vector.x
    self.y = vector.y
end

---@param v XLuaVector2
function XLuaVector2:AddVector(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
end

---@param v XLuaVector2
function XLuaVector2:SubVector(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
end

function XLuaVector2:MulNumber(number)
    self.x = self.x * number
    self.y = self.y * number
end

function XLuaVector2:DivNumber(number)
    if XTool.IsNumberValid(number) then
        self.x = self.x / number
        self.y = self.y / number
    end
end

function XLuaVector2:Clone()
    return XLuaVector2.New(self.x, self.y)
end
--endregion
