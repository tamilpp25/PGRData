local XUiFubenFashionFittingNew=XLuaUiManager.Register(XLuaUi,"UiFubenFashionFittingNew")
local XUiGridFashionStoryTrialStage=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryTrialStage')
--region 生命周期
function XUiFubenFashionFittingNew:OnAwake()
    self:Init()
    self:InitStagesList()
end

function XUiFubenFashionFittingNew:OnStart()
    self:RefreshStageList()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XDataCenter.FashionStoryManager.GetActivityTime(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionFittingNew:OnEnable()
    self:UpdateLeftTime(XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())<=0)
end
--endregion

--region 初始化
function XUiFubenFashionFittingNew:Init()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self.BtnSkip1.CallBack=function() 
        --前往商店界面
        XFunctionManager.SkipInterface(XFashionStoryConfigs.GetFashionStorySkipId(XDataCenter.FashionStoryManager.GetCurrentActivityId(),XFashionStoryConfigs.FashionStorySkip.SkipToStore))
    end
    
    self.GridFitting.gameObject:SetActiveEx(false)
end

function XUiFubenFashionFittingNew:InitStagesList() 
    local count=XFashionStoryConfigs.GetFashionStoryTrialStageCount(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self.UiStagesList={}
    self.StagesList={}
    for i=1,count do
        self.UiStagesList[i]=CS.UnityEngine.GameObject.Instantiate(self.GridFitting,self.GridFitting.transform.parent)
        self.StagesList[i]=XUiGridFashionStoryTrialStage.New(self,self.UiStagesList[i])
        self.UiStagesList[i].gameObject:SetActiveEx(true)
    end
end
--endgion

--region 数据更新

function XUiFubenFashionFittingNew:RefreshStageList()
    local stageIds=XFashionStoryConfigs.GetFashionStoryTrialStages(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    for i, stageCtrl in ipairs(self.StagesList) do
        stageCtrl:RefreshData(stageIds[i])
    end
end

function XUiFubenFashionFittingNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

return XUiFubenFashionFittingNew