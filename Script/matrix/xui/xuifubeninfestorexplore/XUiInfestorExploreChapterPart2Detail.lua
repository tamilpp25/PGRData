local XUiInfestorExploreChapterPart2Detail = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreChapterPart2Detail")

function XUiInfestorExploreChapterPart2Detail:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreChapterPart2Detail:OnEnable()
    self:RefreshView(self.StageId)
end

function XUiInfestorExploreChapterPart2Detail:RefreshView(stageId)
    if not stageId then return end

    self.StageId = stageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    self.TxtArenatName.text = stageCfg.Name
    self.TxtDetails.text = stageCfg.Description

    local icon = stageCfg.StoryIcon
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    end

    local score = XDataCenter.FubenInfestorExploreManager.GetChapter2StageScore(stageId)
    if score > 0 then
        self.TxtArenaScore.text = CS.XTextManager.GetText("ArenaHighDesc", score)
    else
        self.TxtArenaScore.text = score
    end
end

function XUiInfestorExploreChapterPart2Detail:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnEnterArena.CallBack = function() self:OnClickBtnEnter() end
end

function XUiInfestorExploreChapterPart2Detail:OnClickBtnEnter()
    local stageId = self.StageId
    XLuaUiManager.Open("UiNewRoomSingle", stageId)
end