local XUiMemorySaveTreasure  = require("XUi/XUiMemorySave/XUiMemorySaveTreasure")
local XUiMemorySaveStageLine = require("XUi/XUiMemorySave/XUiMemorySaveStageLine")
local XUiMemorySave = XLuaUiManager.Register(XLuaUi, "UiMemorySave")

local LINE_OBJ_LENGTH = 9 -- 关卡之间的线数量

-- 页签按钮下标
XUiMemorySave.BtnTabIndex = {
    Chapter1 = 1,
    Chapter2 = 2,
    Chapter3 = 3,
    Chapter4 = 4,
}

function XUiMemorySave:OnAwake()
    self:InitUI()
    self:InitCB()
end

function XUiMemorySave:OnStart()
    self:InitData()
    self:InitTabButton()
    self:RegisterRedPointEvent()

    -- 资产面板
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TxtChapterName.text = XDataCenter.MemorySaveManager.GetActivityName()

end

function XUiMemorySave:OnEnable()
    if XDataCenter.MemorySaveManager.OnActivityEnd() then
        return
    end
    self:OnOpenUi()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CHAPTER_REWARD, self.RedPointCheck, self)
end

function XUiMemorySave:OnDisable()
    XDataCenter.MemorySaveManager.UpdateSelectIndex(self.CurrentSelect)
    self.StageLinePanel:UpdateScrollPos()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CHAPTER_REWARD, self.RedPointCheck, self)
end

function XUiMemorySave:OnGetEvents()
    return {
        XEventId.EVENT_MEMORYSAVE_ACTIVITY_END,
    }
end

function XUiMemorySave:OnNotify(evt, ...)
    if evt == XEventId.EVENT_MEMORYSAVE_ACTIVITY_END then
        XDataCenter.MemorySaveManager.OnActivityEnd()
    end
end

--region Init
function XUiMemorySave:InitUI()
    --region find component
    
    self.GridCommon.gameObject:SetActiveEx(false)
    self.BtnChapter.gameObject:SetActiveEx(false)

    self.StageLinePanel = XUiMemorySaveStageLine.New(self.PanelStageLine, {
        HideDetailCB = handler(self, self.OnHideDetailCallBack),
        ShowDetailCB = handler(self, self.OnShowDetailCallBack),
    })
    --endregion
end

function XUiMemorySave:InitCB()
    --region 初始化普通按钮
    self.SceneBtnBack.CallBack          = function () self:OnClickBtnBack() end
    self.SceneBtnMainUi.CallBack        = function () self:OnClickBtnMainUi() end
    self.BtnCloseDetail.CallBack        = function () self:OnHideDetailCallBack() end
    self.BtnTanchuangClose.CallBack     = function () self:OnBtnTreasureBgClick() end

    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick) -- 适配旧版按钮
    --endregion
end

function XUiMemorySave:InitData()
    self.ChapterIds = XDataCenter.MemorySaveManager.GetActivityChapterIds()
    self.CurrentSelect = XDataCenter.MemorySaveManager.GetSelectIndex() or self.BtnTabIndex.Chapter1
end

-- 注册红点
function XUiMemorySave:RegisterRedPointEvent()
    for index, chapterId in ipairs(self.ChapterIds) do
        self["ChapterRedDotId"..index] = XRedPointManager.AddRedPointEvent(
            self["BtnChapter"..index], -- node
            function (_, count) -- callback
                self["BtnChapter"..index]:ShowReddot(count >= 0)
            end, 
            self, {
                XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD,
                XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD_NEW_CHAPTER, 
        }, chapterId, false)
    end

    self.RewardRedDotId     = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewardRedDot,self , { 
        XRedPointConditions.Types.CONDITION_MEMORYSAVE_CHAPTER_REWARD 
        }, self:GetCurrentChapterId(), false)
end

