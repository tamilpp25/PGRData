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

local function GetChildUiFight(uiName)
	local fight = CS.XFight.Instance
	if not fight then
		return
	end

	local ui = fight.UiManager:GetUi(typeof(CS.XUiFight)):FindChildUi(uiName)
	if not ui then
		XLog.Error(string.format("子Ui未加载！ name:%s", uiName))
		return
	end
	
	return ui
end

local function OpenChildUiFight(uiName, value)
	local fight = CS.XFight.Instance
	if not fight then
		return
	end

	local uiFight = fight.UiManager:GetUi(typeof(CS.XUiFight))
	if not uiFight.GameObject or not uiFight.GameObject.activeInHierarchy then
		return
	end
	uiFight:OpenChildUi(uiName, value)
end

local function GetChildUiFightAutoOpen(uiName)
	local ui = GetChildUiFight(uiName)
	if not ui then
		return
	end

	if not XLuaUiManager.IsUiShow(uiName) then
		OpenChildUiFight(uiName)
	end
	return ui
end

local function DoUiFunc(uiName, funcName, ...)
	local fight = CS.XFight.Instance
	if not fight then
		return
	end

	local ui = GetChildUiFightAutoOpen(uiName)
	if not ui then
		return
	end

	local func = ui.UiProxy.UiLuaTable[funcName]
	if not func then
		XLog.Error(string.format("不存在的子Ui方法！ name:%s", funcName))
		return
	end
	
	func(ui.UiProxy.UiLuaTable, ...)
end

-----------关卡自定义按钮列表 CSharpCallLua begin--------------
function XFightUiManager.DoSetCommonInterBtnList(id, key, icon, text, order, isDisable)
	DoUiFunc("UiFightCommonInterBtnList", "SetCommonInterBtn", id, key, icon, text, order, isDisable)
end

function XFightUiManager.DoSetCommonInterBtnListFollowNpc(npcId, jointName, offsetX, offsetY)
	local fight = CS.XFight.Instance
	if not fight then
		return
	end
	
	local npc = fight.NpcManager:GetNpc(npcId)
	if not npc then
		return
	end
	DoUiFunc("UiFightCommonInterBtnList", "SetFollowNpc", npc, jointName, offsetX, offsetY)
end
-----------关卡自定义按钮列表 CSharpCallLua end----------------

-----------跟随tips CSharpCallLua begin--------------
local function BrilliantwalkInit(uiLuaTableKey, ...)
	local ui = GetChildUiFight("UiFightBrilliantwalk")
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
	local ui = GetChildUiFight("UiFightBrilliantwalk")
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
		OpenChildUiFight(FunctionParams[id].Params[1], value)
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

	["DoChildUiFunctionAutoOpen"] = function(id, value)
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

		if not XLuaUiManager.IsUiShow(uiName) then
			OpenChildUiFight(uiName)
		end

		local funcName = FunctionParams[id].Params[2]
		local func = ui.UiProxy.UiLuaTable[funcName]
		if not func then
			XLog.Error(string.format("不存在的子Ui方法！ name:%s", funcName))
			return
		end
		func(ui.UiProxy.UiLuaTable, value)
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