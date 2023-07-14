local XArithmetic = require("XFormula/XArithmetic")

local XFormula = XClass(nil, "XFormula")

function XFormula:Ctor()
	self.arithmetic = nil
end

function XFormula:GetResult(text)
	if self.arithmetic == nil then
		self.arithmetic = XArithmetic.New()
	end
	return self.arithmetic:Calculate(text)
end

return XFormula