local FunctionParams
local FunctionDictionary
local FunctionParamPath = "Client/Fight/LuaFunctionParams/LuaFunctionParams.tab";

--if not CS.XFight.Instance then
--CS.XFight.Instance.InputControl.OnOperationClick
--CS.XNpcOperationClickKey
--CS.XNpcOperationClickType
XFightUiManager = XFightUiManager or {}

function XFightUiManager.Init()
	FunctionParams = XTableManager.ReadByIntKey(FunctionParamPath, XTable.XTableLuaFunctionParams, "Id")
end
--CSharpCallLua
function XFightUiManager.DoLuaFunctionWithValue(id,value)
	if not FunctionParams then
		XFightUiManager.Init()
	end
	local funcName = FunctionParams[id].FunctionName
	FunctionDictionary[funcName](id,value)
end
--CSharpCallLua
function XFightUiManager.DoLuaFunction(id)
	if not FunctionParams then
		XFightUiManager.Init()
	end
	local funcName = FunctionParams[id].FunctionName
	FunctionDictionary[funcName](id)
end

FunctionDictionary = {
	["DoNieRoleDeath"] = function(id,value)
		XLog.Debug("DoNieRoleDeath", id, tostring(value))
		if XLuaUiManager.IsUiShow("UiNieREasterEgg") then
			XLog.Error("界面处于展示状态，请检查行为树节点！！！")
		    return 
		end
		--FunctionParams[id].Params
		if value < 3 then
			local isFirstDeath = value == 1
		    XLuaUiManager.Open("UiNieREasterEgg", false , isFirstDeath)
		else
			local lastName, nowName = XDataCenter.NieRManager.GetNieREasrerEggPlayerName()
			XLuaUiManager.Open("UiFightNieRTips",lastName, nowName)
		end
	end
}