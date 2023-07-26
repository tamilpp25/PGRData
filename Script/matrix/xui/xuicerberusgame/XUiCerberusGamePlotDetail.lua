-- 剧情关卡详情弹窗
local XUiCerberusGamePlotDetail = XLuaUiManager.Register(XLuaUi, "UiCerberusGamePlotDetail")

function XUiCerberusGamePlotDetail:OnAwake()
    self:InitButton()
end

function XUiCerberusGamePlotDetail:InitButton()
    self:RegisterClickEvent(self.BtnCloseMask, self.Close)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
end

--- func desc
---@param xStoryPoint XCerberusGameStoryPoint
function XUiCerberusGamePlotDetail:OnStart(xStoryPoint, gridStage)
    self.XStoryPoint = xStoryPoint
    self.GridStage = gridStage
    gridStage:SetPanelSelect(true)
end

function XUiCerberusGamePlotDetail:OnEnable()
    self:RefreshUi()
end

function XUiCerberusGamePlotDetail:RefreshUi()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.XStoryPoint:GetXStage().StageId)
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(stageCfg.StoryIcon)
end

function XUiCerberusGamePlotDetail:OnBtnEnterStoryClick()
    local stageId = self.XStoryPoint:GetXStage().StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if not stageInfo then return end
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
        if not self.XStoryPoint:GetIsPassed() then
            XDataCenter.CerberusGameManager.CerberusGamePassStoryPointRequest(self.XStoryPoint:GetId())
        end
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function ()
                XDataCenter.CerberusGameManager.CerberusGamePassStoryPointRequest(self.XStoryPoint:GetId())
            end)
        end)
    end
end

function XUiCerberusGamePlotDetail:OnDestroy()
    self.GridStage:SetPanelSelect(false)
end

return XUiCerberusGamePlotDetail