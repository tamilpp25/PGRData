local XUiTwoSideTowerOverview = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerOverview")
local XUiGridTwoSideTowerBuffDetail = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerBuffDetail")
function XUiTwoSideTowerOverview:OnStart(chapterId)
    self.ChapterId = chapterId
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
    end
    self.GridObj = {}
    self.GridDetail = {}
    self:InitButtonGroup()
end

function XUiTwoSideTowerOverview:InitButtonGroup()
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    local pointDataDic = chapter:GetPointData()
    self.PointData = {}
    self.BtnList = {}

    -- 攻略提示页签
    local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnFirst, self.BtnContent.transform)
    obj:SetName(XTwoSideTowerConfigs.GetOverviewTabName())
    table.insert(self.BtnList, obj)
    table.insert(self.PointData, {})
    -- todo 刷新详情

    -- 关卡页签
    for _, pointData in pairs(pointDataDic) do
        ---@type XUiComponent.XUiButton
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnFirst, self.BtnContent.transform)
        obj:SetName(pointData:GetName())
        table.insert(self.BtnList, obj)
        table.insert(self.PointData, pointData)
    end

    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnContent:Init(self.BtnList, function(index)
        self:PlayAnimation("QieHuan")
        self:Refresh(index)
    end)
    self.BtnContent:SelectIndex(1)
end

function XUiTwoSideTowerOverview:Refresh(index)
    for _, obj in pairs(self.GridObj) do
        CS.UnityEngine.GameObject.Destroy(obj.gameObject)
    end
    self.GridObj = {}

    local isFirst = index == 1
    self.GridDetails03.gameObject:SetActiveEx(isFirst)
    if isFirst then
        local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
        self.GridDetails03:GetObject("TxtId").text = "0" .. tostring(chapter:GetId())
        self.GridDetails03:GetObject("TxtName").text = chapter:GetChapterName()
        self.GridDetails03:GetObject("TxtDesc").text = chapter:GetChapterOverviewDesc()
        local icon = chapter:GetChapterOverviewIcon()
        self.GridDetails03:GetObject("RImgIcon"):SetRawImage(icon)
        return
    end

    ---@type XTwoSideTowerPoint
    local pointData = self.PointData[index]
    local stageList = pointData:GetStageDataList()
    self.GridDetail = {}
    for _, stageData in pairs(stageList) do
        local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(stageData:GetFeatureId())
        local obj
        if string.IsNilOrEmpty(featureCfg.Image) then
            obj = CS.UnityEngine.GameObject.Instantiate(self.GridDetails01,self.Content)
        else
            obj = CS.UnityEngine.GameObject.Instantiate(self.GridDetails02, self.Content)
        end
        obj.gameObject:SetActiveEx(true)
        table.insert(self.GridObj, obj)
        local grid = XUiGridTwoSideTowerBuffDetail.New(obj, stageData)
        table.insert(self.GridDetail, grid)
    end
end

return XUiTwoSideTowerOverview
