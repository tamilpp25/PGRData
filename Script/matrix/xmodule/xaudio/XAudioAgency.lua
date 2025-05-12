---@class XAudioAgency : XAgency
---@field private _Model XAudioModel
local XAudioAgency = XClass(XAgency, "XAudioAgency")
function XAudioAgency:OnInit()
    --初始化一些变量
    self:InitAlbum()
end

function XAudioAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XAudioAgency:InitEvent()
    --实现跨Agency事件注册
    self:AddAgencyEvent(XEventId.EVENT_PRE_ENTER_FIGHT, self.OpenStageAudioLog, self)
    self:AddAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.CloseStageAudioLogBySettle, self)
    self:AddAgencyEvent(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.OnLogin,self)
end

function XAudioAgency:RemoveEvent()
    self:RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.OpenStageAudioLog)
    self:RemoveEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.CloseStageAudioLogBySettle)
    self:RemoveEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.OnLogin)
end

function XAudioAgency:OpenStageAudioLog(stageId)
    if not XMain.IsWindowsEditor then
        return
    end

    if not stageId then
        -- XLog.Error("尝试记录音频数据失败，stageId为空", stageId)
        return
    end

    if not CS.XAudioManager.IsLogCollect then
        CS.XAudioManager.SetIsLogCollect()
    end
    CS.XAudioManager.StopGenerateLogFile() -- 避免日志混合冲突，先完全停止一遍日志记录
    CS.XAudioManager.StartGenerateLogFile(stageId)
    self.RecordStageId = stageId
end

function XAudioAgency:CloseStageAudioLogByStageId(isUpload)
    if not XTool.IsNumberValid(self.RecordStageId) then
        return
    end

    local stageCfg = XMVCA.XFuben:GetStageCfg(self.RecordStageId)
    if not stageCfg then
        XLog.Error("关卡数据错误", self.RecordStageId)
        return
    end

    if isUpload then
        local allLog = CS.XAudioManager.GetCurFullLog()
        if string.IsNilOrEmpty(allLog) then
            XLog.Error("CriAuLog上报失败 音频日志上报功能在战斗中被异常关闭")
            return
        end

        local titleName = string.format("CriAuLog_%s_%s", self.RecordStageId, stageCfg.Name)
        local url = string.format("http://10.0.30.108:8080/POST?file_name=%s", titleName)
        CS.XHttp.PostAsync(url, allLog)
    end

    self.RecordStageId = nil
    CS.XAudioManager.StopGenerateLogFile()
end

function XAudioAgency:CloseStageAudioLogBySettle()
    if not XMain.IsWindowsEditor then
        return
    end

    local allLog = CS.XAudioManager.GetCurFullLog()
    if string.IsNilOrEmpty(allLog) then
        XLog.Error("CriAuLog上报失败 音频日志上报功能在战斗中被异常关闭")
        return
    end

    self:CloseStageAudioLogByStageId(true)
end

function XAudioAgency:CloseStageAudioLogByReplay()
end

function XAudioAgency:OnLogin()
    self:InitMainNeedCueId()
end

-- CD机 config start
-- 该方法仅检查表格格式 无功能
function XAudioAgency:InitAlbum()
    -- AlbumTemplates = XTableManager.ReadByIntKey(TABLE_ALBUM, XTable.XTableMusicPlayerAlbum,"Id")
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()

    local cueIdDic = {}
    local id
    local cueId
    local priority
    for _, template in pairs(AlbumTemplates) do
        id = template.Id
        cueId = template.CueId
        if not cueId or cueId == 0 then
            XLog.Error("InitAlbum", "cueId", "id", tostring(id))
        end

        if not cueIdDic[cueId] then
            cueIdDic[cueId] = true
        else
            XLog.Error("InitAlbum 错误, 存在相同的cueId: " .. cueId .. "检查配置表 MusicPlayerAlbum.tab")
        end

        priority = template.Priority
        if not priority or priority == 0 then
            XLog.Error("InitAlbum", "Priority", "id", tostring(id))
        end
    end
end

function XAudioAgency:GetAlbumIdList()
    if XTool.IsTableEmpty(self._Model.AlbumIdList) then
        self._Model:CreateAlbumIdList()
    end

    return self._Model.AlbumIdList
end

function XAudioAgency:GetAlbumTemplateById(id)
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()
    local template = AlbumTemplates[id]
    if template then
        return template
    end
    XLog.Error("not found GetAlbumTemplateById","id", tostring(id))
end

function XAudioAgency:IsHaveAlbumById(id)
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()
    return AlbumTemplates[id] ~= nil
end

function XAudioAgency:GetAlbumTemplateByCueId(cueId)
    local albumId = self._Model:GetCueIdToMusicAlbumIdDic()[cueId]
    if not albumId then
        return
    end

    local albumConfig = self:GetModelMusicPlayerAlbum()[albumId]
    return albumConfig
end
-- CD机 config end

-- CD机 manager start
function XAudioAgency:InitMainNeedCueId()
    local albumId = XSaveTool.GetData(self._Model.UiMainSavedAlbumIdKey)
    if not albumId or not self:IsHaveAlbumById(albumId) then
        albumId = self._Model.DefaultAlbumId
        if albumId == 0 then
            XLog.Error("Client/Config/ClientConfig.tab 表里面的 MusicPlayerMainViewNeedPlayedAlbumId 字段对应的值不能为0")
        end
    end
    local template = self:GetAlbumTemplateById(albumId)
    local cueId = template.CueId
    if self:CheckMusicCanPlayByAlbum(cueId) then
        self._Model.UiMainNeedPlayedAlbumId = albumId
        CS.XAudioManager.UiMainNeedPlayedBgmCueId = cueId
    else
        self._Model.UiMainNeedPlayedAlbumId = self._Model.DefaultAlbumId
        CS.XAudioManager.UiMainNeedPlayedBgmCueId = self:GetAlbumTemplateById(self._Model.DefaultAlbumId).CueId
    end
end

function XAudioAgency:ChangeUiMainAlbumId(albumId)
    local template = self:GetAlbumTemplateById(albumId)
    local cueId = template.CueId
    
    self._Model.UiMainNeedPlayedAlbumId = albumId
    XSaveTool.SaveData(self._Model.UiMainSavedAlbumIdKey, albumId)
    CS.XAudioManager.UiMainNeedPlayedBgmCueId = cueId
end

function XAudioAgency:GetUiMainNeedPlayedAlbumId()
    if not XMVCA.XSubPackage:CheckNecessaryComplete() then
        return self._Model.DefaultAlbumId
    end
    return self._Model.UiMainNeedPlayedAlbumId
end
-- CD机 manager end

----------public start----------
-- 检测cueId当前是否能在CD机上播放
function XAudioAgency:CheckMusicCanPlayByAlbum(cueId)
    local albumConfig = self:GetAlbumTemplateByCueId(cueId)
    if not albumConfig then
        return false
    end

    -- 没有condition就是默认可以播放
    local conditionId = albumConfig.ConditionId
    if XTool.IsNumberValid(conditionId) then
        return XConditionManager.CheckCondition(conditionId)
    end

    return true
end

-- get Model config
function XAudioAgency:GetModelMusicPlayerAlbum()
    return self._Model:GetMusicPlayerAlbum()
end
--

----------public end----------

----------private start----------


----------private end----------

return XAudioAgency