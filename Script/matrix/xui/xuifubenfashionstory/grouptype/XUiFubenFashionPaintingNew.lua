local XUiFubenFashionPaintingNew=XLuaUiManager.Register(XLuaUi,"UiFubenFashionPaintingNew")
local XUiGridFashionStoryStage=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryStage')
--region 生命周期
function XUiFubenFashionPaintingNew:OnAwake()
    self:Init()
    self:InitGridStoryList()
end

function XUiFubenFashionPaintingNew:OnStart(groupId)
    self.GroupId=groupId
    self:RefreshBackground()
    self:RefreshProcess()
    self:RefreshStoryGrids()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XDataCenter.FashionStoryManager.GetActivityTime(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionPaintingNew:OnEnable()
    self:UpdateLeftTime(XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())<=0)
end
--endregion

--region 初始化
function XUiFubenFashionPaintingNew:Init()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self.BtnSkip1.CallBack=function()
        --前往商店界面
        XFunctionManager.SkipInterface(XFashionStoryConfigs.GetFashionStorySkipId(XDataCenter.FashionStoryManager.GetCurrentActivityId(),XFashionStoryConfigs.FashionStorySkip.SkipToStore))
    end
end

function XUiFubenFashionPaintingNew:InitGridStoryList()
    self.GridStoryList={}
    
    for i=1,XFashionStoryConfigs.StageCountInGroupUpperLimit do
        if self['GridStory'..i] then
            self.GridStoryList[i]=XUiGridFashionStoryStage.New(self,self['GridStory'..i])
        end
    end
end
--endregion

--region 数据更新
function XUiFubenFashionPaintingNew:RefreshBackground()
    self.RImgFestivalBg:SetRawImage(XFashionStoryConfigs.GetSingleLineChapterBg(self.GroupId))
    self.ImgRole:SetRawImage(XFashionStoryConfigs.GetStoryEntranceBg(self.GroupId))
    self.ImgTitle:SetRawImage(XFashionStoryConfigs.GetSingleLineSummerFashionTitleImg(self.GroupId))
end

function XUiFubenFashionPaintingNew:RefreshProcess()
    local stagesCount=XFashionStoryConfigs.GetSingleLineStagesCount(self.GroupId)
    local passedCount=XDataCenter.FashionStoryManager.GetGroupStagesPassCount(XFashionStoryConfigs.GetSingleLineStages(self.GroupId))
    self.TxtChapterLeftTime.text=tostring(passedCount)..'/'..tostring(stagesCount)
end

function XUiFubenFashionPaintingNew:RefreshStoryGrids()
    local stagesCount=XFashionStoryConfigs.GetSingleLineStagesCount(self.GroupId)
    local stages=XFashionStoryConfigs.GetSingleLineStages(self.GroupId)
    for i=1,XFashionStoryConfigs.StageCountInGroupUpperLimit do
        if self['GridStory'..i] then
            self['GridStory'..i].gameObject:SetActiveEx(false)
        end
    end
    for i=1,stagesCount do
        if self['GridStory'..i] then
            self['GridStory'..i].gameObject:SetActiveEx(true)
            self.GridStoryList[i]:RefreshData(stages[i])
        end
    end
end

function XUiFubenFashionPaintingNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

return XUiFubenFashionPaintingNew