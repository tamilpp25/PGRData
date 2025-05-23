---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by heyupeng.
--- DateTime: 2024/6/5 16:35
---

local VECTOR2_ZERO = Vector2.zero

---@field _Control XSucceedBossControl
local XUiSucceedBossMonsterItem = require("XUi/XUiSucceedBoss/XSucceedBossMonsterItem")

local XUiSucceedBossMainChapterItem = XClass(XUiNode, "XUiSucceedBossMainChapterItem")

function XUiSucceedBossMainChapterItem:Ctor(ui, parent)
    self:InitAutoScript()
    self.MonsterItems = {
        XUiSucceedBossMonsterItem.New(self.Grid1, self),
        XUiSucceedBossMonsterItem.New(self.Grid2, self),
        XUiSucceedBossMonsterItem.New(self.Grid3, self),
    }
end

function XUiSucceedBossMainChapterItem:OnDestroy()
    if XTool.IsNumberValid(self.RedPointEventId) then
        XRedPointManager.RemoveRedPointEvent(self.RedPointEventId)
        self.RedPointEventId = nil
    end
end

function XUiSucceedBossMainChapterItem:InitAutoScript()
    self.LockTxtTips = XUiHelper.TryGetComponent(self.PanelLock, "ImgLock/TxtTips", "Text")
    self:AutoAddListener()
end

function XUiSucceedBossMainChapterItem:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClick)
end

function XUiSucceedBossMainChapterItem:Refresh(chapterId, index)
    self.ChapterId = chapterId
    self.ChapterIndex = index
    self.ChapterConfig = self._Control:GetChapterConfig(chapterId)
    self:SetTextIndex(index)
    if not self.ChapterConfig then
        return
    end

    self.TxtTitle.text = self.ChapterConfig.Name
    self.TxtTitleNum.text = string.format("%02d", index)

    local isChapterUnLock, lockTips = self._Control:CheckChapterUnLock(chapterId)
    if isChapterUnLock then
        if self.PanelLock then
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        if self.PanelLock then
            self.PanelLock.gameObject:SetActiveEx(true)
        end
        if self.LockTxtTips then
            self.LockTxtTips.text = lockTips
        end
    end
    local isChapterPass = self._Control:CheckChapterPass(chapterId)
    self.CommonFuBenClear.gameObject:SetActiveEx(isChapterPass)
    self.RImgBgClear.gameObject:SetActiveEx(isChapterPass)

    local curChapterId = self._Control:GetCurrentChapterId()
    if XTool.IsNumberValid(curChapterId) then
        self.TagOngoing.gameObject:SetActiveEx(self.ChapterId == curChapterId)
    end

    if self.ChapterConfig.Type == XEnumConst.SucceedBoss.ChapterType.Optional then
        self:RefreshOptional()
    else
        self:RefreshNormal()
    end

    if XTool.IsNumberValid(self.RedPointEventId) then
        XRedPointManager.RemoveRedPointEvent(self.RedPointEventId)
        self.RedPointEventId = nil
    end
    -- 红点
    self.RedPointEventId = XRedPointManager.AddRedPointEvent(self.RedPoint, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SUCCEED_BOSS_CHAPTER }, chapterId, true)
end

function XUiSucceedBossMainChapterItem:OnCheckRedPoint(count)
    self.RedPoint.gameObject:SetActiveEx(count >= 0)
end

function XUiSucceedBossMainChapterItem:OnBtnChapterClick()
    -- 先判断能不能进
    -- 再看有没有当前章节数据
    -- 有数据直接打开章节界面
    -- 没数据请求数据，请求成功后打开章节界面
    local isCanEnter, isHasData, desc = self._Control:CheckCanEnterChapter(self.ChapterId)
    if isCanEnter then
        if isHasData then
            XLuaUiManager.Open("UiSucceedBossChapter")
        else
            self._Control:RequestSucceedBossSelectChapter(self.ChapterId, function()
                XLuaUiManager.Open("UiSucceedBossChapter")
            end)
        end

        self._Control:SaveSelectChapterLocalCache(self.ChapterId)
        XEventManager.DispatchEvent(XEventId.EVENT_SUCCEED_BOSS_SELECT_CHAPTER)
    else
        if not string.IsNilOrEmpty(desc) then
            XUiManager.TipText(desc)
        end
    end
end

function XUiSucceedBossMainChapterItem:RefreshNormal()
    self.RImgBgNormal.gameObject:SetActiveEx(true)
    self.RImgBgHard.gameObject:SetActiveEx(false)
    self.TxtScoreTitle.gameObject:SetActiveEx(false)
    --self.TxtScore.gameObject:SetActiveEx(false)
    --self.TxtNoScore.gameObject:SetActiveEx(false)
    local monsterGroupIds = self.ChapterConfig.MonsterGroupIds
    for i, monsterGroupId in ipairs(monsterGroupIds) do
        local monsterGroupConfig = self._Control:GetMonsterGroupConfig(monsterGroupId)
        if monsterGroupConfig then
            local monsterId = monsterGroupConfig.SelectMonster -- 普通章节每关不可选择怪物，只取第一个
            ---@type XUiNode
            local monsterItem = self.MonsterItems[i]
            if not monsterItem then
                break
            end
            --if not monsterItem then
            --    local tempGameObject = XUiHelper.Instantiate(self.GridBoss, self["Grid" .. i])
            --    tempGameObject:GetComponent("RectTransform").anchoredPosition = VECTOR2_ZERO
            --    monsterItem = XUiSucceedBossMonsterItem.New(tempGameObject, self)
            --    self.MonsterItems[i] = monsterItem
            --end
            monsterItem:Open()
            monsterItem:Refresh(monsterId, XEnumConst.SucceedBoss.BossHeadUseType.Main)
        end
    end