-- 初始化页签按钮
function XUiMemorySave:InitTabButton()
    local tabGroup = {}
    for idx, chapterId in ipairs(self.ChapterIds) do
        local btnChapter = CS.UnityEngine.Object.Instantiate(self.BtnChapter)
        btnChapter.transform:SetParent(self.PanelChapter.transform, false)
        btnChapter.gameObject:SetActiveEx(true)
        self["BtnChapter"..idx] = btnChapter
        table.insert(tabGroup, btnChapter)
    end
    self.PanelChapter:Init(tabGroup, function (tabIndex)
        self:OnClickTabGroup(tabIndex)
    end)
end

-- 检查是否生成红点
function XUiMemorySave:RedPointCheck()
    for index, chapterId in ipairs(self.ChapterIds) do
        XRedPointManager.Check(self["ChapterRedDotId"..index], chapterId)
    end
    XRedPointManager.Check(self.RewardRedDotId, self:GetCurrentChapterId())
end

function XUiMemorySave:InitRewardList()
    self.GridMultipleWeeksTask.gameObject:SetActiveEx(false)
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
    local chapterId = self.ChapterIds[self.CurrentSelect]
    local baseItem = self.GridTreasureGrade
    local rewardIds = XMemorySaveConfig.GetChapterRewardIds(chapterId)
    -- 创建奖励数量个item
    if not self.RewardGrids or #self.RewardGrids ~=  #rewardIds then
        self.RewardGrids = {}
        for _, rewardId in ipairs(rewardIds) do
            local item = CS.UnityEngine.Object.Instantiate(baseItem)
            local grid = XUiMemorySaveTreasure.New(self, item, XDataCenter.FubenManager.StageType.MemorySave)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            table.insert(self.RewardGrids, grid)
        end
    end
    for idx, rewardId in ipairs(rewardIds) do
        local pass = XDataCenter.MemorySaveManager.GetChapterPassed(chapterId)
        local total = XMemorySaveConfig.GetChapterRequirePass(chapterId, idx)
        self.RewardGrids[idx]:UpdateGradeGrid(pass, total, rewardId, chapterId, idx)
        self.RewardGrids[idx]:InitTreasureList()
        self.RewardGrids[idx].GameObject:SetActiveEx(true)
    end
end
--endregion

--region CallBack
function XUiMemorySave:OnClickBtnReward()
    self:OnHideDetailCallBack()
    self:InitRewardList()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self:PlayAnimation("TreasureEnable")
end

function XUiMemorySave:OnBtnTreasureBgClick()
    self:PlayAnimation("TreasureDisable", handler(self, function ()
        self.PanelTreasure.gameObject:SetActiveEx(false)
    end))
end

function XUiMemorySave:OnClickBtnBack()
    self:Close()
end

function XUiMemorySave:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiMemorySave:OnClickTabGroup(tabIndex)
    if tabIndex == self.CurrentSelect then
        return
    end
    self:ShowUIByTabIndex(tabIndex)
end

function XUiMemorySave:OnOpenUi()
    self.BtnCloseDetail.gameObject:SetActiveEx(self.IsShowDetail)
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.ImgRedProgress.gameObject:SetActiveEx(false)

    -- 显示活动剩余时间
    local now = XTime.GetServerNowTimestamp()
    local eTime = XDataCenter.MemorySaveManager.GetActivityEndTime()
    self.TxtDay.text = XUiHelper.GetTime(eTime - now, XUiHelper.TimeFormatType.ACTIVITY)

    -- 更新按钮的名称
    for idx, chapterId in ipairs(self.ChapterIds) do
        local btn = self["BtnChapter"..idx]
        btn:SetDisable(not XDataCenter.MemorySaveManager.IsChapterOpen(chapterId))
        local btnName = XMemorySaveConfig.GetChapterBtnName(chapterId)
        btn:SetNameByGroup(0, btnName)
        btn:SetNameByGroup(1, XMemorySaveConfig.GetChapterName(chapterId))
        btn:SetRawImage(XDataCenter.MemorySaveManager.GetChapterBtnBg(chapterId))
        btn:SetSprite(XMemorySaveConfig.GetChapterBtnIcon(chapterId))
    end

    -- 界面刷新
    self.PanelChapter:SelectIndex(self.CurrentSelect)
    -- 回调中有判断tabIndex与self.CurrentSelect，所以初始化时，需要手动执行一次
    self:ShowUIByTabIndex(self.CurrentSelect)

