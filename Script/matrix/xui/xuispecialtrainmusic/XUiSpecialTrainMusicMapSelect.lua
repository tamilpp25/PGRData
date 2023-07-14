local XUiSpecialTrainMusicMapSelect = XLuaUiManager.Register(XLuaUi, "UiSpecialTrainMusicMapSelect")
local XUiGridSpecialTrainMusicMap = require("XUi/XUiSpecialTrainMusic/XUiGridSpecialTrainMusicMap")
function XUiSpecialTrainMusicMapSelect:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCallback = closeCb
    self:InitUiView()
end

function XUiSpecialTrainMusicMapSelect:OnEnable()

end

function XUiSpecialTrainMusicMapSelect:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiSpecialTrainMusicMapSelect:InitUiView()
    self:RegisterButtonEvent()
    self:InitScrollList()
end

function XUiSpecialTrainMusicMapSelect:InitScrollList()
    self.GridList = {}
    self.Stages = XDataCenter.FubenSpecialTrainManager.GetStagesByActivityId(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    for _, stageId in pairs(self.Stages) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridMusic, self.Content)
        local grid = XUiGridSpecialTrainMusicMap.New(stageId, obj,handler(self,self.OnClickGrid))
        if stageId == self.StageId then
            grid:SetSelect(true)
        end
        table.insert(self.GridList, grid)
    end
    self.GridMusic.gameObject:SetActiveEx(false)
end

function XUiSpecialTrainMusicMapSelect:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiSpecialTrainMusicMapSelect:OnClickGrid(stageId)
    XDataCenter.RoomManager.SetStageIdRequest(stageId,function()
        self.StageId = stageId
        for _, grid in pairs(self.GridList) do
            grid:SetSelect(stageId == grid.StageId)
        end
        self:Close()
    end)
end

return XUiSpecialTrainMusicMapSelect