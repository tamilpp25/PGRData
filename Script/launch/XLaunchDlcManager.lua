local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
local DLC_HAS_DOWNLOADED_KEY = "DLC_HAS_DOWNLOADED_KEY"
local DLC_HAS_START_DOWNLOADED_KEY = "DLC_HAS_START_DOWNLOADED_KEY"
local HAS_SELECT_DOWNLOAD_PART_KEY = "HAS_SELECT_DOWNLOAD_PART_KEY"
local CsApplication = CS.XApplication
local CsLog = CS.XLog

local M = {}
local XLaunchDlcManager = M

local IndexTable = {}
local CommonIdSet = {}

local HasStartDownloadDic = {}
local DownloadedDic = {}

local DlcSizeDic = {}
local DlcIndexInfo = {}

local IsDlcBuild = false

local DLC_BASE_INDEX = 0 -- 基础资源包索引
local DLC_COMMON_INDEX = -1 -- 通用资源包索引

local STATE_DEFAULT = 0 -- 未开始下载
local STATE_START = 1 -- 已开始（选择）下载


--====启动逻辑接口 begin=====

M.Init = function(indexTable, commonIdList)
    IndexTable = indexTable
    for _, dlcId in pairs(commonIdList) do
        CommonIdSet[dlcId] = true
    end
    
    for dlcId, info in pairs(IndexTable) do
        HasStartDownloadDic[dlcId] = UnityPlayerPrefs.GetInt(DLC_HAS_START_DOWNLOADED_KEY .. dlcId, STATE_DEFAULT)
        DownloadedDic[dlcId] = UnityPlayerPrefs.GetInt(DLC_HAS_DOWNLOADED_KEY .. dlcId, STATE_DEFAULT)
    end
end

M.SetIsDlcBuild = function(isDlcBuild)
    IsDlcBuild = isDlcBuild
end

M.SetDlcIndexInfo = function(dlcId, dlcIndexInfo) -- 记录size后即可丢弃
    DlcIndexInfo[dlcId] = dlcIndexInfo
end

M.DoDownloadDlc = function(progressCb, doneCb, exitCb)
    local PathModule = require("XLaunchAppPathModule")
    local FileModuleCreator = require("XLaunchFileModule")
    local VersionModule = require("XLaunchAppVersionModule")

    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        CsLog.Debug("Release 模式运行")
        local DocFileModule = FileModuleCreator()
        DocFileModule.Check(RES_FILE_TYPE.MATRIX_FILE, PathModule, VersionModule, doneCb, progressCb, exitCb)
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Debug then
        CsLog.Debug("Debug 模式运行")
        doneCb()
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Editor then
        CsLog.Debug("Editor 模式运行")
        doneCb()
    end
end

-- 是否下载过指定id的分包
M.HasStartDownloadDlc = function(id)
    return HasStartDownloadDic[id] == STATE_START
end

M.HasDownloadedDlc = function(id)
    return DownloadedDic[id] == STATE_START
end

M.DoneDownload = function()
    for dlcId, v in pairs(HasStartDownloadDic) do
        if v == STATE_START then
            DownloadedDic[dlcId] = STATE_START
            UnityPlayerPrefs.SetInt(DLC_HAS_DOWNLOADED_KEY .. dlcId, STATE_START)
        end
    end
end


M.SetNeedDownload = function (id)
    local state = STATE_START
    CsLog.Debug("SetNeedDownload:" .. tostring(id))
    HasStartDownloadDic[id] = state
    UnityPlayerPrefs.SetInt(DLC_HAS_START_DOWNLOADED_KEY .. id, state)
    
    -- 当依赖了通用资源的分包开始下载时，下载通用资源包
    if CommonIdSet[id] and HasStartDownloadDic[DLC_COMMON_INDEX] ~= state then
        HasStartDownloadDic[DLC_COMMON_INDEX] = state
        UnityPlayerPrefs.SetInt(DLC_HAS_START_DOWNLOADED_KEY .. DLC_COMMON_INDEX, state)
    end
end

M.SetAllNeedDownload = function()
    for dlcId, info in pairs(IndexTable) do
        M.SetNeedDownload(dlcId)
    end
end

M.DownloadDlc = function (ids, processCb, doneCb)
    for _, id in pairs(ids) do
        M.SetNeedDownload(id)
    end
   
    XLuaUiManager.OpenWithCallback("UiLaunch",function()
        M.DoDownloadDlc(processCb, 
            function()
                XLuaUiManager.Close("UiLaunch")
                if doneCb then
                    doneCb()
                end
            end, 
            function()
                XLuaUiManager.Close("UiLaunch")
            end)
    end)
end

M.NeedShowSelectDownloadPart = function(appVer)
    return UnityPlayerPrefs.GetInt(HAS_SELECT_DOWNLOAD_PART_KEY .. appVer, STATE_DEFAULT) == STATE_DEFAULT
end

M.DoneSelectDownloadPart = function(appVer)
    UnityPlayerPrefs.SetInt(HAS_SELECT_DOWNLOAD_PART_KEY .. appVer, STATE_START)
end
--====启动逻辑接口 end=====


--======== 业务层接口 begin ====
M.NeedDownloadDlc = function(dlcId)
    return DownloadedDic[dlcId] == STATE_DEFAULT
end

local GetDlcSize = function(dlcId)
    if not DlcSizeDic[dlcId] then
        local size = 0
        local indexInfo = DlcIndexInfo[dlcId]
        if indexInfo == nil then
            return 0
        end
        for assetPath, docInfo in pairs(indexInfo) do
            size = size + docInfo[3]
        end
        DlcSizeDic[dlcId] = size
    end
    return DlcSizeDic[dlcId]
end

M.GetDownloadSize = function(dlcIds)
    local size = 0
    for _, dlcId in pairs(dlcIds) do
        size = size + GetDlcSize(dlcId)
    end
    return size
end
--======== 业务层接口 end ====

return XLaunchDlcManager