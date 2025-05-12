---@class XUiMainLine2DetailStory:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2DetailStory = XLuaUiManager.Register(XLuaUi, "UiMainLine2DetailStory")

function XUiMainLine2DetailStory:OnAwake()
    self:RegisterUiEvents()
end

function XUiMainLine2DetailStory:OnStart(stageIds, chapterId, mainId, closeCb)
    self.StageId = stageIds[1]
    self.ChapterId = chapterId
    self.MainId = mainId
    self.CloseCb = closeCb
end

function XUiMainLine2DetailStory:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiMainLine2DetailStory:OnDisable()
    self.Super.OnDisable(self)
end

function XUiMainLine2DetailStory:OnDestroy()
end

function XUiMainLine2DetailStory:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnPlay, self.OnBtnPlayClick)
end

function XUiMainLine2DetailStory:OnBtnCloseClick()
    local cb = self.CloseCb
    self:Close()
    
    if cb then
        cb()
    end
end

function XUiMainLine2DetailStory:OnBtnPlayClick()
    local stageId = self.StageId
    local detailType = self._Control:GetStageDetailType(stageId)
    local beginStoryId = XMVCA:GetAgency(ModuleId.XFuben):GetBeginStoryId(stageId)
    local videoId = self._Control:GetStageVideoId(stageId)
    
    -- 需要先设置性别
    if not XPlayer.IsSetGender() then
        XPlayer.TipsSetGender("SetGenderTips")
        return
    end

    local stageInfo = XMVCA:GetAgency(ModuleId.XFuben):GetStageInfo(stageId)
    if stageInfo.Passed then
        self:Close()
        self:PlayStory(detailType, beginStoryId, videoId)
    else
        XMVCA:GetAgency(ModuleId.XFuben):FinishStoryRequest(stageId, function()
            self:Close()
            self:PlayStory(detailType, beginStoryId, videoId)
        end)
    end
end

function XUiMainLine2DetailStory:PlayStory(detailType, beginStoryId, videoId)
    if detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE then
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.CG then
        CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
        XDataCenter.VideoManager.PlayUiVideo(videoId, function()
            CsXUiManager.Instance:RevertAll()
        end)
    end
end

function XUiMainLine2DetailStory:Refresh()
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    local stageInfo = XMVCA:GetAgency(ModuleId.XFuben):GetStageInfo(self.StageId)
    local detailType = self._Control:GetStageDetailType(self.StageId)

    local chapterTitle = self._Control:GetMainTitle(self.MainId)
    self.TxtName.text = string.format("%s-%s %s", chapterTitle, stageCfg.OrderId, stageCfg.Name)
    self.TxtDesc.text = stageCfg.Description
    self.ClearTag.gameObject:SetActiveEx(stageInfo.Passed)

    -- 故事图
    self.PanelMovie.gameObject:SetActiveEx(detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE)
    self.PanelCG.gameObject:SetActiveEx(detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.CG)
    if detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE then
        self.RImgMovie:SetRawImage(stageCfg.StoryIcon)
    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.CG then
        self.RImgCG:SetRawImage(stageCfg.StoryIcon)
    end
    
    -- 按钮特效
    local isNoPass = not self._Control:IsStagePass(self.StageId)
    if isNoPass then
        local effectPath = self._Control:GetSpecialEffect(self.MainId)
        if effectPath and effectPath ~= "" then
            self.BtnPlayEffect:LoadPrefab(effectPath)
            self.BtnPlayEffect.gameObject:SetActiveEx(true)
        end
    end
end

return XUiMainLine2DetailStory