local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPartnerTeachingStoryDetail = XLuaUiManager.Register(XLuaUi, "UiPartnerTeachingStoryDetail")

function XUiPartnerTeachingStoryDetail:OnAwake()
    self:InitComponent()
    self:AddListener()
end

function XUiPartnerTeachingStoryDetail:OnStart(closeParentCb)
    self.CloseParentCb = closeParentCb
end

function XUiPartnerTeachingStoryDetail:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
end

-----------------------------------------------按钮响应函数---------------------------------------------------------------
function XUiPartnerTeachingStoryDetail:AddListener()
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
end

function XUiPartnerTeachingStoryDetail:OnBtnEnterClick()
    local isUnlockChapter = XDataCenter.PartnerTeachingManager.WhetherUnLockChapter(self.ChapterId)
    if not isUnlockChapter then
        XUiManager.TipMsg(CSXTextManagerGetText("PartnerTeachingActivityEnd"))
        self.CloseParentCb()
        return
    end

    if not self.StageId then
        return
    end

    local beginStoryId = XFubenConfigs.GetBeginStoryId(self.StageId)
    if not beginStoryId then
        XLog.Error(string.format("XUiPartnerTeachingStoryDetail:OnBtnEnterClick函数错误，关卡：%s的剧情Id为空",
                tostring(self.StageId)))
        return
    end

    local playStory = function()
        XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_TEACHING_CLOSE_STAGE_DETAIL)
        end)
        -- self:Close()
    end

    local isPassed = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    if isPassed then
        playStory()
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageId, function()
            XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_TEACHING_STAGE_REFRESH)
            playStory()
        end)
    end
end

-----------------------------------------------------刷新---------------------------------------------------------------
function XUiPartnerTeachingStoryDetail:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTitle.text = stageCfg.Name
    self.TxtStoryDes.text = stageCfg.Description

    local titleBg = XPartnerTeachingConfigs.GetChapterStoryStageDetailBg(chapterId)
    local enterIcon = XPartnerTeachingConfigs.GetChapterStoryStageDetailIcon(chapterId)
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

function XUiPartnerTeachingStoryDetail:CloseDetailWithAnimation()
    self:PlayAnimation("AnimDisableEnd", function()
        self:Close()
    end)
end