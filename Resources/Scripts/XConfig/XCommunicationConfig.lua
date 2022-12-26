XCommunicationConfig = XCommunicationConfig or {}

local TABLE_FUNCTION_COMMUNICATION_PATH = "Share/Functional/FunctionalCommunication.tab"
local TABLE_FUNCTION_FESTIVAL_COMMUNICATION_PATH = "Share/Functional/FunctionalFestivalCommunication.tab"
local TABLE_FUNCTION_INITIATIVE_COMMUNICATION_PATH = "Share/Functional/FunctionalInitiativeCommunication.tab"
local TABLE_FUNCTION_INITIATIVE_CONTENTS_PATH = "Client/Functional/FunctionalContents.tab"

local FunctionCommunicationConfig = {}
local FunctionFestivalCommunicationConfig = {}
local FunctionInitiativeCommunicationConfig = {}
local FunctionFestivalCommunicationDic = {}

local FunctionalContentsConfig = {}
local FunctionalContentsGroupIdDic = {}

XCommunicationConfig.ComminictionType = {
    NormalType = 1,
    OptionType = 2,
}

function XCommunicationConfig.Init()
    FunctionCommunicationConfig = XTableManager.ReadByIntKey(TABLE_FUNCTION_COMMUNICATION_PATH, XTable.XTableFunctionalCommunication, "Id")
    FunctionFestivalCommunicationConfig = XTableManager.ReadByIntKey(TABLE_FUNCTION_FESTIVAL_COMMUNICATION_PATH, XTable.XTableFunctionalFestivalCommunication, "Id")
    FunctionInitiativeCommunicationConfig = XTableManager.ReadByIntKey(TABLE_FUNCTION_INITIATIVE_COMMUNICATION_PATH, XTable.XTableFunctionalCommunication, "Id")
    FunctionalContentsConfig = XTableManager.ReadByIntKey(TABLE_FUNCTION_INITIATIVE_CONTENTS_PATH, XTable.XTableFunctionalContents, "Id")
    XCommunicationConfig.SetFunctionFestivalCommunicationDic()
    XCommunicationConfig.InitFunctionalContentsGroup()
end

function XCommunicationConfig.GetFunctionCommunicationConfig()
    return FunctionCommunicationConfig
end

function XCommunicationConfig.GetFunctionFestivalCommunicationConfig()
    return FunctionFestivalCommunicationConfig
end

function XCommunicationConfig.GetFunctionFestivalCommunicationDicByType(type)
    return FunctionFestivalCommunicationDic[type]
end

function XCommunicationConfig.GetFunctionInitiativeCommunicationConfig()
    return FunctionInitiativeCommunicationConfig
end

function XCommunicationConfig.GetFunctionInitiativeCommunicationConfigById(commuId)
    return FunctionInitiativeCommunicationConfig[commuId]
end

function XCommunicationConfig.SetFunctionFestivalCommunicationDic()
    for _, communication in pairs(FunctionFestivalCommunicationConfig) do
        local functionFestivalCommunicationType = FunctionFestivalCommunicationDic[communication.Type]
        if not functionFestivalCommunicationType then
            functionFestivalCommunicationType = {}
            FunctionFestivalCommunicationDic[communication.Type] = functionFestivalCommunicationType
        end
        table.insert(functionFestivalCommunicationType, communication)
    end
end

function XCommunicationConfig.InitFunctionalContentsGroup()
    for _, communication in pairs(FunctionalContentsConfig) do
        local functionalComList = FunctionalContentsGroupIdDic[communication.GroupId]
        if not functionalComList then
            functionalComList = {}
            FunctionalContentsGroupIdDic[communication.GroupId] = functionalComList
        end

        if communication.Type == XCommunicationConfig.ComminictionType.NormalType and #communication.OptionTitle > 0 then
            XLog.Error("XCommunicationConfig.InitFunctionalContentsGroup".."配置表项"..TABLE_FUNCTION_INITIATIVE_CONTENTS_PATH.."不应该配置按钮,ID:"..tostring(communication.Id))
        end
            
        table.insert(functionalComList, communication)
    end
    for _, communicationList in pairs(FunctionalContentsGroupIdDic) do
        table.sort(communicationList,function(a, b)
            return a.Id < b.Id
        end)
    end
end

function XCommunicationConfig.GetFunctionalContentsInfoById(id)
    if not FunctionalContentsConfig[id] then
        XLog.ErrorTableDataNotFound("XCommunicationConfig.GetFunctionalContentsInfoById", "配置表项", TABLE_FUNCTION_INITIATIVE_CONTENTS_PATH, "Id", tostring(id))
    end
    return FunctionalContentsConfig[id]
end

function XCommunicationConfig.GetFunctionalContentsGroupFirstInfoByGroupId(groupId)
    if not FunctionalContentsGroupIdDic[groupId] or not FunctionalContentsGroupIdDic[groupId][1] then
        XLog.ErrorTableDataNotFound("XCommunicationConfig.GetFunctionalContentsGroupListByGroupId", "配置表项", TABLE_FUNCTION_INITIATIVE_CONTENTS_PATH, "GroupId", tostring(groupId))
    end
    return FunctionalContentsGroupIdDic[groupId][1]
end



