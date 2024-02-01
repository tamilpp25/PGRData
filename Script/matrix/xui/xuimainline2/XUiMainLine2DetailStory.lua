---@class XUiMainLine2DetailStory:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2DetailStory = XLuaUiManager.Register(XLuaUi, "UiMainLine2DetailStory")

function XUiMainLine2DetailStory:OnAwake()
    self:RegisterUiEvents()
end

function XUiMainLine2DetailStory:OnStart(stageIds, chapterId, mainId)
    self.StageId = stageIds[1]
    self.ChapterId = chapterId
    self.MainId = mainId
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
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnPlay, self.OnBtnPlayClick)
end

function XUiMainLine2DetailStory:OnBtnPlayClick()
    local stageId = self.StageId
    local detailType = self._Control:GetStageDetailType(stageId)
    local beginStoryId = XMVCA:GetAgency(ModuleId.XFuben):GetBeginStoryId(stageId)
    local videoId = self._Control:GetStageVideoId(stageId)

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
        XDataCenter.VideoManager.PlayMovie(videoId, function()
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
end

return XUiMainLine2DetailStory