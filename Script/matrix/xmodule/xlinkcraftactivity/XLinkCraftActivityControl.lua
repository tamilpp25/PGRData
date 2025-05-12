---@class XLinkCraftActivityControl : XControl
---@field private _Model XLinkCraftActivityModel
local XLinkCraftActivityControl = XClass(XControl, "XLinkCraftActivityControl")
function XLinkCraftActivityControl:OnInit()
    --初始化内部变量
    self:StartLeftTimeTimer()
end

function XLinkCraftActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XLinkCraftActivityControl:RemoveAgencyEvent()

end

function XLinkCraftActivityControl:OnRelease()
    self:EndLeftTimeTimer()
end

function XLinkCraftActivityControl:GetShopSkipId()
     return self._Model:GetClientConfigInt('ShopSkipId')
end

function XLinkCraftActivityControl:GetChapterNameById(chapterId)
    local cfg = self._Model:GetLinkCraftChapterCfgById(chapterId)
    if cfg then
        return cfg.Name
    end
end

--region 配置表-------------------------------->>>

--region 关卡相关
function XLinkCraftActivityControl:GetStageIdsByChapterId(chapterId)
    local cfg = self._Model:GetLinkCraftChapterCfgById(chapterId)
    if cfg then
        return cfg.Stages
    end
end

---活动关卡表的关卡Id查找关卡总表的关卡Id
function XLinkCraftActivityControl:GetStageIdById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.StageId
    end
end

function XLinkCraftActivityControl:GetStageAffixIconById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.AffixIcon
    end
end

function XLinkCraftActivityControl:GetStageAffixDescById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.AffixDesc
    end
end

function XLinkCraftActivityControl:GetStageRewardIdById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.RewardId
    end
end

function XLinkCraftActivityControl:GetStageLinkRewardById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.LinkId
    end
end

function XLinkCraftActivityControl:GetStageSkillRewardById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.LinkSkill
    end
end

function XLinkCraftActivityControl:GetStageIconById(id)
    local cfg = self._Model:GetLinkCraftStageCfgById(id)
    if cfg then
        return cfg.Icon
    end
end
--endregion

--region 链条相关

function XLinkCraftActivityControl:GetLinkSkillListById(linkId)
    local cfg = self._Model:GetLinkCraftLinkCfgById(linkId)
    if cfg then
        return cfg.Skills
    end
end

function XLinkCraftActivityControl:GetLinkNameById(linkId)
    local cfg = self._Model:GetLinkCraftLinkCfgById(linkId)
    if cfg then
        return cfg.Name
    end
end

function XLinkCraftActivityControl:GetSkillNameById(skillId)
    local cfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    if cfg then
        return cfg.Name
    end
end

function XLinkCraftActivityControl:GetSkillDetailById(skillId)
    local cfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    if cfg then
        return cfg.Desc
    end
end

function XLinkCraftActivityControl:GetSkillIconById(skillId)
    local cfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    if cfg then
        return cfg.Icon
    end
end

function XLinkCraftActivityControl:GetSkillUnlockTips(skillId)
    local cfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    if cfg then
        return cfg.UnlockTips
    end
end
--endregion

--region 杂项配置
function XLinkCraftActivityControl:GetShowRewardId()
    return self._Model:GetClientConfigInt('ShowRewardId')
end

function XLinkCraftActivityControl:GetClientConfigString(key)
    return self._Model:GetClientConfigString(key)
end

function XLinkCraftActivityControl:GetSkillTypeTextByid(skillId)
    local skillCfg = self._Model:GetLinkCraftSkillCfgById(skillId)
    local skillType = skillCfg.Type
    return self._Model:GetClientConfigStringList('SkillType')[skillType]
end
--endregion

--endregion <<<--------------------------------------------

--region 活动数据-------------------------------->>>
-- 章节相关
function XLinkCraftActivityControl:GetChapterSchedulePercentById(chapterId)
    local activityData = self._Model:GetActivityData()
    local chapterData = activityData:GetChapterDataById(chapterId)
    if chapterData then
        return chapterData:GetStagePassSchedule()
    end
end