end

function XUiMemorySave:OnShowDetailCallBack(stage)
    self.PanelAsset.GameObject:SetActiveEx(false)
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self.Stage = stage
    self.IsShowDetail = true
    if not self.Stage then
        XLog.Error("XUiMemorySave:OnShowDetailCallBack: 未能找到对应的Stage")
    end
    self:OpenOneChildUi("UiMemorySaveDetail", self)
end

function XUiMemorySave:OnHideDetailCallBack()
    self.PanelAsset.GameObject:SetActiveEx(true)
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.StageLinePanel:SetPanelStageListMovementType()
    self.StageLinePanel:OnUpdateSelectStage()
    local childUi = self:FindChildUiObj("UiMemorySaveDetail")
    if childUi then
        childUi:OnBtnCloseClick()
        self.IsShowDetail = false
    end
end

function XUiMemorySave:OnCheckRewardRedDot(count)
    self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
end
--endregion

function XUiMemorySave:ShowUIByTabIndex(tabIndex)
    self:PlayAnimation("QieHuan")
    local chapterId = self.ChapterIds[tabIndex]
    if not XDataCenter.MemorySaveManager.IsChapterOpen(chapterId) then
        local msgTips = CsXTextManagerGetText("MemorySaveStageNotOpen", XMemorySaveConfig.GetChapterOpenTime(chapterId))
        XUiManager.TipMsg(msgTips)
        return
    end
    -- 切换页签存储一下位置属性，放在CurrentSelect更新之前
    self.StageLinePanel:UpdateScrollPos()
    self.CurrentSelect = tabIndex

    local rewardIds = XMemorySaveConfig.GetChapterRewardIds(self.ChapterIds[self.CurrentSelect])
    local rewardList = XRewardManager.GetRewardList(rewardIds[1])
    local reward = rewardList and rewardList[1] or {}
    if not self.GirdCommonReward then
        local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
        self.GirdCommonReward = XUiGridCommon.New(self, ui)
        self.GirdCommonReward.Transform:SetParent(self.PanelConsciousness, false)
        self.GirdCommonReward.GameObject:SetActiveEx(true)
        self.GirdCommonReward:SetClickCallback(handler(self, self.OnClickBtnReward))
        --将红点显示到上层
        local gridIndex = self.GirdCommonReward.Transform:GetSiblingIndex()
        self.ImgRedProgress.transform:SetSiblingIndex(gridIndex)
    end
    self.GirdCommonReward:Refresh(reward) -- 每次Refresh都会让数量重新显示
    self.GirdCommonReward:ShowCount(false)
    self.RImgFestivalBg:SetRawImage(XDataCenter.MemorySaveManager.GetChapterBannerBg(chapterId))
    self.StageLinePanel:Refresh(chapterId)
    self:UpdateChapterProgress()
    self:UpdateChapterBtnPass()
    XDataCenter.MemorySaveManager.SetFirstEntryFlag(chapterId)
    self:RedPointCheck()
end

function XUiMemorySave:UpdateChapterProgress()
    self.TxtProgress.text = XDataCenter.MemorySaveManager.GetCurChapterProgress(self:GetCurrentChapterId())
end

function XUiMemorySave:UpdateChapterBtnPass()
    for idx, chapterId in ipairs(self.ChapterIds) do
        local passed = XDataCenter.MemorySaveManager.IsFinishCurChapter(chapterId)
        self["BtnChapter"..idx]:SetNameByGroup(2, passed and "Cleared" or "")
    end
end

--region get and set
function XUiMemorySave:GetCurrentChapterId()
    return self.ChapterIds[self.CurrentSelect]
end
--endregion


