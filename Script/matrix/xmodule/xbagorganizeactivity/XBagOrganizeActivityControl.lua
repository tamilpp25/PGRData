---@class XBagOrganizeActivityControl : XControl
---@field private _Model XBagOrganizeActivityModel
---@field GameControl XBagOrganizeActivityGameControl
local XBagOrganizeActivityControl = XClass(XControl, "XBagOrganizeActivityControl")
function XBagOrganizeActivityControl:OnInit()
    self:StartCheckOverTimer()
end

function XBagOrganizeActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBagOrganizeActivityControl:RemoveAgencyEvent()

end

function XBagOrganizeActivityControl:OnRelease()
    self:StopCheckOverTimer()
    if self._EditorControl then
        self._EditorControl = nil
    end
    self.GameControl = nil
    
    XMVCA.XBagOrganizeActivity:ClearStarRequestLock()
end

function XBagOrganizeActivityControl:GetEditorControl()
    if self._EditorControl == nil then
        self._EditorControl = self:AddSubControl(require("XModule/XBagOrganizeActivity/Editor/XEditorBagTileEditControl"))
    end
    
    return self._EditorControl
end

function XBagOrganizeActivityControl:SetCurChapterId(chapterId)
    self.ChapterId = chapterId
end

function XBagOrganizeActivityControl:GetCurChapterId()
    return self.ChapterId or 0
end

function XBagOrganizeActivityControl:SetCurStageId(stageId)
    self._Model:SetCurStageId(stageId)
end

function XBagOrganizeActivityControl:GetCurStageId()
    return self._Model:GetCurStageId()
end

--region Activity Data
function XBagOrganizeActivityControl:GetCurActivityTimeId()
    local activityId = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetBagOrganizeActivityConfig()[activityId]
        if cfg then
            return cfg.TimeId
        end
    end
    return 0
end

function XBagOrganizeActivityControl:GetCurChapterIds()
    local activityId = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetBagOrganizeActivityConfig()[activityId]
        if cfg then
            return cfg.ChapterIds
        end
    end
    return nil
end


function XBagOrganizeActivityControl:GetStageMaxScoreById(stageId)
    local data = self._Model:GetStageRecordById(stageId)

    return XTool.IsTableEmpty(data) and 0 or data.MaxScore
end

--- 获取指定章节的通关进度
function XBagOrganizeActivityControl:GetChapterProgressById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableBagOrganizeChapter
        local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]

        if cfg then
            if not XTool.IsTableEmpty(cfg.StageIds) then
                local passCount = 0

                for i, v in pairs(cfg.StageIds) do
                    if XMVCA.XBagOrganizeActivity:CheckPassedByStageId(v) then
                        passCount = passCount + 1
                    end
                end
                
                return passCount / #cfg.StageIds
            else
                return 0    
            end
        end
    end
    
    return 0
end
--endregion

--region Condition
function XBagOrganizeActivityControl:GetChapterUnLockLeftTime(chapterId)
    local leftTime = 0
    local timeId = self:GetChapterTimeIdById(chapterId)
    if XTool.IsNumberValid(timeId) then
        leftTime = XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
        if leftTime < 0 then
            leftTime = 0
        end
    end

    return leftTime
end

function XBagOrganizeActivityControl:CheckHasNextStage()
    local chapterId = self:GetCurChapterId()
    local stageId = self:GetCurStageId()

    if XTool.IsNumberValid(chapterId) and XTool.IsNumberValid(stageId) then
        local stageIds = self:GetChapterStageIdsById(chapterId)
        if not XTool.IsTableEmpty(stageIds) then
            local isContain, index = table.contains(stageIds, stageId)
            if XTool.IsNumberValid(index) and index < #stageIds then
                return true, stageIds[index + 1]
            end
        end
    end
    
    return false
end
--endregion

--region Configs

--- Chapter
function XBagOrganizeActivityControl:GetChapterNameById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.Name
    end
    
    return ''
end

function XBagOrganizeActivityControl:GetChapterTimeIdById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.TimeId
    end

    return 0
end

function XBagOrganizeActivityControl:GetChapterStageIdsById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.StageIds
    end

    return nil
end

function XBagOrganizeActivityControl:GetChapterEntranceBgById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.EntranceBgAddress
    end

    return ''
end

function XBagOrganizeActivityControl:GetChapterTitleBgById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.TitleBg
    end

    return ''
end