function XLinkCraftActivityControl:GetChapterScheduleDescById(chapterId)
    local percent = self:GetChapterSchedulePercentById(chapterId)
    if percent then
        local fixedPercent = math.floor(percent*100)
        return string.format("%s%%", fixedPercent)
    end
    return ''
end

function XLinkCraftActivityControl:SetCurChapterById(chapterId)
    local activityData = self._Model:GetActivityData()

    if activityData then
        activityData:SetCurChapterById(chapterId)
    end

end

function XLinkCraftActivityControl:GetCurChapterId()
    local activityData = self._Model:GetActivityData()
    return activityData:GetCurChapterId()
end

function XLinkCraftActivityControl:GetChapterIdByIndex(index)
    local activityData = self._Model:GetActivityData()
    local activityCfg = self._Model:GetLinkCraftActivityCfgById(activityData._CurActivityId)
    return activityCfg.Chapters[index]
end

function XLinkCraftActivityControl:CheckSkillIsLockById(skillId)
    local activityData = self._Model:GetActivityData()
    return not activityData:CheckSkillInUnLockSetById(skillId)
end

function XLinkCraftActivityControl:CheckSkillIsUsingById(skillId)
    local activityData = self._Model:GetActivityData()
    local linkData = activityData:GetCurLinkdData()
    return linkData:CheckIsSkillUsing(skillId)
end

function XLinkCraftActivityControl:GetLocalTeam()
    return self._Model:GetLocalTeam()
end

---@return XLinkListData
function XLinkCraftActivityControl:GetCurLinkListData()
    local activityData = self._Model:GetActivityData()
    return activityData:GetCurLinkdData()
end

function XLinkCraftActivityControl:GetLinkListDataById(linkId)
    local activityData = self._Model:GetActivityData()
    return activityData:GetLinkDataById(linkId)
end

function XLinkCraftActivityControl:SetSkillIntoCurSelect(skillId)
    local curSelectIndex = self:GetSelectIndex()
    local linkData = self:GetCurLinkListData()
    linkData:SetSkill(curSelectIndex, skillId)
end

function XLinkCraftActivityControl:SwitchSkillIntoCurSelect(skillId)
    local curSelectIndex = self:GetSelectIndex()
    local linkData = self:GetCurLinkListData()
    
    local skillList = linkData:GetSkillList()
    local index = 0
    local selectPosSkillId = 0
    for i, v in ipairs(skillList) do
        if v == skillId then
            index = i
        end
        if i == curSelectIndex then
            selectPosSkillId = v
        end
    end

    linkData:SetSkill(curSelectIndex, skillId)
    linkData:SetSkill(index, selectPosSkillId)
end

function XLinkCraftActivityControl:GetStageStarById(stageId)
    local activityData = self._Model:GetActivityData()
    local curChapterData = activityData:GetCurChapterData()
    if curChapterData then
        return curChapterData:GetStageAwardStarById(stageId)
    elseif not XTool.IsTableEmpty(activityData._ChapterDataList) then
        --遍历所有章节数据
        for i, v in ipairs(activityData._ChapterDataList) do
            local starNum = v:GetStageAwardStarById(stageId)
            if XTool.IsNumberValid(starNum) then
                return starNum
            end
        end
    end
    return 0
end

function XLinkCraftActivityControl:MarkChapterIsOld(chapterId)
    if XMVCA.XLinkCraftActivity:CheckChapterIsNewById(chapterId) then
        local key = XMVCA.XLinkCraftActivity:GetChapterNewTagKey(chapterId)
        XSaveTool.SaveData(key,true)
    end
end

