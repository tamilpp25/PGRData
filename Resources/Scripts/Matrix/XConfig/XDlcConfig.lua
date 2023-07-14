local TABLE_DLC_DESC_PATH = "Client/DlcRes/DlcDesc.tab"
local TABLE_DLC_STAGE_PATH = "Client/DlcRes/DlcStage.tab"
local TABLE_DLC_FUNC_PATH = "Client/DlcRes/DlcFunc.tab"

local DlcDescConfig = {}
local DlcStageConfig = {}
local DlcFuncConfig = {}

local StageToDlcIdDic = {}
local FuncToDlcIdDic = {}


XDlcConfig = XDlcConfig or {}

function XDlcConfig.Init()
	--XLog.Error("XDlcConfig init")
    DlcDescConfig = XTableManager.ReadByIntKey(TABLE_DLC_DESC_PATH, XTable.XTableDlcDesc, "DlcId")
    DlcStageConfig = XTableManager.ReadByIntKey(TABLE_DLC_STAGE_PATH, XTable.XTableDlcStage, "DlcId")
    DlcFuncConfig = XTableManager.ReadByIntKey(TABLE_DLC_FUNC_PATH, XTable.XTableDlcFunc, "DlcId")

    for k,v in pairs(DlcStageConfig) do
    	--XLog.Error("DlcStageConfig["..k.."] = " ..  v)
    	for k2,v2 in ipairs(v.StageIds) do
    		StageToDlcIdDic[v2] = k
    		--XLog.Error("StageToDlcIdDic["..v2.."] = " ..  k)
    	end
    end

    for k,v in pairs(DlcFuncConfig) do
    	--XLog.Error("DlcFuncConfig["..k.."] = " ..  v)
    	for k2,v2 in ipairs(v.FuncIds) do
    		FuncToDlcIdDic[v2] = k
    		--XLog.Error("FuncToDlcIdDic["..v2.."] = " ..  k)
    	end
    end
end

function XDlcConfig.StageToDlcId(stageId)
	return StageToDlcIdDic[stageId]
end

function XDlcConfig.FuncToDlcId(funcId)
	return FuncToDlcIdDic[funcId]
end

XDlcConfig.DlcDescConfig = DlcDescConfig
XDlcConfig.StageToDlcIdDic = StageToDlcIdDic
XDlcConfig.FuncToDlcIdDic = FuncToDlcIdDic