local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGame2048Main: XLuaUi
---@field _Control XGame2048Control
local XUiGame2048Main = XLuaUiManager.Register(XLuaUi, 'UiGame2048Main')

local XUiGridGame2048Chapter = require('XUi/XUiGame2048/UiGame2048Main/XUiGridGame2048Chapter')
local XUiGameMainSpine = require('XUi/XUiGame2048/UiGame2048Main/XUiGameMainSpine')

function XUiGame2048Main:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:BindHelpBtn(self.BtnHelp, "Game2048")
    self.BtnShop.CallBack = handler(self, self.OnStoreClickEvent)
    
    self._SpineBg1 = XUiGameMainSpine.New(self.BgShiTouSpine01)
    self._SpineBg2 = XUiGameMainSpine.New(self.BgShiTouSpine02)
end

function XUiGame2048Main:OnStart()
    self:InitChapterUI()
    self._StoreReddotId = self:AddRedPointEvent(self.BtnShop, self.OnShopBtnReddot, self, {XRedPointConditions.Types.CONDITION_GAME2048_STORE})
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCurActivityItemId())
    self:InitShowRewards()
    self._StartRun = true
    -- todo 暂时屏蔽动画
    --[[
    self._SpineBg1:PlaySpineAnimation("Enable", "Loop")
    self._SpineBg2:PlaySpineAnimation("Enable", "Loop")
    self:PlayAnimationWithMask("Enable", function()
        self:PlayAnimation("UiLoop",nil,nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    --]]
end

function XUiGame2048Main:OnEnable()
    self:StartLeftTimer()
    self:RefreshChapterUI()
    XRedPointManager.Check(self._StoreReddotId)

    if self._StartRun then
        self._StartRun = false
    else
        --todo 暂时屏蔽动画
        --[[
        self:PlayAnimation("UiLoop",nil,nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        --]]
    end
end

function XUiGame2048Main:OnDisable()
    self:StopLeftTimer()
end

--region 活动剩余时间显示
function XUiGame2048Main:StartLeftTimer()
    self:StopLeftTimer()
    self:UpdateLeftTimer()
    self._LeftTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateLeftTimer), XScheduleManager.SECOND)
end

function XUiGame2048Main:StopLeftTimer()
    if self._LeftTimerId then
        XScheduleManager.UnSchedule(self._LeftTimerId)
        self._LeftTimerId = nil
    end
end

function XUiGame2048Main:UpdateLeftTimer()
    local timeId = self._Control:GetCurActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local now = XTime.GetServerNowTimestamp()
        
        local leftTime = endTime - now

        if leftTime < 0 then
            leftTime = 0
        end
        
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        return
    end

    self.TxtTime.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.ACTIVITY)
end
--endregion

--region 章节入口
function XUiGame2048Main:InitChapterUI()
    local chapterIds = XMVCA.XGame2048:GetCurChapterIds()
    
    if not XTool.IsTableEmpty(chapterIds) then

        self._ChapterGrids = {}

        --- 检查连续索引的UI，处于配置内则初始化，否则隐藏
        for index = 1, 10 do
            local go = self['GridChapter'..index]

            if go then
                local id = chapterIds[index]

                if XTool.IsNumberValid(id) then
                    local grid = XUiGridGame2048Chapter.New(go, self, id, index)
                    grid:Open()
                    grid:SetEnterAnimationName('GridChapter'..tostring(index)..'Enable')
                    table.insert(self._ChapterGrids, grid)
                else
                    go.gameObject:SetActiveEx(false)
                end
                
            else
                break
            end
            
            
        end
    end
end

function XUiGame2048Main:RefreshChapterUI()
    if not XTool.IsTableEmpty(self._ChapterGrids) then
        for index, grid in ipairs(self._ChapterGrids) do
            grid:Refresh()
        end
    end
end
--endregion

--region 商店入口
function XUiGame2048Main:OnStoreClickEvent()
    local shopId = XMVCA.XGame2048:GetCurShopId()
    if XTool.IsNumberValid(shopId) then
        XShopManager.GetShopInfo(shopId, function()
            XLuaUiManager.Open('UiGame2048Shop')
        end)
    else
        XLog.Error('Game2048ClientConfig.tab中配置的商店Id无效(Key: ShopId)') 
    end
end

function XUiGame2048Main:InitShowRewards()
    self.Grid256New.gameObject:SetActiveEx(false)
    self._GoodsPreview = {}
    --通用处理
    local showItems = nil
    local rewardId = self._Control:GetClientConfigNum('ShowRewardId')
    if XTool.IsNumberValid(rewardId) then
        showItems = XRewardManager.GetRewardListNotCount(rewardId)
    end
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, showItems and #showItems or 0, function(index, obj)
        local gridCommont = XUiGridCommon.New(self, obj)
        gridCommont:Refresh(showItems[index])
        table.insert(self._GoodsPreview, gridCommont)
    end)


end

function XUiGame2048Main:OnShopBtnReddot(count)
    self.BtnShop:ShowReddot(count >= 0)
end
--endregion

return XUiGame2048Main