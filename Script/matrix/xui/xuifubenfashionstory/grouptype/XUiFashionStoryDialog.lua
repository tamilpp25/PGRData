local XUiFashionStoryDialog = XLuaUiManager.Register(XLuaUi, "UiFashionStoryDialog")

local CSTextManagerGetText = CS.XTextManager.GetText

--region 生命周期
function XUiFashionStoryDialog:OnAwake()
    self:Init()
    self:InitCb()
end

function XUiFashionStoryDialog:OnStart(stageId)
    self.StageId=stageId
    self:RefreshData()
end
--endregion

--region 初始化
function XUiFashionStoryDialog:Init()
    self.BtnEnterStoryBefore.gameObject:SetActiveEx(true)
    self.BtnEnterStoryAfter.gameObject:SetActiveEx(false)

    self.BtnEnterStoryBefore:SetName(CSTextManagerGetText("PlayStory"))
end

function XUiFashionStoryDialog:InitCb()
    self.BtnMask.CallBack=function() self:Close() end

    self.BtnEnterStoryBefore.CallBack=function() self:OnPlayClick() end
end
--endregion

--region 数据更新
function XUiFashionStoryDialog:RefreshData()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStoryDec.text = stageCfg.Name
    self.TxtStoryName.text=stageCfg.Description
    self.RImgStory:SetRawImage(XFashionStoryConfigs.GetStoryStageDetailIcon(self.StageId))
end
--endgion

--region 事件处理
function XUiFashionStoryDialog:OnPlayClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageId, function()
            XDataCenter.FashionStoryManager.RefreshStagePassedBySettleData({ StageId = self.StageId })
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()

            end)
        end)
    end
end
--endregion

return XUiFashionStoryDialog