--- 按照规则从当前章节中选一个关卡进行选中
function XLinkCraftActivityControl:GetSelectStageByChapterId(chapterId)
    -- 默认展开上一次选择的关卡
    local stageId = self._Model:GetLastPassStageByChapterId(chapterId)

    if not XTool.IsNumberValid(stageId) then
        
        local activityData = self._Model:GetActivityData()
        local chapterData = activityData:GetCurChapterData()
        -- 获取最后一个clear的关卡
        stageId = chapterData:GetLastPassedStageIndex()

        if XTool.IsNumberValid(stageId) then
            local nextStageId = stageId + 1
            local nextStageCfg = self._Model:GetLinkCraftStageCfgById(nextStageId)
            -- 选择ID最小的一个未clear关卡
            if nextStageCfg and nextStageCfg.ChapterId == chapterId then
                return nextStageId
            else
                -- 否则选择最后一个clear的关卡
                return stageId
            end
        else
            -- 都没有数据则默认选择第一个
            return self._Model:GetLinkCraftChapterCfgById(chapterId).Stages[1]
        end
    end
    
    return stageId
end

function XLinkCraftActivityControl:CheckLinkIsValid()
    local linkData = self:GetCurLinkListData()
    local skillList = linkData:GetSkillList()
    --特别规则，三号位不可设增益buff
    if XTool.IsNumberValid(skillList[3]) then
        local cfg = self._Model:GetLinkCraftSkillCfgById(skillList[3])
        if cfg then
            return cfg.Type ~= 1, 3
        end
    end
    return true
end

function XLinkCraftActivityControl:SetSelectedStageId(stageId)
    local stageCfg = self._Model:GetLinkCraftStageCfgById(stageId)
    self._Model:SetSelectStageIdOfLinkStageTab(stageCfg.ChapterId, stageId)
end

--- 判断是否有首通新解锁的技能，用于弹窗提示
function XLinkCraftActivityControl:GetNewSkill()
    return self._Model:GetNewSkill()
end

function XLinkCraftActivityControl:ClearNewSkillMark()
    self._Model:SetSkillNewMark(nil)
end

--endregion <<<--------------------------------------------

--region 界面数据------------------------------------------>>>
function XLinkCraftActivityControl:GetSelectIndex()
    return self._CurSelectIndex or 1
end

function XLinkCraftActivityControl:SetSelectIndex(index)
    self._CurSelectIndex = index
end

function XLinkCraftActivityControl:CheckIsEditLink()
    return self._IsEditLink or false
end

function XLinkCraftActivityControl:SetIsEditLink(isEdit)
    self._IsEditLink = isEdit
end

function XLinkCraftActivityControl:BackupLinkData()
    local linkData = self:GetCurLinkListData()

    self._BackupSkillList = linkData:GetSkillList()
end

function XLinkCraftActivityControl:RestoreLinkData()
    local linkData = self:GetCurLinkListData()
    linkData._SkillData = self._BackupSkillList
    self._BackupSkillList = nil
end

function XLinkCraftActivityControl:SetLastSelectChapterId(chapterId)
    -- 不允许置空缓存，这个缓存用于保底查找数据
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    self._Model:SetLastSelectChapterId(chapterId)
end

function XLinkCraftActivityControl:GetLastSelectChapterId()
    return self._Model:GetLastSelectChapterId()
end

function XLinkCraftActivityControl:GetLastSelectChapterLinkData()
    local chapterId = self:GetLastSelectChapterId()
    local activityData = self._Model:GetActivityData()
    local chapterData = activityData:GetChapterDataById(chapterId)

    if chapterData then
        return activityData:GetLinkDataById(chapterData._CurLinkId)
    end
end
--endregion <<<--------------------------------------------

function XLinkCraftActivityControl:StartLeftTimeTimer()
    self:EndLeftTimeTimer()
    self:UpdateLeftTime()
    self._LeftTimeTimerId = XScheduleManager.ScheduleForever(handler(self,self.UpdateLeftTime),XScheduleManager.SECOND)
end

function XLinkCraftActivityControl:EndLeftTimeTimer()
    if self._LeftTimeTimerId then
        XScheduleManager.UnSchedule(self._LeftTimeTimerId)
        self._LeftTimeTimerId = nil
    end
end

function XLinkCraftActivityControl:UpdateLeftTime()
    local leftTime = XMVCA.XLinkCraftActivity:GetLeftTime()
    --到点踢出
    if leftTime <= 0 then
        XLuaUiManager.RunMain()
        XUiManager.TipText('ActivityMainLineEnd')
    end
end

return XLinkCraftActivityControl