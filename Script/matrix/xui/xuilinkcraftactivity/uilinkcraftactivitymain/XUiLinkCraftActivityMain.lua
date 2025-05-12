local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiLinkCraftActivityMain = XLuaUiManager.Register(XLuaUi,'UiLinkCraftActivityMain')

local XUiGridLinkCraftActivityChapter = require('XUi/XUiLinkCraftActivity/UiLinkCraftActivityMain/XUiGridLinkCraftActivityChapter')

--region 生命周期------------>>>
function XUiLinkCraftActivityMain:OnAwake()
    --返回事件
    self.BtnBack.CallBack = handler(self,self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    --图文
    self:BindHelpBtn(self.BtnHelp,'LinkCraftActivity')
    --资源栏
    self.PanelAssetCtrl = XUiPanelAsset.New(self, self.PanelAsset, table.unpack(XEnumConst.LinkCraftActivity.Items))
    --商店跳转
    self.BtnShop.CallBack = handler(self,self.SkipToShop)
    self._ShopReddotId = self:AddRedPointEvent(self.BtnShop, self.OnShopReddotEvent, self, {XRedPointConditions.Types.CONDITION_LINKCRAFT_EXCHANGEABLE})
end

function XUiLinkCraftActivityMain:OnStart()
    self._Control:SetCurChapterById(nil)
    
    self:InitGoodsShow()
    self:InitChapterUI()
end

function XUiLinkCraftActivityMain:OnEnable()
    self:StartLeftTimeTimer()
    self:UpdateChapterUI()
    XRedPointManager.Check(self._ShopReddotId)
end

function XUiLinkCraftActivityMain:OnDisable()
    self:EndLeftTimeTimer()
end

--endregion <<<----------------

--region 界面初始化------------->>>
function XUiLinkCraftActivityMain:InitGoodsShow()
    self.Grid256New.gameObject:SetActiveEx(false)
    --通用处理
    local showItems = XRewardManager.GetRewardListNotCount(self._Control:GetShowRewardId())
    XUiHelper.RefreshCustomizedList(self.PanelItem, self.Grid256New, showItems and #showItems or 0, function(index, obj)
        local gridCommont = XUiGridCommon.New(self, obj)
        gridCommont:Refresh(showItems[index])
    end)
end

function XUiLinkCraftActivityMain:InitChapterUI()
    local chapterObj =nil
    local index = 1
    self._GridChapterList = {}
    
    repeat
        chapterObj = self['GridChapter'..index]
        if chapterObj then
            --根据索引通过Control获取Id（防止索引与Id不对应）
            local chapterId = self._Control:GetChapterIdByIndex(index)
            --初始化控制器并设置静态内容
            self._GridChapterList[index] = XUiGridLinkCraftActivityChapter.New(chapterObj,self,chapterId)
        end
        index = index + 1
    until chapterObj == nil
end
--endregion <<<------------------

--region 界面更新------------->>>
function XUiLinkCraftActivityMain:UpdateLeftTime()
    local leftTime = XMVCA.XLinkCraftActivity:GetLeftTime()

    if leftTime <= 0 then
        leftTime = 0
    end
    
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiLinkCraftActivityMain:UpdateChapterUI()
    for index, grid in ipairs(self._GridChapterList) do
        grid:Refresh()
    end
end

--endregion <<<----------------

--region 事件处理---------------->>>
function XUiLinkCraftActivityMain:StartLeftTimeTimer()
    self:EndLeftTimeTimer()
    self:UpdateLeftTime()
    self._LeftTimeTimerId = XScheduleManager.ScheduleForever(handler(self,self.UpdateLeftTime),XScheduleManager.SECOND)
end

function XUiLinkCraftActivityMain:EndLeftTimeTimer()
    if self._LeftTimeTimerId then
        XScheduleManager.UnSchedule(self._LeftTimeTimerId)
        self._LeftTimeTimerId = nil
    end
end

function XUiLinkCraftActivityMain:SkipToShop()
    local shopId = XMVCA.XLinkCraftActivity:GetCurShopId()
    
    XShopManager.GetShopInfo(shopId, function() 
        XLuaUiManager.Open('UiLinkCraftActivityShop')
    end)
end

function XUiLinkCraftActivityMain:OnShopReddotEvent(count)
    self.BtnShop:ShowReddot(count>=0)
end

--endregion <<<--------------------


return XUiLinkCraftActivityMain