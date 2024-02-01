-- require("XCommon/XClass")
-- require("XCommon/XGlobalFunc")

local function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

---------------------------------------------------------------
-- @class module
-- @name Stack
-- @author liqiang
local Stack = XClass(nil, "Stack")

--[[--
得到栈内元素数量
@treturn number size 元素个数
]]
function Stack:size()
	return #self
end

--[[--
栈是否为空
@treturn boolean b true为空,否则为不空
]]
function Stack:empty()
	return (self:size() == 0)
end

--[[--
出栈
@treturn void value 返回删除的元素,空返回nil
]]
function Stack:pop()
	local tmp = self:top()
	table.remove(self)
	return tmp
end

--[[--
入栈
@tparam void value 入栈的元素
@treturn number size 入栈后元素个数
]]
function Stack:push(value)
	table.insert(self, value)
	return self:size()
end

--[[--
得到栈顶元素
@treturn void value 栈顶元素,空返回nil
]]
function Stack:top()
	local size = self:size()
	if size == 0 then
		return nil
	end
	return self[size]
end

---@class XArithmetic
local XArithmetic = XClass(nil, "XArithmetic")

local defaultOperatorLevel = {
	["+"] = 0,
	["-"] = 0,
	["("] = 10,
	["*"] = 1,
	["/"] = 1,
	[")"] = 0,
	["<"] = 1,
	[">"] = 1,
	["^"] = 2,
}

local defaultOperatorPattern = {
	["%+"] = "+",
	["%-"] = "-",
	["%("] = "(",
	["%*"] = "*",
	["/"] = "/",
	["%)"] = ")",
	["<"] = "<",
	[">"] = ">",
	["%^"] = "^",
}

local charsReg = "^%a+%d*$"

function XArithmetic:Ctor()
	self.OperatorLevel = defaultOperatorLevel
	self.OperatorPattern = defaultOperatorPattern
	self.GetVariableDelegate = nil
end

function XArithmetic:SetTextValueHandler(handle)
	self.GetVariableDelegate = handle
end

function XArithmetic:Calculate(expression)
	local rpnExperssion = self:ConvertToRPN(self:InsertBlank(expression))
	return self:GetResultByExperssion(rpnExperssion)
end

function XArithmetic:GetValue(left, right, operator)
	if "+" == operator then
		return left + right
	elseif "-" == operator then
		return left - right
	elseif "*" == operator then
		return left * right
	elseif "/" == operator then
		return left / right
	elseif "<" == operator then
		return math.min(left, right)
	elseif ">" == operator then
		return math.max(left, right)
	elseif "^" == operator then
		return math.pow(left, right)
	end
	XLog.Warning("XArithmetic:GetValue error! operator: %s", operator)
	return 0
end

function XArithmetic:GetResultByExperssion(source)
	local operatorLevel = self.OperatorLevel
	local stack = Stack.New()
	local list = split(source, " ")
	for i, current in ipairs(list) do
		if tonumber(current) then
            stack:push(tonumber(current))
		elseif string.match(current, charsReg) then
			stack:push(current)
        elseif operatorLevel[current] then
			local right = self:GetValueByText(stack:pop())
			local left = self:GetValueByText(stack:pop())        	
            stack:push(self:GetValue(left, right, string.sub(current, 1, 1)))
        end
    end
	return stack:pop(), #stack
end

function XArithmetic:GetValueByText(text)
	if self.GetVariableDelegate then
		return self.GetVariableDelegate(text)
	end
	if tonumber(text) then
		return tonumber(text)
	end
	XLog.Warning("XArithmetic.GetVariableDelegate == nil")
	return 1
end

function XArithmetic:ConvertToRPN(source)
	local operatorLevel = self.OperatorLevel
	local result = ""
    local stack = Stack.New()
    local list = split(source, " ")
    for i, current in ipairs(list) do
    	-- log("current %s", current)
        if tonumber(current) then
			result = result..current.." "
		elseif string.match(current, charsReg) then
			result = result..current.." "
		elseif operatorLevel[current] then
			if #stack > 0 then
				local prev = stack:top()
				-- log("prev %s", prev)
				if prev == "(" then
					stack:push(current)
				elseif current == "(" then
					stack:push(current)
				elseif current == ")" then
					while #stack > 0 and stack:top() ~= "(" do
						result = result..stack:pop().." "
					end
					--Pop the "("
					if #stack > 0 and stack:top() == "(" then
						stack:pop()
					end
				elseif operatorLevel[current] <= operatorLevel[prev] then
					while #stack > 0 do
						local top = stack:pop()
						if top ~= "(" and top ~= ")" and operatorLevel[current] <= operatorLevel[top] then
							result = result..top.." "
						else
							-- break
							stack:push(top)
							break
						end
					end
					stack:push(current)
				else
					stack:push(current)
				end
			else
				stack:push(current)
			end
		end

		local text = ""
		local i = 1
		while stack[i] ~= nil do
			text = text.." "..stack[i]
			i = i + 1
		end
		-- log("                   "..text)
	end
	if #stack > 0 then
		while #stack > 0 do
			local top = stack:pop()
			if top ~= "(" and top ~= ")" then
				result = result..top.." "
			end
		end
	end
	-- log(result)
	return result
end

function XArithmetic:InsertBlank(source)
	for p, v in pairs(self.OperatorPattern) do
		source = string.gsub(source, p, " "..v.." ")
	end
	return source
end

return XArithmetic

-- local function Test(expression, result)
-- 	local realyResult = XArithmetic:Calculate(expression);
-- 	XLog.Warning(realyResult, result)
-- 	if realyResult ~= result then
-- 		XLog.Warning("Formula.Calculate(\"%s\") != %d, realy result = %d", expression, result, realyResult)
-- 	else
-- 		XLog.Debug("XArithmetic test ok")
-- 	end 
-- end

-- XLog.Warning("===========asdasd")
-- Test("4-2-1+3", 4)
-- Test("1+1*(2+1)-3.8/2 + 1 * (2+1)", 5.1)
-- Test("1000+0+0+0+0-0-0-0+0-100-0-0-0", 900)
-- Test("1000-0-100", 900)
-- Test("0-2*(3+4*6/5)", -15.6)