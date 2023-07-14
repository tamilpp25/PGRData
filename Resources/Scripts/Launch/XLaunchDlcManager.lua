local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
local DLC_HAS_DOWNLOADED_KEY = "DLC_HAS_DOWNLOADED_KEY"
local DLC_HAS_START_DOWNLOADED_KEY = "DLC_HAS_START_DOWNLOADED_KEY"
local HAS_SELECT_DOWNLOAD_PART_KEY = "HAS_SELECT_DOWNLOAD_PART_KEY"

local M = {}
local XDlcManager = M

local HasStartDownloadDic = {}
local DownloadedDic = {}
local IndexTalbe = {}

local launchModule = require("XLaunchModule")

M.Init = function(indexTalbe)
    IndexTalbe = indexTalbe
    for k,v in pairs(IndexTalbe) do
        HasStartDownloadDic[k] = UnityPlayerPrefs.GetInt(DLC_HAS_START_DOWNLOADED_KEY..k,0)
        DownloadedDic[k] = UnityPlayerPrefs.GetInt(DLC_HAS_DOWNLOADED_KEY..k,0)
    end
end


M.HasStartDownloadDlc = function(id)
    return HasStartDownloadDic[id] == 1
end

M.HasDownloadedDlc = function(id)
    return DownloadedDic[id] == 1
end

M.DoneDownload = function(id)
    for k,v in pairs(HasStartDownloadDic) do
        DownloadedDic[id] = 1
        UnityPlayerPrefs.SetInt(DLC_HAS_START_DOWNLOADED_KEY..k,1)
    end
end


M.SetNeedDownload = function (id)
    HasStartDownloadDic[id] = 1
    UnityPlayerPrefs.SetInt(DLC_HAS_DOWNLOADED_KEY..k,1)
end

M.SetAllNeedDownload = function()
    for k,v in pairs(IndexTalbe) do
        M.SetNeedDownload(k)
    end
end

M.DownloadDlc = function (id,processCb,doneCb)
    M.SetNeedDownload(id)

    launchModule.DownloadDlc(processCb,doneCb)
end

M.NeedDownloadForFunc = function(funcId)
    -- body
    local dlcId = XDlcConfig.FuncToDlcId(funcId)
    dlcId = tostring(dlcId)
    if dlcId then
        return not M.DownloadedDic(dlcId)
    else
        return false
    end
end

M.NeedDownloadForStage = function(stageId)
    -- body
    local dlcId = XDlcConfig.StageToDlcId(stageId)
     dlcId = tostring(dlcId)
    if dlcId then
        return not M.DownloadedDic(dlcId)
    else
        return false
    end
end

M.NeedDownloadDlc = function(dlcId)
    return DownloadedDic[dlcId] == 0
end

M.NeedShowSelectDownloadPart = function(appVer)
    return UnityPlayerPrefs.GetInt(HAS_SELECT_DOWNLOAD_PART_KEY..appVer,0) == 0
end

M.DoneSelectDownloadPart = function(appVer)
    UnityPlayerPrefs.SetInt(HAS_SELECT_DOWNLOAD_PART_KEY..appVer,1)
end

return XDlcManager