local Object

local XUiTRPGExploreRegionChapter = XClass(nil, "XUiTRPGExploreRegionChapter")

function XUiTRPGExploreRegionChapter:Ctor(ui, secondAreaId, mainAreaId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    Object = CS.UnityEngine.Object
    self.MainAreaId = mainAreaId
    self.SecondAreaId = secondAreaId
    self:Init()

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiTRPGExploreRegionChapter:Init()
    local secondAreaName = XTRPGConfigs.GetSecondAreaName(self.SecondAreaId)
    self.BtnClick:SetName(secondAreaName)

    local type = XTRPGConfigs.GetSecondAreaType(self.SecondAreaId)
    self.PanelNormalImgMigong.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Maze)
    self.PanelNormalImgPutong.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Normal)
    self.PanelPreImgMigong.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Maze)
    self.PanelPreImgPutong.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Normal)
    if self.ImgMigongDis then
        self.ImgMigongDis.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Maze)
    end
    if self.ImgputongDis then
        self.ImgputongDis.gameObject:SetActiveEx(type == XTRPGConfigs.TRPGSecondAreaType.Normal)
    end
end

function XUiTRPGExploreRegionChapter:OnBtnClick()
    local conditionId = XTRPGConfigs.GetSecondAreaCondition(self.SecondAreaId)
    local ret, desc = XConditionManager.CheckCondition(conditionId)
    if not ret then
        XUiManager.TipError(desc)
        return
    end

    local type = XTRPGConfigs.GetSecondAreaType(self.SecondAreaId)
    if type == XTRPGConfigs.TRPGSecondAreaType.Maze then
        local mazeId = XTRPGConfigs.GetSecondAreaMazeId(self.SecondAreaId)
        XDataCenter.TRPGManager.TRPGEnterMazeRequest(mazeId)
    else
        XLuaUiManager.Open("UiTRPGExploreChapter", self.SecondAreaId, self.MainAreaId)
    end
end

function XUiTRPGExploreRegionChapter:Refresh()
    local conditionId = XTRPGConfigs.GetSecondAreaCondition(self.SecondAreaId)
    local ret = XConditionManager.CheckCondition(conditionId)
    self.BtnClick:SetDisable(not ret)
    self:CheckShowNewHint(ret)
end

function XUiTRPGExploreRegionChapter:CheckShowNewHint(isConditionComplete)
    if not self.TagNew1 or not self.TagNew2 then
        return
    end
    if not isConditionComplete then
        self.TagNew1.gameObject:SetActiveEx(false)
        self.TagNew2.gameObject:SetActiveEx(false)
        return
    end
    local type = XTRPGConfigs.GetSecondAreaType(self.SecondAreaId)
    local isAlreadyEnter
    if type == XTRPGConfigs.TRPGSecondAreaType.Maze then
        local mazeId = XTRPGConfigs.GetSecondAreaMazeId(self.SecondAreaId)
        isAlreadyEnter = XDataCenter.TRPGManager.CheckIsAlreadyEnterMaze(mazeId)
    else
        isAlreadyEnter = XDataCenter.TRPGManager.CheckIsAlreadyOpenExploreChapter(self.SecondAreaId, self.MainAreaId)
    end
    self.TagNew1.gameObject:SetActiveEx(not isAlreadyEnter)
    self.TagNew2.gameObject:SetActiveEx(not isAlreadyEnter)
end

return XUiTRPGExploreRegionChapter