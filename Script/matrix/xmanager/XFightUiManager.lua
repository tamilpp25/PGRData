local FunctionParams
local FunctionDictionary
local FunctionParamPath = "Client/Fight/LuaFunctionParams/LuaFunctionParams.tab"

--CS.XFight.Instance.InputControl.OnClick
--CS.XNpcOperationClickKey
--CS.XOperationClickType
XFightUiManager = XFightUiManager or {}

function XFightUiManager.Init()
	FunctionParams = XTableManager.ReadByIntKey(FunctionParamPath, XTable.XTableLuaFunctionParams, "Id")
end

--CSharpCallLua
function XFightUiManager.DoLuaFunctionWithValue(id, value, value2)
	if not FunctionParams then
		XFightUiManager.Init()
	end
	local funcName = FunctionParams[id].FunctionName
	FunctionDictionary[funcName](id, value, value2)
end

--CSharpCallLua
function XFightUiManager.DoLuaFunction(id)
	if not FunctionParams then
		XFightUiManager.Init()
	end
	local funcName = FunctionParams[id].FunctionName
	FunctionDictionary[funcName](id)
end

-----------跟随tips CSharpCallLua begin--------------
local function GetUiFightBrilliantwalk()
	local fight = CS.XFight.Instance
	if not fight then
		return
	end

	return fight.UiManager:GetUi(typeof(CS.XUiFight)):FindChildUi("UiFightBrilliantwalk")
end

local function BrilliantwalkInit(uiLuaTableKey, ...)
	local ui = GetUiFightBrilliantwalk()
	if not ui then
		return
	end

	local fight = CS.XFight.Instance
	if not fight then
		return
	end
	
	local data = {...}
	local npc = fight.NpcManager:GetNpc(data[2])
	if not npc then
		return
	end
	local func = ui.UiProxy.UiLuaTable[uiLuaTableKey]
	func(ui.UiProxy.UiLuaTable, data[1], npc, data[3], data[4], data[5], data[6], data[7], data[8], data[9])
end

function XFightUiManager.DoBrilliantwalkInitTips(id, npcId, styleType, xOffset, yOffset, endX, endY, jointName, effectName)
	BrilliantwalkInit("InitTips", id, npcId, styleType, xOffset, yOffset, endX, endY, jointName, effectName)
end

function XFightUiManager.DoBrilliantwalkInitTipsEx(id, npcId, styleType, xOffset, yOffset, endX, endY, jointName, configId)
	BrilliantwalkInit("InitTipsEx", id, npcId, styleType, xOffset, yOffset, endX, endY, jointName, configId)
end

function XFightUiManager.DoBrilliantwalkSetTipsDesc(id, textIndex, tipTextId, varIndex, value)
	local ui = GetUiFightBrilliantwalk()
	if not ui then
		return
	end
	local func = ui.UiProxy.UiLuaTable["SetTipsDesc"]
	func(ui.UiProxy.UiLuaTable, id, textIndex, tipTextId, varIndex, value)
end
-----------跟随tips CSharpCallLua end---------------

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
	end,

	["DoOpenChildUi"] = function(id, value)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		local uiName = FunctionParams[id].Params[1]

		fight.UiManager:GetUi(typeof(CS.XUiFight)):OpenChildUi(uiName, value)
	end,

	["DoCloseChildUi"] = function(id)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		local uiName = FunctionParams[id].Params[1]
		fight.UiManager:GetUi(typeof(CS.XUiFight)):CloseChildUi(uiName)
	end,

	["DoChildUiFunction"] = function(id, value)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		local uiName = FunctionParams[id].Params[1]
		local ui = fight.UiManager:GetUi(typeof(CS.XUiFight)):FindChildUi(uiName)
		if not ui then
			XLog.Error(string.format("子Ui未加载！ name:%s", uiName))
			return
		end

		local funcName = FunctionParams[id].Params[2]
		local func = ui.UiProxy.UiLuaTable[funcName]
		if not func then
			XLog.Error(string.format("不存在的子Ui方法！ name:%s", funcName))
			return
		end
		func(ui.UiProxy.UiLuaTable, value)
	end,

	["DoChildUiFunctionEx"] = function(id, value, value2)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		local uiName = FunctionParams[id].Params[1]
		local ui = fight.UiManager:GetUi(typeof(CS.XUiFight)):FindChildUi(uiName)
		if not ui then
			XLog.Error(string.format("子Ui未加载！ name:%s", uiName))
			return
		end

		local funcName = FunctionParams[id].Params[2]
		local func = ui.UiProxy.UiLuaTable[funcName]
		if not func then
			XLog.Error(string.format("不存在的子Ui方法！ name:%s", funcName))
			return
		end
		func(ui.UiProxy.UiLuaTable, value, value2)
	end,

	["HideClientScene"] = function(id, value)
		local fight = CS.XFight.Instance;
		if fight:GetClientRole().Npc.Id == value then
			CS.XRLManager.RLScene:HideRendering(true)
		end
	end,

	["HideClientSceneEx"] = function(id, value)
		CS.XRLManager.RLScene:HideRendering(value)
	end,

	["HideClientFightUi"] = function(id, value)
		local fight = CS.XFight.Instance;
		if fight:GetClientRole().Npc.Id == value then
			fight.UiManager:GetUi(typeof(CS.XUiFight)):SetActive(false)
		end
	end,
}