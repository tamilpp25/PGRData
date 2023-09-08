local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
local CsLog = CS.XLog
local CsRemoteConfig = CS.XRemoteConfig

local DOCUMENT_VERSION = "DOCUMENT_VERSION"
local LAUNCH_MODULE_VERSION = "LAUNCH_MODULE_VERSION"

--标注已预下载完成的字段
local PreloadCompleteKey = "__kuro_preload_complete__"
--标注预下载index的版本号
local PreloadIndexKey = "__kuro_preload_index__"
--预下载分包的id
local PreloadDlcIdsKey = "__kuro_preload_dlc_ids__"
--标记红点版本号
local PreloadRedPointKey = "__kuro_preload_red_point__"
local EmptyVersion = "0.0.0"

local ForceDeleteTempFile = -2

---@class XPreloadModel : XModel
local XPreloadModel = XClass(XModel, "XPreloadModel")
function XPreloadModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._PreloadEnable = false --是否开启预下载
    self._PreloadBaseVersion = EmptyVersion --预下载的大版本号
    self._PreloadVersion = EmptyVersion --预下载版本号
    self._PreloadSha = "" --预下载index文件sha1值
    self._PreloadSize = ForceDeleteTempFile

    self._LocalDocVersion = nil --documetn的版本号
    self._LocalPreloadCompleteVersion = nil --本地已经预下载完成的版本号
    self._LocalPreloadIndexVersion = nil --本地已经下载的预下载index版本号
    self._LocalPreloadDlcIds = nil --记录的dlc版本
    self._LocalPreloadRedPoint = nil --记录当前红点的版本号
end

function XPreloadModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XPreloadModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
end

----------public start----------
function XPreloadModel:InitRemoteConfig(preloadEnable, preloadBaseVersion, preloadVersion, preloadSha, preloadSize)
    self._PreloadEnable = preloadEnable == 1
    self._PreloadBaseVersion = preloadBaseVersion
    self._PreloadVersion = preloadVersion
    self._PreloadSha = preloadSha
    self._PreloadSize = preloadSize

    CsLog.Debug(string.format("XPreloadModel:InitRemoteConfig PreloadEnable: %s, PreloadBaseVersion: %s, PreloadVersion: %s, PreloadSha: %s, PreloadSize: %s", self._PreloadEnable, self._PreloadBaseVersion, self._PreloadVersion, self._PreloadSha, self._PreloadSize))
end

function XPreloadModel:InitLocalConfig()
    self._LocalDocVersion = CsRemoteConfig.DocumentVersion
    self._LocalPreloadCompleteVersion = CSPlayerPrefs.GetString(PreloadCompleteKey, EmptyVersion)
    self._LocalPreloadIndexVersion = CSPlayerPrefs.GetString(PreloadIndexKey, EmptyVersion)
    self._LocalPreloadRedPoint = EmptyVersion -- CSPlayerPrefs.GetString(PreloadRedPointKey, EmptyVersion)
    local dlcIdsStr = CSPlayerPrefs.GetString(PreloadDlcIdsKey, '')
    if string.IsNilOrEmpty(dlcIdsStr) then
        self._LocalPreloadDlcIds = nil
    else
        self._LocalPreloadDlcIds = {}
        local ids = string.Split(dlcIdsStr)
        for i = 1, #ids do
            local id = tonumber(ids[i])
            self._LocalPreloadDlcIds[id] = true
        end
    end
    CsLog.Debug(string.format("XPreloadModel:InitLocalConfig LocalPreloadCompleteVersion: %s, LocalPreloadIndexVersion: %s, LocalPreloadRedPoint: %s", self._LocalPreloadCompleteVersion, self._LocalPreloadIndexVersion, self._LocalPreloadRedPoint))
    CsLog.Debug("XPreloadModel:InitLocalConfig LocalPreloadDlcIds: " .. XLog.Dump(self._LocalPreloadDlcIds))
end

function XPreloadModel:GetPreloadEnable()
    return self._PreloadEnable
end

function XPreloadModel:GetPreloadBaseVersion()
    return self._PreloadBaseVersion
end

function XPreloadModel:GetPreloadVersion()
    return self._PreloadVersion
end

function XPreloadModel:GetPreloadSha()
    return self._PreloadSha
end

function XPreloadModel:GetPreloadSize()
    return self._PreloadSize
end

function XPreloadModel:GetLocalDocVersion()
    return self._LocalDocVersion
end

function XPreloadModel:GetLocalPreloadCompleteVersion()
    return self._LocalPreloadCompleteVersion
end

function XPreloadModel:GetLocalPreloadIndexVersion()
    return self._LocalPreloadIndexVersion
end

function XPreloadModel:GetLocalPreloadRedPoint()
    return self._LocalPreloadRedPoint
end

---是否有过预下载记录
function XPreloadModel:HasLocalPreloadIndexVersion()
    return self._LocalPreloadIndexVersion ~= EmptyVersion
end

function XPreloadModel:GetLocalPreloadDlcIds()
    return self._LocalPreloadDlcIds
end

function XPreloadModel:SetLocalPreloadDlcIds(val)
    self._LocalPreloadDlcIds = val
end

---预下载完成, 保存当前预下载版本号
function XPreloadModel:SavePreloadCompleteVersion()
    self._LocalPreloadCompleteVersion = self._PreloadVersion
    CSPlayerPrefs.SetString(PreloadCompleteKey, self._PreloadVersion)
    CSPlayerPrefs.Save()
end

---预下载index版本号保存
function XPreloadModel:SavePreloadVersion()
    self._LocalPreloadIndexVersion = self._PreloadVersion
    CSPlayerPrefs.SetString(PreloadIndexKey, self._PreloadVersion)
    CSPlayerPrefs.Save()
end

---保存dlc分组id
function XPreloadModel:SavePreloadDlcIds()
    if self._LocalPreloadDlcIds then
        local dlcIds = ""
        local count = 0
        for id, _ in pairs(self._LocalPreloadDlcIds) do
            if count == 0 then
                dlcIds = tostring(id)
            else
                dlcIds = dlcIds .. "|" .. tostring(id)
            end
            count = count + 1
        end
        CSPlayerPrefs.SetString(PreloadDlcIdsKey, dlcIds)
        CSPlayerPrefs.Save()
    end
end

function XPreloadModel:SavePreloadRedPoint()
    self._LocalPreloadRedPoint = self._PreloadVersion --当此登录有效
    --CSPlayerPrefs.SetString(PreloadRedPointKey, self._LocalPreloadRedPoint)
    --CSPlayerPrefs.Save()
end


-----清理本地的preLoadindex版本号
--function XPreloadModel:ClearPreloadVersion()
--    self._LocalPreloadDlcIds = nil
--    self._LocalPreloadIndexVersion = EmptyVersion
--    CSPlayerPrefs.DeleteKey(PreloadDlcIdsKey)
--    CSPlayerPrefs.DeleteKey(PreloadIndexKey)
--    CSPlayerPrefs.Save()
--end

---清理所有预下载记录, 包括预下载完成版本号+预下载index版本号
function XPreloadModel:ClearPreloadAll()
    self._LocalPreloadCompleteVersion = EmptyVersion
    self._LocalPreloadIndexVersion = EmptyVersion
    self._LocalPreloadDlcIds = nil
    CSPlayerPrefs.DeleteKey(PreloadCompleteKey)
    CSPlayerPrefs.DeleteKey(PreloadIndexKey)
    CSPlayerPrefs.DeleteKey(PreloadDlcIdsKey)
    CSPlayerPrefs.Save()
    CsLog.Debug("[Preload] 清除所有预下载记录")
end



----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XPreloadModel