--- Stage
function XBagOrganizeActivityControl:GetStageNameById(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        return cfg.Name
    end
    
    return ''
end


function XBagOrganizeActivityControl:GetStageGoodsListById(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        return cfg.GoodsList
    end

    return nil
end

function XBagOrganizeActivityControl:GetStageGuideImagesById(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        return cfg.GuideImages
    end
end

function XBagOrganizeActivityControl:GetStageEntranceRoleIconById(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        return cfg.EntranceRoleIcon
    end

    return ''
end

function XBagOrganizeActivityControl:GetStageMapIdsById(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        return cfg.MapIds
    end
end

--- 目前仅有一个关卡开启排行，因此直接遍历查找即可
function XBagOrganizeActivityControl:GetEnableRankStage()
    ---@type XTableBagOrganizeActivity
    local cfg = self._Model:GetBagOrganizeActivityConfig()[self._Model:GetCurActivityId()]

    if cfg then
        return cfg.EnableRankStageId
    end
end

--- ClientConfig
function XBagOrganizeActivityControl:GetClientConfigVector2(key)
    return self._Model:GetClientConfigVector2(key)
end

function XBagOrganizeActivityControl:GetClientConfigNum(key, index)
    return self._Model:GetClientConfigNum(key, index)
end

function XBagOrganizeActivityControl:GetClientConfigText(key, index)
    return self._Model:GetClientConfigText(key, index)
end

--- Goods
function XBagOrganizeActivityControl:GetGoodsCfgById(goodsId)
    local cfg = self._Model:GetBagOrganizeGoodsConfig()[goodsId]
    if cfg then
        return cfg
    end
end

--- Map
function XBagOrganizeActivityControl:GetBagOrganizeBagCfgById(mapId)
    return self._Model:GetBagOrganizeBagCfgById(mapId)
end

--- BagOrganizeScoreGrade
function XBagOrganizeActivityControl:GetScoreLevelByStageIdAndScore(stageId, score)
    local cfg = self._Model:GetBagOrganizeScoreGradeCfgById(stageId)

    if cfg then
        for i = #cfg.Score, 1, -1 do
            if score >= cfg.Score[i] then
                return i
            end
        end
    end
    
    return 0
end

function XBagOrganizeActivityControl:GetScoreListByStageId(stageId)
    local cfg = self._Model:GetBagOrganizeScoreGradeCfgById(stageId)

    if cfg then
        return cfg.Score
    end
end

function XBagOrganizeActivityControl:GetScoreLevelIconByStageIdAndScore(stageId, score)
    local levelIndex = self:GetScoreLevelByStageIdAndScore(stageId, score)

    levelIndex = XTool.IsNumberValid(levelIndex) and levelIndex or 1
    
    return self:GetClientConfigText('GameScoreLevelIcon', levelIndex)
end

--- BagOrganizeEventResult
function XBagOrganizeActivityControl:GetBagOrganizeEventResultCfgById(id)
    return self._Model:GetBagOrganizeEventResultCfgById(id)
end

--endregion

--region 到点踢出
function XBagOrganizeActivityControl:StartCheckOverTimer()
    self:StopCheckOverTimer()
    if XMain.IsWindowsEditor then
        self._CheckEditorTimerId = XScheduleManager.ScheduleNextFrame(function()
            -- 编辑器也用了这个控制器，但是不需要踢出检测
            if not self._EditorControl then
                self:UpdateTimer()
                self._CheckOverTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
            end
        end)
    else
        self:UpdateTimer()
        self._CheckOverTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
    end
end

function XBagOrganizeActivityControl:StopCheckOverTimer()
    if self._CheckOverTimerId then
        XScheduleManager.UnSchedule(self._CheckOverTimerId)
        self._CheckOverTimerId = nil
    end

    if XMain.IsWindowsEditor then
        if self._CheckEditorTimerId then
            XScheduleManager.UnSchedule(self._CheckEditorTimerId)
            self._CheckEditorTimerId = nil
        end
    end
end

function XBagOrganizeActivityControl:UpdateTimer()
    local activityId = self._Model:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        ---@type XTableBagOrganizeActivity
        local activityCfg = self._Model:GetBagOrganizeActivityConfig()[activityId]
        
        if activityCfg then
            if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
                return
            end    
        end
    end

    if self._LockTickOut then
        return
    end
    self:StopCheckOverTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipText('ActivityMainLineEnd')
end

--- 玩法界面不需要踢出
function XBagOrganizeActivityControl:LockTickOut()
    self._LockTickOut = true
end

--- 需成对使用，防止踢出功能失效
function XBagOrganizeActivityControl:UnLockTickOut()
    self._LockTickOut = false
end
--endregion

--region In Game
function XBagOrganizeActivityControl:StartGameInit()
    if self.GameControl then
        self:RemoveSubControl(self.GameControl)
        self.GameControl = nil
    end
    self.GameControl = self:AddSubControl(require('XModule/XBagOrganizeActivity/InGame/XBagOrganizeActivityGameControl'))
end

function XBagOrganizeActivityControl:EndGameRelease()
    if self.GameControl then
        self:RemoveSubControl(self.GameControl)
        self.GameControl = nil
        self._Model:ClearOnGameControlRelease()
    end
end

function XBagOrganizeActivityControl:GetGameControl()
    return self.GameControl
end

function XBagOrganizeActivityControl:RecordGameData(settleType)
    if self.GameControl then
        local dict = {}

        dict['turn_id'] = self._Model:GetCurStageTurnId()
        dict['begin_time'] = self._Model:GetCurStageStartTime()
        
        if settleType == XMVCA.XBagOrganizeActivity.EnumConst.SettleType.Normal or settleType == XMVCA.XBagOrganizeActivity.EnumConst.SettleType.NormalForce then
            dict['game_content'] = self.GameControl:GetRecordContent()
            dict['event_effects'] = self.GameControl:GetRecordEventEffects()
        end

        dict['settle_type'] = settleType
        
        CS.XRecord.Record(dict,"900007", "BagOrganizeClientRecord")
    end
end

function XBagOrganizeActivityControl:CheckIsShowTips()
    local curStageId = self._Model:GetCurStageId()
    if XTool.IsNumberValid(curStageId) then
        return self._Model.ReddotData:GetStageTipsShowStateByStateId(curStageId)
    end
    return false
end

function XBagOrganizeActivityControl:SetStageTipsIsShow()
    local curStageId = self._Model:GetCurStageId()
    if XTool.IsNumberValid(curStageId) then
        self._Model.ReddotData:SetStageTipsShowStageByStateId(curStageId)
    end
end
--endregion

return XBagOrganizeActivityControl