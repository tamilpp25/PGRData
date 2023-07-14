local XUiPartnerTeachingChapter = XLuaUiManager.Register(XLuaUi, "UiPartnerTeachingChapter")

local XUiPartnerTeachingChapterContent = require("XUi/XUiFubenPartnerTeaching/XUiPartnerTeachingChapterContent")
local FIGHT_DETAIL = "UiPartnerTeachingFightDetail"
local STORY_DETAIL = "UiPartnerTeachingStoryDetail"

function XUiPartnerTeachingChapter:OnAwake()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self:AddListener()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_TEACHING_OPEN_STAGE_DETAIL, self.OpenStageDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_TEACHING_CLOSE_STAGE_DETAIL, self.CloseStageDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_TEACHING_STAGE_REFRESH, self.Refresh, self)
end

function XUiPartnerTeachingChapter:OnStart(chapterId)
    self.ChapterId = chapterId
    self:LoadChapter(chapterId)
end

function XUiPartnerTeachingChapter:OnEnable()
    self:Refresh()
end

function XUiPartnerTeachingChapter:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_TEACHING_OPEN_STAGE_DETAIL, self.OpenStageDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_TEACHING_CLOSE_STAGE_DETAIL, self.CloseStageDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_TEACHING_STAGE_REFRESH, self.Refresh, self)
end

----------------------------------------------------初始化---------------------------------------------------------------
---
--- 加载章节
function XUiPartnerTeachingChapter:LoadChapter(chapterId)
    -- 背景
    local bg = XPartnerTeachingConfigs.GetChapterBackground(chapterId)
    if bg then
        self.RImgFestivalBg:SetRawImage(bg)
    end

    -- 预制体
    local prefabPath = XPartnerTeachingConfigs.GetChapterFubenPrefab(chapterId)
    if prefabPath then
        local go = self.PanelChapter:LoadPrefab(prefabPath)
        self.ChapterContent = XUiPartnerTeachingChapterContent.New(go, self.ChapterId)
    end
end

---------------------------------------------------刷新------------------------------------------------------------------
function XUiPartnerTeachingChapter:Refresh()
    if self.ChapterContent then
        self.ChapterContent:Refresh()
    end
end

-----------------------------------------------按钮响应函数--------------------------------------------------------------
function XUiPartnerTeachingChapter:AddListener()
    self.SceneBtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.SceneBtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnCloseDetail.CallBack = function()
        self:CloseStageDetail()
    end
end

function XUiPartnerTeachingChapter:OnBtnBackClick()
    if XLuaUiManager.IsUiShow(FIGHT_DETAIL) or XLuaUiManager.IsUiShow(STORY_DETAIL) then
        self:CloseStageDetail()
    else
        self:Close()
    end
end

function XUiPartnerTeachingChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-------------------------------------------------关卡详情-----------------------------------------------------------------
---
--- 打开关卡详情界面
function XUiPartnerTeachingChapter:OpenStageDetail(stageId)
    -- 选择关卡
    self.ChapterContent:SelectStage(stageId)

    local detailType
    local stageType = XFubenConfigs.GetStageType(stageId)
    if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG
            or stageType == XFubenConfigs.STAGETYPE_COMMON then
        detailType = FIGHT_DETAIL
    elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        detailType = STORY_DETAIL
    else
        XLog.Error(string.format("XUiPartnerTeachingChapter.OpenStageDetail函数错误，没有对应StageType的处理逻辑，关卡：%s，StageType：%s",
                stageId, stageType))
        return
    end
    self:OpenOneChildUi(detailType, handler(self, self.Close))
    self:FindChildUiObj(detailType):Refresh(stageId, self.ChapterId)

    self.BtnCloseDetail.gameObject:SetActiveEx(true)
end

---
--- 关闭关卡详情界面
function XUiPartnerTeachingChapter:CloseStageDetail()
    -- 取消关卡选择
    self.ChapterContent:CancelSelectStage()

    if XLuaUiManager.IsUiShow(FIGHT_DETAIL) then
        self:FindChildUiObj(FIGHT_DETAIL):CloseDetailWithAnimation()
    end
    if XLuaUiManager.IsUiShow(STORY_DETAIL) then
        self:FindChildUiObj(STORY_DETAIL):CloseDetailWithAnimation()
    end

    self.BtnCloseDetail.gameObject:SetActiveEx(false)
end