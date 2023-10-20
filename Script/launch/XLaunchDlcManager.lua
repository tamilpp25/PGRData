local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
local KEY_GAME_DOWNLOAD_RECORD = "KEY_GAME_DOWNLOAD_RECORD"
local KEY_LAUNCH_DOWNLOAD_RECORD = "KEY_LAUNCH_DOWNLOAD_RECORD"
local KEY_DOWNLOADED = "KEY_DOWNLOADED"

local DLC_NEED_DOWNLOAD_KEY = "DLC_NEED_DOWNLOAD_KEY"
local HAS_SELECT_DOWNLOAD_PART_KEY = "HAS_SELECT_DOWNLOAD_PART_KEY"
local HAS_SELECT_ALL_DOWNLOAD_KEY = "HAS_SELECT_ALL_DOWNLOAD_KEY"
local IS_SELECT_WIFI_AUTO_DOWNLOAD = "IS_SELECT_WIFI_AUTO_DOWNLOAD" --是否选中wifi自动下载
local CsApplication = CS.XApplication
local CsLog = CS.XLog

---@class XLaunchDlcManager 分包资源-启动管理类
local M = {}
local XLaunchDlcManager = M

local DlcIdList = {}
local ApplicationIndexTable = {}

local GameDownloadRecord = {} -- 游戏内已选择的下载
local LaunchDownloadRecord = {} -- 热更时已选择的下载
local DownloadedDic = {} -- 已下载

local DlcIndexInfo = {} 

local NeedLaunchTest = CS.XResourceManager.NeedLaunchTest
local IsInGame = false

local DLC_BASE_INDEX = 0 -- 基础资源包索引
local DLC_COMMON_INDEX = -1 -- 通用资源包索引

local STATE_DEFAULT = 0 -- 未开始下载
local STATE_START = 1 -- 已开始（选择）下载

local DownloadedMap = {}
local PathModule = nil
local FileModule = nil
local VersionModule = nil

local IsInit = false
--====启动逻辑接口 begin=====
M.Init = function(dlcIndexTable)
    if IsInit then
        return
    end
    IsInit = true

    for dlcId, info in pairs(dlcIndexTable) do
        table.insert(DlcIdList, dlcId)
    end

    for i, dlcId in pairs(DlcIdList) do
        LaunchDownloadRecord[dlcId] = UnityPlayerPrefs.GetInt(KEY_LAUNCH_DOWNLOAD_RECORD .. dlcId, STATE_DEFAULT)
        --这个字段只有在游戏内读取，避免下载时一次下载多个，不用存在本地
        --GameDownloadRecord[dlcId] = UnityPlayerPrefs.GetInt(KEY_GAME_DOWNLOAD_RECORD .. dlcId, STATE_DEFAULT)

        local downloadState = UnityPlayerPrefs.GetInt(KEY_DOWNLOADED .. dlcId, STATE_DEFAULT)
        DownloadedDic[dlcId] = downloadState
    end
end

M.SetDownloadedMap = function(downloadedMap)
    -- local logTab = {}
    -- local count = 0
    -- for dlcId, need in pairs(downloadedMap) do
    --     count = count + 1
    --     table.insert(logTab, dlcId .. ":" .. tostring(need))
    -- end
    -- CsLog.Debug("[DLC] downloadedMap: count:" .. count ..", " .. tostring(table.concat(logTab, ";")))
    CsLog.Debug("[DLC] downloadedMap next:" .. tostring((next(downloadedMap))))
    DownloadedMap = downloadedMap
end

M.AddDownloadedMap = function(updateTable)
    local count = 0
    for name, info in pairs(updateTable) do
        if not DownloadedMap[name] then
            count = count + 1
        end
        DownloadedMap[name] = true
    end
    CsLog.Debug("[DLC] AddDownloadedMap, Count: " .. count)
end

-- 目前仅游戏内以Traditional下载方式时调用
M.SetDownloadedFile = function(name, downloaded)
    DownloadedMap[name] = downloaded
    -- CsLog.Debug("[DLC] SetDownloadedFile, downloaded:"..tostring(downloaded) .. ", file name " .. name)
end

M.SetDlcIndexInfo = function(dlcId, dlcIndexInfo) -- 记录size后即可丢弃
    DlcIndexInfo[dlcId] = dlcIndexInfo
end

M.IsNameDownloaded = function(name)
    return DownloadedMap[name]
end

-- 是否需要下载
M.CheckNeedDownload = function(dlcId, needShowSelect)
    if LaunchDownloadRecord[dlcId] == STATE_START then
        if needShowSelect then
            return false
        end
        return true
    end
    if IsInGame then
        return GameDownloadRecord[dlcId] == STATE_START
    end
    return false
end

-- 修正下载记录
M.SetDlcDownloadedRecord = function(dlcId, downloaded)
    DownloadedDic[dlcId] = downloaded and STATE_START or STATE_DEFAULT
    UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. dlcId, downloaded and STATE_START or STATE_DEFAULT)
end

-- 修正下载记录(仅本次)
M.FixDownloadedDlc = function(dlcId, downloaded)
    -- print(".. FixDownloadedDlc dlcId:" .. dlcId .. ", downloaded:" .. tostring(downloaded) .. "\n" .. debug.traceback())
    DownloadedDic[dlcId] = downloaded and STATE_START or STATE_DEFAULT
end

M.DoneDownloadInLaunch = function(dlcIds)
    for dlcId, v in pairs(LaunchDownloadRecord) do
        if v == STATE_START then
            DownloadedDic[dlcId] = STATE_START
            UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. dlcId, STATE_START)
        end
    end
end

