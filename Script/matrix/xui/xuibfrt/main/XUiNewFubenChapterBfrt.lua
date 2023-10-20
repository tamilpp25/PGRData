---@class XUiNewFubenChapterBfrt:XLuaUi
local XUiNewFubenChapterBfrt = XLuaUiManager.Register(XLuaUi, "UiNewFubenChapterBfrt")
local XUiGridChapterBfrt = require("XUi/XUiFubenMainLineBanner/XUiGridChapterBfrt")
-- 新副本入口独立出来的据点主界面

function XUiNewFubenChapterBfrt:OnAwake()
    self:RegisterUiEvents()
end

function XUiNewFubenChapterBfrt:OnStart()
    XDataCenter.BfrtManager.UpdateStageInfo()
    self:InitDynamicTable()
end

function XUiNewFubenChapterBfrt:OnEnable()
    self:RefreshChapterList()
    self:AddEventListener()
end

function XUiNewFubenChapterBfrt:OnDisable()
    self:RemoveEventListener()
end

--region Ui - ChapterList
function XUiNewFubenChapterBfrt:InitDynamicTable()
    self._ChapterDynamicTable = XDynamicTableNormal.New(self.PanelChapterBfrt)
    self._ChapterDynamicTable:SetProxy(XUiGridChapterBfrt, self)
    self._ChapterDynamicTable:SetDelegate(self)
    self.GridChapterBfrt.gameObject:SetActiveEx(false)
end

-- 设置数据
function XUiNewFubenChapterBfrt:RefreshChapterList()
    ---@type number[]
    self._ChapterIds = self._ChapterIds or XDataCenter.BfrtManager.GetChapterList()
    self._ChapterDynamicTable:SetDataSource(self._ChapterIds)
    self._ChapterDynamicTable:ReloadDataSync()
end

--动态列表事件
---@param grid XUiGridChapterBfrt
function XUiNewFubenChapterBfrt:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._ChapterIds[index] then
            grid:RefreshData(self._ChapterIds[index], index == 1, index == #self._ChapterIds)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:RefreshImportantReward()
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self:RefreshImportantReward()
    end
end

function XUiNewFubenChapterBfrt:RefreshChapterReward()
    for index, grid in pairs(self._ChapterDynamicTable:GetGrids()) do
        if self._ChapterIds[index] then
            grid:RefreshData(self._ChapterIds[index], index == 1, index == #self._ChapterIds)
        end
    end
end
--endregion

--region Ui - CourseReward
function XUiNewFubenChapterBfrt:RefreshImportantReward()
    if not self.RewardsBubble then
        return
    end
    local endIndex = self._ChapterDynamicTable:GetEndIndex()
    local chapterId = self._ChapterIds[endIndex]
    local importantRewardId = XDataCenter.BfrtManager.GetBfrtImportantRewardId(chapterId)
    if XTool.IsNumberValid(importantRewardId) then
        local showItemList = XDataCenter.BfrtManager.GetBfrtRewardShowItemList(importantRewardId, 1)
        if showItemList[1] then
            local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(showItemList[1])
            if goodsShowParams.RewardType == XRewardManager.XRewardType.Nameplate then
                self.RImgBubbleIcon.gameObject:SetActiveEx(false)

                if not self.PanelNamePlate then
                    local prefab = self.RewardsBubble.transform:LoadPrefab(XMedalConfigs.XNameplatePanelPath)
                    local rectTransform = prefab.transform:GetComponent("RectTransform")
                    if rectTransform then
                        local scale = CS.UnityEngine.Vector3(0.45, 0.5, 0.5)
                        rectTransform.position = self.RImgBubbleIcon.transform.position
                        rectTransform.localScale = scale
                    end
                    local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
                    self.PanelNamePlate = XUiPanelNameplate.New(prefab, self)
                end
                self.PanelNamePlate.GameObject:SetActiveEx(true)
                self.PanelNamePlate:UpdateDataById(goodsShowParams.TemplateId)
            else
                if self.PanelNamePlate then
                    self.PanelNamePlate.GameObject:SetActiveEx(false)
                end
                self.RImgBubbleIcon.gameObject:SetActiveEx(true)
                XUiHelper.GetUiSetIcon(self.RImgBubbleIcon, goodsShowParams.Icon)
            end
            self.RewardsBubble.gameObject:SetActiveEx(true)
        end
    else
        self.RewardsBubble.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - BtnListener
function XUiNewFubenChapterBfrt:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiNewFubenChapterBfrt:OnBtnBackClick()
    self:Close()
end
    
function XUiNewFubenChapterBfrt:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

--region Event
function XUiNewFubenChapterBfrt:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_COURSE_REWARD_RECV, self.RefreshChapterReward, self)
end

function XUiNewFubenChapterBfrt:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_COURSE_REWARD_RECV, self.RefreshChapterReward, self)
end
--endregion

return XUiNewFubenChapterBfrt