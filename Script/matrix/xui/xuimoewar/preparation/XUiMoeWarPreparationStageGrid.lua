local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local REWARD_GRID_MAX_COUNT = 3
local LABEL_TEXT_MAX_COUNT = 3
local stringFormat = string.format

local XUiMoeWarPreparationStageGrid = XClass(nil, "XUiMoeWarPreparationStageGrid")

function XUiMoeWarPreparationStageGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self.RewardGrids = {}
    self:InitLabelText()
    self:AddListener()
end

function XUiMoeWarPreparationStageGrid:Delete()
    self:StopTimer()
end

function XUiMoeWarPreparationStageGrid:InitLabelText()
    for i = 1, LABEL_TEXT_MAX_COUNT do
        self["LabelText" .. i] = XUiHelper.TryGetComponent(self["Label0" .. i], "Text", "Text")
    end
end

function XUiMoeWarPreparationStageGrid:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDispatch, self.OnBtnDispatchClick)
end

--打开派遣界面
function XUiMoeWarPreparationStageGrid:OnBtnDispatchClick()
    XLuaUiManager.Open("UiMoeWarDispatch", self.StageId, self.Index)
end

--打开进入战斗前界面
function XUiMoeWarPreparationStageGrid:OnBtnReceiveClick()
    XLuaUiManager.Open("UiMoeWarPrepare", self.StageId, self.Index)
end

function XUiMoeWarPreparationStageGrid:Refresh(stageId, index)
    self.GameObject.name = stringFormat("GridShop%s", index)

    self.StageId = stageId
    self.Index = index
    local isOpenStage = XDataCenter.MoeWarManager.IsOpenPreparationStageByIndex(index)

    self.PrepareNormal.gameObject:SetActiveEx(isOpenStage)
    self.PrepareDisable.gameObject:SetActiveEx(not isOpenStage)

    self:RefreshTitle(self.StageId, isOpenStage)

    if not isOpenStage then
        self:StartTimer(index)
        return
    end

    self:RefreshReward(self.StageId)
    self:RefreshTag(self.StageId)
end

function XUiMoeWarPreparationStageGrid:RefreshTitle(stageId, isOpenStage)
    if self.TxtTitle then
        self.TxtTitle.text = isOpenStage and XFubenConfigs.GetStageName(stageId) or ""
    end
end

function XUiMoeWarPreparationStageGrid:RefreshTag(stageId)
    local labelIds = XMoeWarConfig.GetPreparationStageLabelIds(stageId)
    for i, labelId in ipairs(labelIds) do
        if self["LabelText" .. i] then
            self["LabelText" .. i].text = XMoeWarConfig.GetPreparationStageTagLabelById(labelId)
            self["Label0" .. i].gameObject:SetActiveEx(true)
        end
    end
    for i = #labelIds + 1, LABEL_TEXT_MAX_COUNT do
        self["Label0" .. i].gameObject:SetActiveEx(false)
    end
end

function XUiMoeWarPreparationStageGrid:RefreshReward(stageId)
    local rewardId = XMoeWarConfig.GetPreparationStageShowBaseRewardId(stageId)
    local showAllRewardId = XMoeWarConfig.GetPreparationStageShowAllRewardId(stageId)
    local showAllRewardRewards = showAllRewardId > 0 and XRewardManager.GetRewardList(showAllRewardId) or {}

    for i = 1, REWARD_GRID_MAX_COUNT do
        local grid = self.RewardGrids[i]
        if showAllRewardRewards[i] then
            if not grid then
                grid = XUiGridCommon.New(self.RootUi, self["Grid" .. i])
                self.RewardGrids[i] = grid
            end
            grid:Refresh(showAllRewardRewards[i])
            grid.GameObject:SetActiveEx(true)
        else
            self["Grid" .. i].gameObject:SetActiveEx(false)
        end
    end

    local showSpecialRewardId = XMoeWarConfig.GetPreparationStageShowSpecialRewardId(stageId)
    local showSpecialRewardIds = showSpecialRewardId > 0 and XRewardManager.GetRewardList(showSpecialRewardId) or {}
    local showSpecialItemId = showSpecialRewardIds[1] and showSpecialRewardIds[1].TemplateId
    local showSpecialItemCount = showSpecialRewardIds[1] and showSpecialRewardIds[1].Count or 0
    self.Text.text = showSpecialItemId and XDataCenter.ItemManager.GetItemName(showSpecialItemId) or ""

    local goodsShowParams = showSpecialItemId and XGoodsCommonManager.GetGoodsShowParamsByTemplateId(showSpecialItemId)
    if XTool.IsTableEmpty(goodsShowParams) then
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.TxtNumber.text = ""
    else
        self.RImgIcon:SetRawImage(goodsShowParams.Icon)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.TxtNumber.text = "+" .. showSpecialItemCount
    end
end

function XUiMoeWarPreparationStageGrid:StartTimer(index)
    self:StopTimer()

    local nowServerTime = XTime.GetServerNowTimestamp()
    local reserveTime = XDataCenter.MoeWarManager.GetReserveStageTimeByIndex(index)
    self.Timer = XScheduleManager.ScheduleForever(function()
        nowServerTime = XTime.GetServerNowTimestamp()
        if nowServerTime >= reserveTime then
            self:StopTimer()
            self:Refresh(self.StageId, self.Index)
            return
        end
        self.TxtTime.text = XUiHelper.GetTime(reserveTime - nowServerTime, XUiHelper.TimeFormatType.DEFAULT)
    end, XScheduleManager.SECOND)
    self.TxtTime.text = XUiHelper.GetTime(reserveTime - nowServerTime, XUiHelper.TimeFormatType.DEFAULT)
end

function XUiMoeWarPreparationStageGrid:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiMoeWarPreparationStageGrid