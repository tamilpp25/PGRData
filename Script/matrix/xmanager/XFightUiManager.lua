local FunctionParams
local FunctionDictionary
local FunctionParamPath = "Client/Fight/LuaFunctionParams/LuaFunctionParams.tab";

--CS.XFight.Instance.InputControl.OnClick
--CS.XNpcOperationClickKey
--CS.XNpcOperationClickType
XFightUiManager = XFightUiManager or {}
CS.XUiFightParkour.SlideThreshold = 0.05

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

	["ClearRLManager"] = function(id, value)
		CS.XFight.Instance.RLManager:Clear();
	end,

	["ClearSLivBallEffect"] = function(id, value)
		-- 1.25版本已去除 同韩服
	end,
	
	["PlayKalieFashionEndFightCv"] = function(id)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		-- 对应ModelId为R3KalieninaMd019101
		if fight:GetClientRole().Npc.RLNpc.ModelHash == 536048250 then
			CS.XAudioManager.PlayCv(107113);
		else
			CS.XAudioManager.PlayCv(107170);
		end
	end,

	["LoadResource"] = function(id)
		local fight = CS.XFight.Instance
		if not fight then
			return
		end

		local resource = CS.XResourceManager.Load(FunctionParams[id].Params[1]);
		fight:AddPool(resource.Url, resource.Asset);
	end,
}