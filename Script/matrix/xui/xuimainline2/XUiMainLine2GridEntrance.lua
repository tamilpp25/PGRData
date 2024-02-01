---@class XUiMainLine2GridEntrance : XUiNode
---@field private _Control XMainLine2Control
local XUiMainLine2GridEntrance = XClass(XUiNode, "XUiMainLine2GridEntrance")

function XUiMainLine2GridEntrance:OnStart(entranceData, chapterId, mainId, parentGo, lineGo)
    self.EntranceData = entranceData
    self.StageIds = entranceData.StageIds -- 关卡入口包含1个或多个关卡
    self.StageId = entranceData.StageIds[1] -- 关卡入口使用第一个关卡刷新数据
    self.ChapterId = chapterId
    self.MainId = mainId
    self.ParentGo = parentGo
    self.LineGo = lineGo
    self.SubPrefabs = {}

    self:RegisterUiEvents()
end

function XUiMainLine2GridEntrance:OnEnable()

end

function XUiMainLine2GridEntrance:OnDisable()

end

function XUiMainLine2GridEntrance:OnDestroy()
    self.EntranceData = nil
    self.StageIds = nil
    self.StageId = nil
    self.ChapterId = nil
    self.ParentGo = nil
    self.LineGo = nil
    self.SubPrefabs = nil
    self.AchieveUiObjs = nil
end

function XUiMainLine2GridEntrance:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiMainLine2GridEntrance:OnBtnStageClick()
    local isUnlock, tips = self:IsUnlock()
    if not isUnlock then
        XUiManager.TipMsg(tips)
        return
    end

    -- 缓存关卡Id对应的章节Id
    for _, stageId in ipairs(self.StageIds) do
        self._Control:CacheStageChapterId(stageId, self.ChapterId)
        self._Control:CacheStageStageIds(stageId, self.StageIds)
    end

    local detailType = self._Control:GetStageDetailType(self.StageId)
    if detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE
    or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.CG then
        XLuaUiManager.Open("UiMainLine2DetailStory", self.StageIds, self.ChapterId, self.MainId)

    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_NORMAL 
    or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_SPECIAL
    or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_BOSS then
        XLuaUiManager.Open("UiMainLine2DetailBattle", self.StageIds, self.ChapterId, self.MainId)
    end
end

function XUiMainLine2GridEntrance:Refresh()
    local isShow = self:IsShow()
    local isPass = self:IsPass()

    self.ParentGo.gameObject:SetActiveEx(isShow)
    if self.LineGo then
        self.LineGo.gameObject:SetActiveEx(isShow)
    end

    if not isShow then
        self:Close()
        return
    end
    self:Open()

    local isUnlock = self:IsUnlock()
    local isCur = isUnlock and not isPass

    self:RefreshInfo()
    self:RefreshStageProgress()
    self:RefreshAchievements()
    self:RefreshLock(isUnlock)
    self:ShowSubPrefab("PanelEffect", isCur)
    self:ShowSubPrefab("PanelKill", isPass)
end

-- 刷新关卡信息
function XUiMainLine2GridEntrance:RefreshInfo()
    local stagePrefab = self:LoadSubPrefab("PanelStageActive")
    local uiObj = stagePrefab:GetComponent("UiObject")

    local stageName
    local chapterTitle = self._Control:GetMainTitle(self.MainId)
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    local specialorder = self._Control:GetStageSpecialorder(self.StageId)
    local detailType = self._Control:GetStageDetailType(self.StageId)
    if specialorder then
        stageName = string.format("%s-%s%s %s", chapterTitle, stageCfg.OrderId, specialorder, stageCfg.Name)
    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_BOSS then
        stageName = string.format("%s-%s\n<size=30>%s</size>", chapterTitle, stageCfg.OrderId, stageCfg.Name)
    else
        stageName = string.format("%s-%s %s", chapterTitle, stageCfg.OrderId, stageCfg.Name)
    end
    uiObj:GetObject("TxtName").text = stageName
    uiObj:GetObject("RImgIcon"):SetRawImage(stageCfg.Icon)

    -- 关卡组名称
    local text = XUiHelper.TryGetComponent(self.ParentGo, "Text", "Text")
    if text then
        local groupCfg = self._Control:GetConfigStageGroup(self.EntranceData.GroupId)
        text.text = groupCfg.GroupName
    end
end

