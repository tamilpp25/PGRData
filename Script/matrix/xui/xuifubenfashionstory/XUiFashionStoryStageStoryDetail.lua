local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFashionStoryStageStoryDetail = XLuaUiManager.Register(XLuaUi, "UiFashionStoryStageStoryDetail")

function XUiFashionStoryStageStoryDetail:OnAwake()
    self:InitComponent()
    self:AddListener()
end

function XUiFashionStoryStageStoryDetail:OnStart(closeParentCb)
    self.CloseParentCb = closeParentCb
end

function XUiFashionStoryStageStoryDetail:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
end


-----------------------------------------------按钮响应函数---------------------------------------------------------------

function XUiFashionStoryStageStoryDetail:AddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end

function XUiFashionStoryStageStoryDetail:OnBtnEnterClick()
    local leftTimeStamp = XDataCenter.FashionStoryManager.GetLeftTimeStamp(self.ActivityId)
    if leftTimeStamp <= 0 then
        XUiManager.TipText("FashionStoryActivityEnd")
        self.CloseParentCb()
        return
    end

    local beginStoryId = XFubenConfigs.GetBeginStoryId(self.StageId)
    if not beginStoryId then
        XLog.Error(string.format("XUiFashionStoryStageStoryDetail:OnBtnEnterClick函数错误，关卡：%s的剧情Id为空",
                tostring(self.StageId)))
        return
    end

    local playStory = function(isPassed)
        XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            if isPassed then
                -- 非首次通关，关闭关卡详情
                XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_CLOSE_STAGE_DETAIL)
            else
                -- 首次通关，刷新关卡并移动到最后一关
                XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_CHAPTER_REFRESH, true)
            end
        end)
    end

    local isPassed = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    if isPassed then
        playStory(true)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageId, function()
            XDataCenter.FashionStoryManager.RefreshStagePassedBySettleData({ StageId = self.StageId })
            XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_CLOSE_STAGE_DETAIL)
            playStory(false)
        end)
    end
end


-----------------------------------------------------刷新---------------------------------------------------------------

function XUiFashionStoryStageStoryDetail:Refresh(stageId, activityId)
    self.StageId = stageId
    self.ActivityId = activityId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTitle.text = stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description

    local titleBg = XFashionStoryConfigs.GetStoryStageDetailBg(stageId)
    local enterIcon = XFashionStoryConfigs.GetStoryStageDetailIcon(stageId)
    if titleBg then
        self.RImgTitleBg:SetRawImage(titleBg)
    else
        self.RImgTitleBg.gameObject:SetActiveEx(false)
    end
    if enterIcon then
        self.RImgNandu:SetRawImage(enterIcon)
    else
        self.RImgNandu.gameObject:SetActiveEx(false)
    end
end

function XUiFashionStoryStageStoryDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimClose", function()
        self:Close()
    end)
end