-- 游戏内选择的dlc均设为“已下载”
M.DoneDownloadInGame = function()
    for dlcId, v in pairs(GameDownloadRecord) do
        if v == STATE_START then
            DownloadedDic[dlcId] = STATE_START
            UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. dlcId, STATE_START)
        end
    end
end

M.HasDownloadedDlc = function(id)
    -- print("?? HasDownloadedDlc id:" .. id .. ", DownloadedDic[id]:" .. tostring(DownloadedDic[id]) .. "\n" .. debug.traceback())
    return DownloadedDic[id] == STATE_START
end

M.SetAllLaunchDownloadRecord = function()
    for i, dlcId in pairs(DlcIdList) do
        M.SetLaunchDownloadRecord(dlcId)
    end
end

-- 热更时选择下载策略
M.NeedShowSelect = function(appVer)
    if NeedLaunchTest then
        return true
    end
    if CS.XRemoteConfig.LaunchSelectType == nil or CS.XRemoteConfig.LaunchSelectType == 0 then
        return false
    end
    --return UnityPlayerPrefs.GetInt(HAS_SELECT_DOWNLOAD_PART_KEY .. appVer, STATE_DEFAULT) == STATE_DEFAULT
    --调整为只有新包才会弹
    return UnityPlayerPrefs.GetInt(HAS_SELECT_DOWNLOAD_PART_KEY, STATE_DEFAULT) == STATE_DEFAULT
end

M.DoneSelect = function(appVer)
    --UnityPlayerPrefs.SetInt(HAS_SELECT_DOWNLOAD_PART_KEY .. appVer, STATE_START)
    --调整为只有新包才会弹
    UnityPlayerPrefs.SetInt(HAS_SELECT_DOWNLOAD_PART_KEY, STATE_START)
    UnityPlayerPrefs.Save()
end

--- 是否是整包下载
---@return boolean
--------------------------
M.IsFullDownload = function()
    local state = UnityPlayerPrefs.GetInt(HAS_SELECT_ALL_DOWNLOAD_KEY, STATE_DEFAULT)
    return state == STATE_START
end

M.SetIsFullDownload = function(isFullDownload) 
    UnityPlayerPrefs.SetInt(HAS_SELECT_ALL_DOWNLOAD_KEY, isFullDownload and STATE_START or STATE_DEFAULT)
end

M.SetLaunchDownloadRecord = function (id)
    local state = STATE_START
    CsLog.Debug("SetLaunchDownloadRecord:" .. tostring(id))
    LaunchDownloadRecord[id] = state
    UnityPlayerPrefs.SetInt(KEY_LAUNCH_DOWNLOAD_RECORD .. id, state)
end
--====启动逻辑接口 end=====


--======== 游戏业务层接口 begin ====

M.SetGameDownloadRecord = function (id)
    GameDownloadRecord[id] = STATE_START
    --UnityPlayerPrefs.SetInt(KEY_GAME_DOWNLOAD_RECORD .. id, STATE_START)
end

--- 清除需要下载的DlcId标记(仅仅本次）
--------------------------
M.ClearGameDownloadRecord = function()
    GameDownloadRecord = {}
end

M.CheckGameNeedDownload = function(dlcId)
    return not M.HasDownloadedDlc(dlcId)
end
local FileModule = nil
local VersionModule = nil

M.GetPathModule = function()
    if not PathModule then
        PathModule = require("XLaunchAppPathModule")
    end
    return PathModule
end


---@return XLaunchFileModule
--------------------------
M.GetFileModule = function()
    if not FileModule then
        local FileModuleCreator = require("XLaunchFileModule")
        FileModule = FileModuleCreator()
    end
    return FileModule
end

M.GetVersionModule = function()
    if not VersionModule then
        VersionModule = require("XLaunchAppVersionModule")
    end
    return VersionModule
end

M.DoDownloadDlc = function(progressCb, doneCb, exitCb)
    local PathModule = M.GetPathModule()
    local DocFileModule = M.GetFileModule()
    local VersionModule = M.GetVersionModule()
    DocFileModule.SetIsInGame(IsInGame)
    XMVCA.XSubPackage:SetFileModule(DocFileModule)
    DocFileModule.Check(RES_FILE_TYPE.MATRIX_FILE, PathModule, VersionModule, doneCb, progressCb, exitCb)
end

-- 游戏内调用下载
M.DownloadDlc = function (ids, processCb, doneCb, exitCb)
    IsInGame = true
    --清除一下记录
    M.ClearGameDownloadRecord()
    --标记本次需要下载DLCId
    for _, id in pairs(ids) do
        M.SetGameDownloadRecord(id)
    end
    --CsLog.Error("Prepare Download" .. table.concat(ids, ", "))
   -- todo 下载模块，无需界面
   -- CS.XUiManager.Instance:OpenWithCallback("UiLaunch", function()
        M.DoDownloadDlc(processCb, 
            function(isPause)
                XLuaUiManager.Close("UiLaunch")
                if doneCb then
                    doneCb(isPause)
                end
            end, 
            function()
                XLuaUiManager.Close("UiLaunch")
                if exitCb then exitCb() end
            end)
    -- end)
end

M.GetIndexInfo = function()
    return DlcIndexInfo
end

--是否选中wifi自动下载
M.IsSelectWifiAutoDownload = function()
    --默认选中
    return UnityPlayerPrefs.GetInt(IS_SELECT_WIFI_AUTO_DOWNLOAD, STATE_START) == STATE_START
end

M.SetSelectWifiAutoDownloadValue = function(isSelect)
    local value = isSelect and STATE_START or STATE_DEFAULT
    UnityPlayerPrefs.SetInt(IS_SELECT_WIFI_AUTO_DOWNLOAD, value)
end

--======== 业务层接口 end ====

return XLaunchDlcManager