end

function XUiSucceedBossMainChapterItem:RefreshOptional()
    self.RImgBgNormal.gameObject:SetActiveEx(false)
    self.RImgBgHard.gameObject:SetActiveEx(true)
    self.TxtScoreTitle.gameObject:SetActiveEx(true)
    -- 判断当前战斗章节是否是该章节
    local curChapterId = self._Control:GetCurrentChapterId()
    if XTool.IsNumberValid(curChapterId) then
        if curChapterId == self.ChapterId and self._Control:GetStageProgressIndex() > 1 then
            self:RefreshOptionalByCurStageInfos()
        else
            self:RefreshOptionalByRecordData()
        end
    else
        self:RefreshOptionalByRecordData()
    end
end

function XUiSucceedBossMainChapterItem:RefreshOptionalByCurStageInfos()
    local curStageInfos = self._Control:GetCurStageInfos()
    local monsterGroupIds = self.ChapterConfig.MonsterGroupIds
    local stageProgressIndex = self._Control:GetStageProgressIndex()
    for i = 1, #monsterGroupIds do
        local monsterItem = self.MonsterItems[i]
        if not monsterItem then
            break
        end
        --if not monsterItem then
        --    local tempGameObject = XUiHelper.Instantiate(self.GridBoss, self["Grid" .. i])
        --    tempGameObject:GetComponent("RectTransform").anchoredPosition = VECTOR2_ZERO
        --    monsterItem = XUiSucceedBossMonsterItem.New(tempGameObject, self)
        --    self.MonsterItems[i] = monsterItem
        --end
        monsterItem:Open()
        local stageInfo = curStageInfos[i]
        if XTool.IsTableEmpty(stageInfo) or i >= stageProgressIndex then
            monsterItem:SetShow(false)
        else
            monsterItem:Refresh(stageInfo.MonsterId, XEnumConst.SucceedBoss.BossHeadUseType.Main)
        end
    end
    self.TxtScore.gameObject:SetActiveEx(false)
    self.TxtNoScore.gameObject:SetActiveEx(true)
end

function XUiSucceedBossMainChapterItem:RefreshOptionalByRecordData()
    local passChapterInfo = self._Control:GetPassChapterInfo(self.ChapterId)
    if XTool.IsTableEmpty(passChapterInfo) then
        local monsterGroupIds = self.ChapterConfig.MonsterGroupIds
        for i, _ in ipairs(monsterGroupIds) do
            local monsterItem = self.MonsterItems[i]
            if not monsterItem then
                break
            end
            --if not monsterItem then
            --    local tempGameObject = XUiHelper.Instantiate(self.GridBoss, self["Grid" .. i])
            --    tempGameObject:GetComponent("RectTransform").anchoredPosition = VECTOR2_ZERO
            --    monsterItem = XUiSucceedBossMonsterItem.New(tempGameObject, self)
            --    self.MonsterItems[i] = monsterItem
            --end
            monsterItem:Open()
            monsterItem:SetShow(false)
        end
        self.TxtScore.gameObject:SetActiveEx(false)
        self.TxtNoScore.gameObject:SetActiveEx(true)
    else
        self:RefreshOptionalByPassChapterInfo(passChapterInfo)
    end
end

function XUiSucceedBossMainChapterItem:RefreshOptionalByPassChapterInfo(passChapterInfo)
    self.TxtScore.gameObject:SetActiveEx(true)
    self.TxtNoScore.gameObject:SetActiveEx(false)
    self.TxtScore.text = passChapterInfo.MaxScore
    -- 使用等级最高的三个怪做显示
    local selectMonstersDic = passChapterInfo:GetSelectMonsters()
    local allMonstersList = {}
    for monsterId, monsterData in pairs(selectMonstersDic) do
        table.insert(allMonstersList, { MonsterId = monsterId, Level = monsterData:GetMonsterLevel(), StageIndex = monsterData:GetStageIndex() })
    end

    table.sort(allMonstersList, function(a, b)
        return a.StageIndex < b.StageIndex
    end)

    for i = 1, 3 do
        local monsterItem = self.MonsterItems[i]
        if not monsterItem then
            break
        end
        --if not monsterItem then
        --    local tempGameObject = XUiHelper.Instantiate(self.GridBoss, self["Grid" .. i])
        --    tempGameObject:GetComponent("RectTransform").anchoredPosition = VECTOR2_ZERO
        --    monsterItem = XUiSucceedBossMonsterItem.New(tempGameObject, self)
        --    self.MonsterItems[i] = monsterItem
        --end
        monsterItem:Open()
        local monsterLevelData = allMonstersList[i]
        if not monsterLevelData then
            monsterItem:SetShow(false)
        else
            monsterItem:Refresh(monsterLevelData.MonsterId, XEnumConst.SucceedBoss.BossHeadUseType.Main, monsterLevelData.Level)
        end
    end
end

function XUiSucceedBossMainChapterItem:SetTextIndex(index)
    local imgFrom = self["ImgTitleNum" .. index]
    if not imgFrom then
        return
    end
    ---@type UnityEngine.UI.Image
    local imgTo = self.ImgTitleNum
    -- 把imgFrom的图片复制到imgTo
    imgTo:SetNativeSize()
    imgTo.sprite = imgFrom.sprite
    imgTo.color = imgFrom.color
end

return XUiSucceedBossMainChapterItem