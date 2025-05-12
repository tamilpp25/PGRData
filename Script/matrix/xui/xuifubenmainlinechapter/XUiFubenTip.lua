local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiFubenTip : XLuaUi
local XUiFubenTip = XLuaUiManager.Register(XLuaUi, "UiFubenTip")

local TitleContent = {
    [XFubenConfigs.ChapterType.MainLine] = "UiFubenTipMainLineContent"
}

function XUiFubenTip:OnAwake()
    self:RegisterUiEvents()
end

function XUiFubenTip:OnStart(teleportRewardCache, chapterType)
    self.TeleportRewardCache = teleportRewardCache
    -- 标题描述
    if not XTool.IsNumberValid(chapterType) then
        chapterType = XFubenConfigs.ChapterType.MainLine
    end
    local content = XUiHelper.GetText(TitleContent[chapterType])
    self.TxtTitle.text = XUiHelper.GetText("UiFubenTipTitleContent", content)
end

function XUiFubenTip:OnEnable()
    self:RefreshStages()
    self:RefreshRewards()
end

function XUiFubenTip:RefreshStages()
    self.GridStageDic = self.GridStageDic or {}

    local stageIdList = {}
    -- 获取跳转缓存数据
    for _, info in pairs(self.TeleportRewardCache or {}) do
        local stageId = info.StageId or 0
        table.insert(stageIdList, stageId)
    end
    -- 排序
    table.sort(stageIdList, function(a, b) 
        return a < b
    end)

    for i, stageId in pairs(stageIdList) do
        local grid = self.GridStageDic[i]
        if not grid then
            grid = i == 1 and self.GridStage or XUiHelper.Instantiate(self.GridStage, self.PanelStageContent)
            self.GridStageDic[i] = grid
        end
        local txt = grid.transform:GetComponent("Text")
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(stageId)
        txt.text = chapterOrderId .. "-" .. stageCfg.OrderId .. stageCfg.Name
        grid.gameObject:SetActiveEx(true)
    end
    for i = #stageIdList + 1, #self.GridStageDic do
        self.GridStageDic[i].gameObject:SetActiveEx(false)
    end
end

function XUiFubenTip:RefreshRewards()
    self.GridRewardDic = self.GridRewardDic or {}

    local rewardGoodsList = {}
    -- 获取跳转缓存数据
    for _, info in pairs(self.TeleportRewardCache or {}) do
        local rewardList = info.RewardGoodsList or {}
        rewardGoodsList = XTool.MergeArray(rewardGoodsList, rewardList)
    end
    
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridRewardDic[i]
        if not grid then
            local go = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.PanelContent)
            grid = XUiGridCommon.New(self, go)
            self.GridRewardDic[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardDic do
        self.GridRewardDic[i].GameObject:SetActiveEx(false)
    end 
end

function XUiFubenTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnBackClick)
end

function XUiFubenTip:OnBtnBackClick()
    self:Close()
end

return XUiFubenTip