-- 刷新关卡进度
function XUiMainLine2GridEntrance:RefreshStageProgress()
    local reachCnt, allCnt = self._Control:GetStageProgress(self.StageId)
    local isShowProgress = allCnt > 0
    if not isShowProgress then
        return
    end

    -- 已完成不显示进度
    local showProgress = reachCnt < allCnt
    if not showProgress then
        self:ShowSubPrefab("PanelProgress", false)
        return
    end

    local prefab = self:LoadSubPrefab("PanelProgress")
    local transform = prefab.transform
    self.RImgGreyBg = self.RImgGreyBg or XUiHelper.TryGetComponent(transform, "RawImage", "RawImage")
    self.ImgProgress = self.ImgProgress or XUiHelper.TryGetComponent(transform, "Image", "Image")
    self.PanelJd = self.PanelJd or XUiHelper.TryGetComponent(transform, "PanelJd")
    self.TxtGreyProgress = self.TxtGreyProgress or XUiHelper.TryGetComponent(transform, "PanelJd/Text1", "Text")
    self.TxtProgress = self.TxtProgress or XUiHelper.TryGetComponent(transform, "PanelJd/Text2", "Text")

    -- 背景图
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    self.RImgGreyBg:SetRawImage(stageCfg.ProgressGreyBg)
    self.ImgProgress:SetSprite(stageCfg.ProgressBg)

    -- 进度
    local progress = reachCnt / allCnt
    self.ImgProgress.fillAmount = progress
    self.TxtGreyProgress.text = math.floor(progress * 100)
    self.TxtProgress.text = math.floor(progress * 100)
end

-- 刷新成就
function XUiMainLine2GridEntrance:RefreshAchievements()
    -- 获取所有关卡的成就
    local achieveInfos = self._Control:GetStagesAchievementInfos(self.StageId, false, self.StageIds)

    -- 无成就时不显示
    if #achieveInfos == 0 then
        return
    end

    -- 加载成就预制体
    if not self.AchieveUiObjs then
        local prefab = self:LoadSubPrefab("PanelAchievement")
        local uiObj = prefab:GetComponent("UiObject")
        local achieveUiObj = uiObj:GetObject("GridAchieve")
        self.AchieveUiObjs = { achieveUiObj }
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchieveUiObjs[i]
        if not uiObj then
            local cloneGo = self.AchieveUiObjs[1].gameObject
            local go = CSInstantiate(cloneGo, cloneGo.transform.parent)
            uiObj = go:GetComponent("UiObject")
            table.insert(self.AchieveUiObjs, uiObj)
        end

        local isNormal = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL
        local isSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL
        uiObj:GetObject("GridNormal").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalFinish").gameObject:SetActiveEx(isNormal and info.IsUnLock)
        uiObj:GetObject("GridHide").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgHideFinish").gameObject:SetActiveEx(isSpecial and info.IsUnLock)
    end
end

-- 刷新上锁状态
function XUiMainLine2GridEntrance:RefreshLock(isUnlock)
    if isUnlock then
        return
    end

    local prefab = self:LoadSubPrefab("PanelStageLock")
    local rImgIcon = XUiHelper.TryGetComponent(prefab.transform, "RImgIcon", "RawImage")
    if rImgIcon then
        local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
        rImgIcon:SetRawImage(stageCfg.Icon)
    end
end

-- 加载子预制体
function XUiMainLine2GridEntrance:LoadSubPrefab(prefabName)
    local prefab = self.SubPrefabs[prefabName]
    if prefab then
        return prefab
    end

    local parentGo = self[prefabName .. "Parent"]
    prefab = self.Obj:Instantiate(prefabName, parentGo.gameObject)
    self.SubPrefabs[prefabName] = prefab
    return prefab
end

-- 显示/隐藏子预制体
function XUiMainLine2GridEntrance:ShowSubPrefab(prefabName, isShow)
    local prefab = self.SubPrefabs[prefabName]
    if not prefab and isShow then
        prefab = self:LoadSubPrefab(prefabName)
    end

    if prefab then
        prefab.gameObject:SetActiveEx(isShow)
    end
    return prefab
end

-- 是否通关
function XUiMainLine2GridEntrance:IsPass()
    for _, stageId in ipairs(self.StageIds) do
        local isIgnore = self._Control:IsStageIgnore(stageId)
        if not isIgnore then
            local isPass, desc = self._Control:IsStagePass(stageId)
            if not isPass then
                return false, desc
            end
        end
    end
    return true
end

-- 是否显示
function XUiMainLine2GridEntrance:IsShow()
    local stageInfo = XMVCA:GetAgency(ModuleId.XFuben):GetStageInfo(self.StageId)
    return stageInfo.Unlock
end

-- 是否解锁
function XUiMainLine2GridEntrance:IsUnlock()
    return self._Control:IsStageUnlock(self.StageId)
end

return XUiMainLine2GridEntrance