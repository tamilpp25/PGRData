local XUiSummerEpisodeMap = XLuaUiManager.Register(XLuaUi, "UiSummerEpisodeMap")
local XUiGridSummerEpisodeMap = require("XUi/XUiSummerEpisode/XUiGridSummerEpisodeMap")
function XUiSummerEpisodeMap:OnStart(stageId, isIncludeRandomStage, closeCb,ignoreRedPoint)
    self.StageId = stageId
    self.IsHell = XFubenSpecialTrainConfig.IsHellStageId(stageId)
    self.IsIncludeRandomStage = isIncludeRandomStage
    self.Lock = false
    self.CloseCallback = closeCb
    self.IgnoreRedPoint=ignoreRedPoint
    self:InitUiView()
end

function XUiSummerEpisodeMap:InitUiView()
    self.TxtTitle.text = CS.XTextManager.GetText("SummerEpisodeMapSelectTitle")
    self:RegisterButtonEvent()
    self:InitScrollList()
end

function XUiSummerEpisodeMap:InitScrollList()
    self.GridList = {}
    self.Stages = XDataCenter.FubenSpecialTrainManager.GetAllStageIdByActivityId(XDataCenter.FubenSpecialTrainManager.GetCurActivityId(), self.IsIncludeRandomStage)
    for _, stageId in pairs(self.Stages) do
        if self.IsHell and not self.IsIncludeRandomStage then
            stageId = XFubenSpecialTrainConfig.GetHellStageId(stageId)
        end
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridMap, self.Content)
        local grid = XUiGridSummerEpisodeMap.New(obj, stageId, self)
        grid:SetClickEvent(handler(self, self.OnClickGrid))
        if stageId == self.StageId then
            grid:SetSelect(true)
        end
        table.insert(self.GridList, grid)
    end
    self.GridMap.gameObject:SetActiveEx(false)
end

function XUiSummerEpisodeMap:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiSummerEpisodeMap:OnClickGrid(stageId)
    if self.IsIncludeRandomStage then
        if self.CloseCallback then
            self.CloseCallback(stageId)
        end

        self:Close()
        
    else
        if self.Lock then return end
        self.Lock = true
        XDataCenter.RoomManager.PhotoChangeMapRequest(stageId, function()
            self.Lock = false
            self.StageId = stageId
            if XDataCenter.FubenSpecialTrainManager.CheckStageIsNewUnLock(stageId) then
                XDataCenter.FubenSpecialTrainManager.SaveForOldUnLock(stageId)
            end
            XDataCenter.FubenSpecialTrainManager.SetCurrentStageId(stageId)
            for _, grid in pairs(self.GridList) do
                grid:SetSelect(stageId == grid.StageId)
            end
            self:Close()

            
        end)
    end
end

return XUiSummerEpisodeMap