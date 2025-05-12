local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiMechanismMain
---@field _Control XMechanismActivityControl
local XUiMechanismMain = XLuaUiManager.Register(XLuaUi, 'UiMechanismMain')
local XUiGridMechanismChapter = require('XUi/XUiMechanismActivity/UiMechanismMain/XUiGridMechanismChapter')
local XUiGridMechanismGoodsPreview = require('XUi/XUiMechanismActivity/UiMechanismMain/XUiGridMechanismGoodsPreview')
--region --------------------------生命周期---------------------------

function XUiMechanismMain:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self.BtnShop.CallBack = handler(self, self.OnShopBtnClickEvent)
    XUiHelper.RegisterHelpButton(self.BtnHelp, 'MechanismActivity')
end

function XUiMechanismMain:OnStart()
    self:InitChapterGrids()
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelSpecialTool, self._Control:GetCoinItemByActivityId(self._Control:GetCurActivityId()))
    self:InitShowRewards()
    self._StoreReddotId = self:AddRedPointEvent(self.BtnShop, self.OnShopBtnReddot, self, {XRedPointConditions.Types.CONDITION_MECHANISM_EXCHANGEABLE})
end

function XUiMechanismMain:OnEnable()
    self:StartTimeUpdater()
    self:UpdateChapterGrids()
    XRedPointManager.Check(self._StoreReddotId)
    self:CheckGoodsPreviewComplete()
end


function XUiMechanismMain:OnDisable()
    self:StopTimeUpdater()
end

--endregion

--region 活动时间
function XUiMechanismMain:StartTimeUpdater()
    self:StopTimeUpdater()
    self:OnTimeUpdate()
    self._TimerUpdaterId = XScheduleManager.ScheduleForever(handler(self, self.OnTimeUpdate), XScheduleManager.SECOND)
end

function XUiMechanismMain:OnTimeUpdate()
    local leftTime = XMVCA.XMechanismActivity:GetLeftTime()
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiMechanismMain:StopTimeUpdater()
    if self._TimerUpdaterId then
        XScheduleManager.UnSchedule(self._TimerUpdaterId)
        self._TimerUpdaterId = nil
    end
end

--endregion

--region 章节入口
function XUiMechanismMain:InitChapterGrids()
    self._ChapterGrids = {}
    self.GridChapter.gameObject:SetActiveEx(false)
    
    local activityId = self._Control:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local chapterIds = self._Control:GetChapterIdsByActivityId(activityId)
        if not XTool.IsTableEmpty(chapterIds) then
            for i, v in ipairs(chapterIds) do
                if self['Chapter'..i] then
                    local clone = CS.UnityEngine.GameObject.Instantiate(self.GridChapter, self['Chapter'..i].transform)
                    clone.transform.anchoredPosition = Vector2.zero
                    local grid = XUiGridMechanismChapter.New(clone, self)
                    grid:Open()
                    grid:Refresh(v)
                    table.insert(self._ChapterGrids, grid)
                end
            end
        end
    end
end

function XUiMechanismMain:UpdateChapterGrids()
    if not XTool.IsTableEmpty(self._ChapterGrids) then
        for i, v in pairs(self._ChapterGrids) do
            v:Refresh()
        end
    end
end
--endregion

--region 商店入口
function XUiMechanismMain:OnShopBtnClickEvent()
    local shopId = XMVCA.XMechanismActivity:GetCurShopId()

    XShopManager.GetShopInfo(shopId, function()
        XLuaUiManager.Open('UiMechanismShop')
    end)
end

function XUiMechanismMain:InitShowRewards()
    self.Grid256New.gameObject:SetActiveEx(false)
    self._GoodsPreview = {}
    --通用处理
    local showItems = {}
    local rewardId = self._Control:GetShowRewardIdsByActivityId(self._Control:GetCurActivityId())
    if XTool.IsNumberValid(rewardId) then
        showItems = XRewardManager.GetRewardListNotCount(rewardId)
    end
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, showItems and #showItems or 0, function(index, obj)
        local gridCommont = XUiGridMechanismGoodsPreview.New(self, obj)
        gridCommont:Refresh(showItems[index])
        table.insert(self._GoodsPreview, gridCommont)
    end)

    
end

function XUiMechanismMain:CheckGoodsPreviewComplete()
    local showItems = {}
    local rewardId = self._Control:GetShowRewardIdsByActivityId(self._Control:GetCurActivityId())
    if XTool.IsNumberValid(rewardId) then
        showItems = XRewardManager.GetRewardListNotCount(rewardId)
    end
    if #self._GoodsPreview > 0 and not XTool.IsTableEmpty(showItems) then
        -- 只有开放了商店功能才请求数据进行处理
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) then
            self._Control:CheckGoodsIsBuyAll(showItems, function(result)
                for i, v in ipairs(self._GoodsPreview) do
                    v:SetBuyComplete(result[i] and true or false)
                end
            end)
        else
            -- 否则默认显示未购买完
            for i, v in ipairs(self._GoodsPreview) do
                v:SetBuyComplete(false)
            end
        end
    end
end

function XUiMechanismMain:OnShopBtnReddot(count)
    self.BtnShop:ShowReddot(count >= 0)
end
--endregion
return XUiMechanismMain