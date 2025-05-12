local type = type

---@class XLuaVector4
XLuaVector4 = XClass(nil, "XLuaVector4")

function XLuaVector4:Ctor(x, y, z, w)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    self.w = w or 0
end

--region static - public
---@param value XLuaVector4
function XLuaVector4.CheckIsVector(value)
    return type(value) == "table" and value.__cname == "XLuaVector4"
end

function XLuaVector4.Equal(value1, value2)
    return value1.x & value2.x and value1.y & value2.y and value1.z & value2.z and value1.w & value2.w
end

---@param a XLuaVector4
---@param b XLuaVector4
---@return XLuaVector4
function XLuaVector4.Add(a, b)
    if not XLuaVector4.CheckIsVector(a) or not XLuaVector4.CheckIsVector(b) then
        XLog.Error("XLuaVector4 Addition Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector4.New(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
end

---@param a XLuaVector4
---@param b XLuaVector4
---@return XLuaVector4
function XLuaVector4.Sub(a, b)
    if not XLuaVector4.CheckIsVector(a) or not XLuaVector4.CheckIsVector(b) then
        XLog.Error("XLuaVector4 Subtraction Parameter error! Please check the parameter!")
        return false
    end
    return XLuaVector4.New(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
end

---@return XLuaVector4
function XLuaVector4.Mul(a, b)
    if XLuaVector4.CheckIsVector(a) and type(b) == "number" then
        return XLuaVector4.New(a.x * b, a.y * b, a.z * b, a.w * b)
    end

    if XLuaVector4.CheckIsVector(b) and type(a) == "number" then
        return XLuaVector4.New(b.x * a, b.y * a, b.z * a, b.w * a)
    end

    return XLuaVector4.Cross(a, b)
end

---@return XLuaVector4
function XLuaVector4.Div(a, b)
    if XLuaVector4.CheckIsVector(a) and type(b) == "number" then
        if XTool.IsNumberValid(b) then
            return XLuaVector4.New(a.x / b, a.y / b, a.z / b, a.w / b)
        else
            XLog.Error("XLuaVector4 Division Error Parameter error: b = 0!")
            return false
        end
    end

    if XLuaVector4.CheckIsVector(b) and type(a) == "number" then
        if XTool.IsNumberValid(a) then
            return XLuaVector4.New(b.x / a, b.y / a, b.z / a, b.w / a)
        else
            XLog.Error("XLuaVector4 Division Error Parameter error: a = 0!")
            return false
        end
    end
    XLog.Error("XLuaVector4 Division Error Parameter error! Please check the parameter!")
    return false
end


---@param value1 XLuaVector4
---@param value2 XLuaVector4
---@return number
function XLuaVector4.Dot(value1, value2)
    return value1.x * value2.x + value1.y * value2.y + value1.z * value2.z + value1.w * value2.w
end

---@param value1 XLuaVector4
---@param value2 XLuaVector4
---@return number
function XLuaVector4.Distance(value1, value2)
    local x = value1.x - value2.x
    local y = value1.y - value2.y
    local z = value1.z - value2.z
    local w = value1.w - value2.w
    return math.sqrt(x * x + y * y + z * z + w * w)
end


---@param value XLuaVector4
---@return XLuaVector4
function XLuaVector4.Normalize(value)
    local num = XLuaVector4.Magnitude(value)
    return XLuaVector4.New(value.x / num, value.y / num, value.z / num, value.w / num)
end
--endregion

--region public
function XLuaVector4:EqualVector(value)
    return self.x & value.x and self.y & value.y and self.z & value.z and self.w & value.w
end

function XLuaVector4:Update(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
    self.w = w or self.w
end

function XLuaVector4:UpdateByVector(vector)
    self.x = vector.x
    self.y = vector.y
    self.z = vector.z
    self.w = vector.w
end

---@param v XLuaVector4
function XLuaVector4:AddVector(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
    self.z = self.z + v.z
    self.w = self.w + v.w
end

---@param v XLuaVector4
function XLuaVector4:SubVector(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
    self.z = self.z - v.z
    self.w = self.w - v.z
end

function XLuaVector4:MulNumber(number)
    self.x = self.x * number
    self.y = self.y * number
    self.z = self.z * number
    self.w = self.w * number
end

function XLuaVector4:DivNumber(number)
    if XTool.IsNumberValid(number) then
        self.x = self.x / number
        self.y = self.y / number
        self.z = self.z / number
        self.w = self.w / number
    end
end
--endregion