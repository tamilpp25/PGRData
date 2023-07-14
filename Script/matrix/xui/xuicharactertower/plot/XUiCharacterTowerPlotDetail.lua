---@class XUiCharacterTowerPlotDetail : XLuaUi
local XUiCharacterTowerPlotDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerPlotDetail")

function XUiCharacterTowerPlotDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiCharacterTowerPlotDetail:Refresh(stageId)
    self.StageId = stageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        self:OnShowStoryDialog()
    else
        self:OnShowFightDialog()
    end
end
-- 剧情
function XUiCharacterTowerPlotDetail:OnShowStoryDialog()
    self.PanelStory.gameObject:SetActiveEx(true)
    self.PanelFight.gameObject:SetActiveEx(false)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(stageCfg.StoryIcon)
end
-- 战斗
function XUiCharacterTowerPlotDetail:OnShowFightDialog()
    self.PanelStory.gameObject:SetActiveEx(false)
    self.PanelFight.gameObject:SetActiveEx(true)

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtFightName.text = stageCfg.Name
    self.TxtFightDec.text = stageCfg.Description
    self.RImgFight:SetRawImage(stageCfg.Icon)
end

function XUiCharacterTowerPlotDetail:Hide()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL)
end

function XUiCharacterTowerPlotDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.OnBtnMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterStory, self.OnBtnEnterStoryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnterFight, self.OnBtnEnterFightClick)
end

function XUiCharacterTowerPlotDetail:OnBtnMaskClick()
    self:Hide()
end

function XUiCharacterTowerPlotDetail:OnBtnEnterStoryClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self:Hide()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageId, function()
            XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
        end)
    end
end

function XUiCharacterTowerPlotDetail:OnBtnEnterFightClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if stageCfg == nil then
        XLog.Error("XUiCharacterTowerPlotDetail.OnBtnEnterFightClick: Can not find StageCfg!")
        return
    end
    
    if not XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        return
    end
    self:Hide()
    XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
end

return XUiCharacterTowerPlotDetail