local XDlcMultiplayerConfigModel = require("XModule/XDlcMultiplayer/XDlcMultiplayerConfigModel")

---@class XDlcMultiplayerModel : XDlcMultiplayerConfigModel
local XDlcMultiplayerModel = XClass(XDlcMultiplayerConfigModel, "XDlcMultiplayerModel")

function XDlcMultiplayerModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()
    self._ActivityPrivateConfigMap = {}
    self._PrivateConfigRef = {}
end

function XDlcMultiplayerModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XDlcMultiplayerModel:ResetAll()
    --这里执行重登数据清理
    self._ActivityPrivateConfigMap = {}
    self._PrivateConfigRef = {}
end

function XDlcMultiplayerModel:RegisterActivityPrivateConfig(moduleId, tableName)
    self._ActivityPrivateConfigMap[moduleId] = self._ActivityPrivateConfigMap[moduleId] or {}
    self._ActivityPrivateConfigMap[moduleId][tableName] = tableName
end

function XDlcMultiplayerModel:LoadActivityPrivateConfig(moduleId)
    if not XTool.IsTableEmpty(self._ActivityPrivateConfigMap[moduleId]) then
        for _, tableName in pairs(self._ActivityPrivateConfigMap[moduleId]) do
            self._PrivateConfigRef[tableName] = self._PrivateConfigRef[tableName] or 0
            self._PrivateConfigRef[tableName] = self._PrivateConfigRef[tableName] + 1
        end
    end
end

function XDlcMultiplayerModel:ClearActivityPrivateConfig(moduleId)
    local tableKey = self:_GetTableKey()

    if not XTool.IsTableEmpty(self._ActivityPrivateConfigMap[moduleId]) then
        for _, tableName in pairs(self._ActivityPrivateConfigMap[moduleId]) do
            if XTool.IsNumberValid(self._PrivateConfigRef[tableName]) then
                self._PrivateConfigRef[tableName] = self._PrivateConfigRef[tableName] - 1

                if self._PrivateConfigRef[tableName] == 0 then
                    local path = self._ConfigUtil:GetPathByTableKey(tableKey[tableName])

                    if path then
                        self._ConfigUtil:Clear(path)
                    end
                end
            end
        end
    end
end

return XDlcMultiplayerModel