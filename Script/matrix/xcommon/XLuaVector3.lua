local type = type

---@class XLuaVector3
XLuaVector3 = XClass(nil, "XLuaVector3")

function XLuaVector3:Ctor(x, y, z)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
end

--region static - public
---@param value XLuaVector3
function XLuaVector3.CheckIsVector(value)
    return type(value) == "table" and value.__cname == "XLuaVector3"
end

function XLuaVector3.Equal(value1, value2)
    return value1.x & value2.x and value1.y & value2.y and value1.z & value2.z
end

---@param a XLuaVector3
---@param b XLuaVector3
---@return XLuaVector3
function XLuaVector3.Add(a, b)
    if not XLuaVector3.CheckIsVector(a) or not XLuaVector3.CheckIsVector(b) then
        XLog.Error("XLuaVector3 Addition Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector3.New(a.x + b.x, a.y + b.y, a.z + b.z)
end

---@param a XLuaVector3
---@param b XLuaVector3
---@return XLuaVector3
function XLuaVector3.Sub(a, b)
    if not XLuaVector3.CheckIsVector(a) or not XLuaVector3.CheckIsVector(b) then
        XLog.Error("XLuaVector3 Subtraction Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector3.New(a.x - b.x, a.y - b.y, a.z - b.z)
end

---@return XLuaVector3
function XLuaVector3.Mul(a, b)
    if XLuaVector3.CheckIsVector(a) and type(b) == "number" then
        return XLuaVector3.New(a.x * b, a.y * b, a.z * b)
    end

    if XLuaVector3.CheckIsVector(b) and type(a) == "number" then
        return XLuaVector3.New(b.x * a, b.y * a, b.z * a)
    end

    return XLuaVector3.Cross(a, b)
end

---@return XLuaVector3
function XLuaVector3.Div(a, b)
    if XLuaVector3.CheckIsVector(a) and type(b) == "number" then
        if XTool.IsNumberValid(b) then
            return XLuaVector3.New(a.x / b, a.y / b, a.z / b)
        else
            XLog.Error("XLuaVector3 Division Error Parameter error: b = 0!")
            return false
        end
    end

    if XLuaVector3.CheckIsVector(b) and type(a) == "number" then
        if XTool.IsNumberValid(a) then
            return XLuaVector3.New(b.x / a, b.y / a, b.z / a)
        else
            XLog.Error("XLuaVector3 Division Error Parameter error: a = 0!")
            return false
        end
    end
    XLog.Error("XLuaVector3 Division Error Parameter error! Please check the parameter!")
    return false
end

---@param value1 XLuaVector3
---@param value2 XLuaVector3
---@return XLuaVector3
function XLuaVector3.Cross(value1, value2)
    if not XLuaVector3.CheckIsVector(value1) or not XLuaVector3.CheckIsVector(value2) then
        XLog.Error("XLuaVector3 Cross Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector3.New(value1.y * value2.z - value1.z * value2.y,
            value1.z * value2.x - value1.x * value2.z,
            value1.x * value2.y - value1.y * value2.x)
end

---@param value1 XLuaVector3
---@param value2 XLuaVector3
---@return number
function XLuaVector3.Dot(value1, value2)
    return value1.x * value2.x + value1.y * value2.y + value1.z * value2.z
end

---@param value1 XLuaVector3
---@param value2 XLuaVector3
---@return number
function XLuaVector3.Distance(value1, value2)
    local x = value1.x - value2.x
    local y = value1.y - value2.y
    local z = value1.z - value2.z
    return math.sqrt(x * x + y * y + z * z)
end

---@param value XLuaVector3
---@return number
function XLuaVector3.Magnitude(value)
    return math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
end

---@param value XLuaVector3
---@return XLuaVector3
function XLuaVector3.Normalize(value)
    local num = XLuaVector3.Magnitude(value)
    return XLuaVector3.New(value.x / num, value.y / num, value.z / num)
end
--endregion

--region public
function XLuaVector3:EqualVector(value)
    return self.x & value.x and self.y & value.y and self.z & value.z
end

function XLuaVector3:Update(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
end

function XLuaVector3:UpdateByVector(vector)
    self.x = vector.x
    self.y = vector.y
    self.z = vector.z
end

---@param v XLuaVector3
function XLuaVector3:AddVector(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
end

---@param v XLuaVector3
function XLuaVector3:SubVector(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
end

function XLuaVector3:MulNumber(number)
    self.x = self.x * number
    self.y = self.y * number
    self.z = self.z * number
end

function XLuaVector3:DivNumber(number)
    if XTool.IsNumberValid(number) then
        self.x = self.x / number
        self.y = self.y / number
        self.z = self.z / number
    end
end
--endregion