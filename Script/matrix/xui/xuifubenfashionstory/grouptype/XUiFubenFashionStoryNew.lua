local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFubenFashionStoryNew=XLuaUiManager.Register(XLuaUi,"UiFubenFashionStoryNew")
local XUiGridFashionStoryGroup=require('XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryGroup')
--region 生命周期
function XUiFubenFashionStoryNew:OnAwake()
    self:Init()
    self:InitChapterGroup()
end

function XUiFubenFashionStoryNew:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XDataCenter.FashionStoryManager.GetActivityTime(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionStoryNew:OnEnable()
    self:UpdateGroupGridUi()
    self:UpdateLeftTime(XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())<=0)
    XRedPointManager.Check(self.TaskRedPointId)
end

function XUiFubenFashionStoryNew:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.TaskRedPointId)
end
--endregion

--region 初始化
function XUiFubenFashionStoryNew:Init()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    --试衣间
    self.BtnSkip1.CallBack=function() XLuaUiManager.Open("UiFubenFashionFittingNew") end
    --任务
    self.BtnSkip2.CallBack=function() XLuaUiManager.Open("UiFingerFashionTask") end
    
    self.TaskRedPointId=XRedPointManager.AddRedPointEvent(self.BtnSkip2,self.TaskBtnReddot,self,{XRedPointConditions.Types.CONDITION_FASHION_STORY_TASK},nil,false)
end

function XUiFubenFashionStoryNew:InitChapterGroup()
    local rectTrans=self.PanelSummer.gameObject:GetComponent("RectTransform")
    rectTrans.anchorMax=CS.UnityEngine.Vector2(0.5,0.5)
    rectTrans.anchorMin=CS.UnityEngine.Vector2(0.5,0.5)
    rectTrans.anchoredPosition=CS.UnityEngine.Vector2(0,0)
    self.PanelSummer.gameObject.transform.localScale=CS.UnityEngine.Vector3(1,1,1)

    self.PanelSummerGroup={}
    self.GroupCtrl={}
    for i=1,4,1 do
        local key='GridSummer0'..tostring(i)
        if self[key] then
            self.PanelSummerGroup[i]=CS.UnityEngine.GameObject.Instantiate(self.PanelSummer,self[key])
            self.GroupCtrl[i]=XUiGridFashionStoryGroup.New(self,self.PanelSummerGroup[i])
        end
    end
    
    self.PanelSummer.gameObject:SetActiveEx(false)
end
--endregion

--region 数据更新
function XUiFubenFashionStoryNew:UpdateGroupGridUi()
    --读取组id
    local groupIds=XFashionStoryConfigs.GetSingleLines(XDataCenter.FashionStoryManager.GetCurrentActivityId())
    for i, groupId in ipairs(groupIds) do
        if self.GroupCtrl[i] then
            self.GroupCtrl[i]:Refresh(groupId)
        end
    end
end

function XUiFubenFashionStoryNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    else
        --UI更新
        local leftTimeStamp=XDataCenter.FashionStoryManager.GetLeftTimeStamp(XDataCenter.FashionStoryManager.GetCurrentActivityId())
        local leftTime=XUiHelper.GetTime(leftTimeStamp,XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtChapterLeftTime.text=leftTime
    end
end
--endregion

function XUiFubenFashionStoryNew:TaskBtnReddot(count)
    self.BtnSkip2:ShowReddot(count>=0)
end 